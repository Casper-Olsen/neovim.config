local utils = require 'utils.dotnet-utils'
local status = require 'utils.fidget-status'

local M = {}
local source_failure_details = {}

local function strip_ansi(line)
  return line:gsub('\27%[[0-?]*[ -/]*[@-~]', '')
end

local function quickfix_text(text)
  text = strip_ansi(text)
  text = text:gsub('[\r\n\t]+', ' ')
  text = text:gsub('%c+', ' ')
  text = text:gsub('%s+', ' ')
  text = vim.trim(text)

  if #text > 160 then
    text = text:sub(1, 157) .. '...'
  end

  return text
end

local function command_text(cmd)
  if type(cmd) == 'string' then
    return quickfix_text(cmd)
  end

  return quickfix_text(table.concat(cmd, ' '))
end

local function first_line(text)
  if not text then
    return nil
  end

  return vim.trim((text:gsub('\r\n', '\n'):match '([^\n]+)') or text)
end

local function add_dotnet_diagnostic(qf_list, seen, file, lnum, col, type, code, msg, user_data)
  local key = table.concat({ file, lnum, col, type, code, msg }, '|')
  if seen[key] then
    return
  end

  seen[key] = true
  table.insert(qf_list, {
    filename = vim.fn.fnamemodify(file, ':p'),
    lnum = tonumber(lnum),
    col = tonumber(col),
    text = quickfix_text(string.format('%s %s: %s', type:upper(), code, msg)),
    type = type:sub(1, 1):upper(),
    user_data = user_data,
  })
end

local function set_quickfix(qf_list, title)
  vim.fn.setqflist({}, 'r', { title = title, items = qf_list })
end

local function open_quickfix(mode, action)
  if vim.fn.exists ':Trouble' == 2 then
    local trouble_mode = mode or 'quickfix'
    vim.cmd('silent Trouble ' .. trouble_mode)
    vim.defer_fn(function()
      vim.cmd('silent Trouble ' .. trouble_mode .. ' ' .. (action or 'fold_close_all'))
    end, 50)
  else
    vim.cmd 'silent copen'
  end
end

local function get_current_qf_item()
  local qf = vim.fn.getqflist { title = 1, items = 1, idx = 0 }
  if qf.title ~= 'dotnet test' then
    return nil
  end

  local idx = qf.idx
  if vim.bo.filetype == 'qf' then
    idx = vim.fn.line '.'
  end

  return qf.items and qf.items[idx] or nil
end

local function dotnet_test_detail(item)
  local user_data = item and item.user_data
  if type(user_data) == 'table' and type(user_data.dotnet_test) == 'table' then
    return user_data.dotnet_test.detail
  end

  return nil
end

local function stack_frame_location(line)
  return line:match('%s+at .- in (.-):line (%d+)')
end

local function open_detail_window(title, detail)
  local lines = vim.split(detail, '\n', { plain = true })
  if #lines == 0 then
    lines = { detail }
  end

  local width = 80
  for index, line in ipairs(lines) do
    if index > 500 then
      break
    end
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local ui = vim.api.nvim_list_uis()[1] or { width = 120, height = 40 }
  width = math.min(width + 2, math.floor(ui.width * 0.9))
  local height = math.min(math.max(#lines, 1), math.floor(ui.height * 0.8))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'dotnet-test-output', { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    border = 'rounded',
    title = ' ' .. title .. ' ',
    style = 'minimal',
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function jump_to_frame()
    local line = vim.api.nvim_get_current_line()
    local file, lnum = stack_frame_location(line)
    if not file or not lnum then
      vim.notify('No source location on this line', vim.log.levels.WARN)
      return
    end

    close()
    vim.cmd('edit ' .. vim.fn.fnameescape(file))
    pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(lnum), 0 })
    vim.cmd 'normal! zz'
  end

  vim.keymap.set('n', 'q', close, { buffer = buf, silent = true, desc = 'Close test failure' })
  vim.keymap.set('n', '<Esc>', close, { buffer = buf, silent = true, desc = 'Close test failure' })
  vim.keymap.set('n', '<CR>', jump_to_frame, { buffer = buf, silent = true, desc = 'Jump to stack frame' })
  vim.keymap.set('n', 'gf', jump_to_frame, { buffer = buf, silent = true, desc = 'Jump to stack frame' })
end

local function show_current_failure(item)
  local detail = dotnet_test_detail(item)

  if not detail and vim.bo.filetype == 'qf' then
    item = get_current_qf_item()
    detail = dotnet_test_detail(item)
  end

  if not detail then
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
    local details_by_line = source_failure_details[filename]
    if details_by_line then
      detail = details_by_line[vim.fn.line '.']
    end
  end

  if not detail then
    item = item or get_current_qf_item()
    detail = dotnet_test_detail(item)
  end

  if not detail then
    vim.notify('No dotnet test detail for this quickfix item', vim.log.levels.WARN)
    return
  end

  open_detail_window((item and item.text) or 'dotnet test failure', detail)
end

-- Run `dotnet test` asynchronously and publish failures to the normal quickfix
-- list. Quickfix entries stay short and jumpable; the full failure output is
-- stored in item.user_data and can be opened with :DotnetTestShowFailure.
local function dotnet_test_quickfix_async(cmd)
  local test_cmd = cmd
  if not test_cmd then
    local sln = utils.find_sln_file()
    if not sln then
      status.notify('dotnet test', utils.command_icons.error .. ' No .sln file found', vim.log.levels.ERROR)
      return
    end

    test_cmd = { 'dotnet', 'test', sln }
  end

  local test_status = status.start('dotnet test', 'Running: ' .. command_text(test_cmd))
  vim.fn.setqflist({}, 'r') -- clear quickfix first
  source_failure_details = {}

  local diagnostic_pattern = '^(.-)%((%d+),(%d+)%)%s*:%s*(%a+)%s+(%w+)%s*:%s*(.+)$'
  local stack_frame_pattern = '%s+at .- in (.-):line (%d+)'
  local parser = {
    qf_list = {},
    failure_groups = {},
    seen = {},
    current_test = nil,
    current_message = nil,
    in_error_message = false,
    run_error_message = nil,
    current_frames = {},
    current_failure_lines = {},
  }

  local function short_test_name(test_name)
    return test_name:match '([%w_`]+%.[^%.]+)$' or test_name
  end

  local function test_display_name(test_name)
    return short_test_name(test_name):match '^[^%.]+%.(.+)$' or test_name
  end

  local function find_failure_frame(test_name, frames)
    local frame = nil
    local class_name = short_test_name(test_name):match '^([^%.]+)%.'
    if class_name then
      for _, candidate in ipairs(frames) do
        if candidate.file and vim.fn.fnamemodify(candidate.file, ':t:r') == class_name then
          frame = candidate
          break
        end
      end
    end

    if not frame then
      for _, candidate in ipairs(frames) do
        if candidate.file and candidate.file:match '%.Tests[/\\]' then
          frame = candidate
          break
        end
      end
    end

    return frame or frames[1]
  end

  local function sort_quickfix()
    local severity_order = {
      E = 1,
      W = 2,
    }

    table.sort(parser.qf_list, function(a, b)
      local a_severity = severity_order[a.type] or 99
      local b_severity = severity_order[b.type] or 99
      if a_severity ~= b_severity then
        return a_severity < b_severity
      end

      local a_has_location = a.filename ~= nil and a.lnum ~= nil
      local b_has_location = b.filename ~= nil and b.lnum ~= nil
      if a_has_location ~= b_has_location then
        return a_has_location
      end

      local a_filename = a.filename or ''
      local b_filename = b.filename or ''
      if a_filename ~= b_filename then
        return a_filename < b_filename
      end

      local a_lnum = a.lnum or 0
      local b_lnum = b.lnum or 0
      if a_lnum ~= b_lnum then
        return a_lnum < b_lnum
      end

      local a_col = a.col or 0
      local b_col = b.col or 0
      if a_col ~= b_col then
        return a_col < b_col
      end

      return (a.text or '') < (b.text or '')
    end)
  end

  local function add_quickfix_item(item)
    local key = table.concat({
      item.filename or '',
      item.lnum or 0,
      item.col or 0,
      item.type or '',
      item.text or '',
    }, '|')
    if parser.seen[key] then
      return false
    end

    parser.seen[key] = true
    table.insert(parser.qf_list, item)
    return true
  end

  local function fallback_location()
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file ~= '' and vim.fn.filereadable(current_file) == 1 then
      return current_file
    end

    return utils.find_sln_file(vim.fn.getcwd())
  end

  local function add_failure(file, lnum, summary, text)
    local filename = vim.fn.fnamemodify(file, ':p')
    local line_number = tonumber(lnum)
    local key = table.concat({ filename, line_number, 1 }, '|')
    local group = parser.failure_groups[key]
    if not group then
      group = {
        filename = filename,
        lnum = line_number,
        col = 1,
        summaries = {},
        details = {},
      }
      parser.failure_groups[key] = group
    end

    table.insert(group.summaries, summary)
    table.insert(group.details, text)
  end

  local function add_failure_without_location(text)
    local fallback_file = fallback_location()
    local item = {
      text = quickfix_text(first_line(text) or text),
      type = 'E',
      user_data = {
        dotnet_test = {
          detail = text,
        },
      },
    }

    if fallback_file then
      item.filename = vim.fn.fnamemodify(fallback_file, ':p')
      item.lnum = 1
      item.col = 1
    end

    add_quickfix_item(item)
  end

  -- Finalize the currently parsed failing test. Prefer a frame matching the
  -- test class, then any *.Tests frame, then the first parsed frame. Stackless
  -- failures use a fallback file so Trouble can display them as valid items.
  local function flush_failure()
    if not parser.current_test then
      parser.current_frames = {}
      parser.current_message = nil
      parser.current_failure_lines = {}
      return
    end

    local frame = find_failure_frame(parser.current_test, parser.current_frames)
    local test_name = test_display_name(parser.current_test)
    local full_message = parser.current_message and ('FAILED ' .. test_name .. ': ' .. parser.current_message) or ('FAILED ' .. test_name)
    local summary = full_message
    if parser.current_message then
      summary = quickfix_text(full_message)
    end

    local full_text = vim.trim(table.concat(parser.current_failure_lines, '\n'))
    local qf_text = summary
    if full_text ~= '' then
      qf_text = summary .. '\n' .. full_text
    end

    if frame then
      add_failure(frame.file, frame.lnum, summary, qf_text)
    else
      add_failure_without_location(qf_text)
    end

    parser.current_test = nil
    parser.current_message = nil
    parser.current_frames = {}
    parser.current_failure_lines = {}
  end

  -- Parse one line of dotnet output.
  -- Handles compiler diagnostics immediately, otherwise accumulates test failure
  -- context until the next failure or process exit calls `flush_failure`.
  local function parse_line(line)
    line = strip_ansi(line)
    if line:match '^%s*Failed!%s+%-%s+Failed:%s+%d+,%s+Passed:%s+%d+,%s+Skipped:%s+%d+,%s+Total:%s+%d+,' then
      flush_failure()
      return
    end

    local file, lnum, col, type, code, msg = string.match(line, diagnostic_pattern)
    if file and lnum and col and type and code and msg and (type == 'error' or type == 'warning') then
      add_dotnet_diagnostic(parser.qf_list, parser.seen, file, lnum, col, type, code, msg)
      return
    end

    local failed_test = string.match(line, '^%s*Failed%s+(.+)$')
    if failed_test then
      flush_failure()
      parser.current_test = vim.trim(failed_test:gsub('%s*%[%d+%s*ms%]%s*$', ''))
      parser.current_message = nil
      parser.current_frames = {}
      parser.current_failure_lines = { line }
      parser.in_error_message = false
      return
    end

    if parser.current_test then
      table.insert(parser.current_failure_lines, line)
    end

    if string.match(line, 'The active test run was aborted') or string.match(line, 'Test Run Aborted') then
      parser.run_error_message = vim.trim(line)
      return
    end

    if string.match(line, '^%s*Error Message:%s*$') then
      parser.in_error_message = true
      return
    end

    if string.match(line, '^%s*Stack Trace:%s*$') then
      parser.in_error_message = false
      return
    end

    if parser.in_error_message and string.match(line, '%S') then
      local message_line = vim.trim(line)
      if parser.current_message then
        parser.current_message = parser.current_message .. ' ' .. message_line
      else
        parser.current_message = message_line
      end
      return
    end

    local stack_file, stack_lnum = string.match(line, stack_frame_pattern)
    if stack_file and stack_lnum then
      table.insert(parser.current_frames, { file = stack_file, lnum = stack_lnum })
    end
  end

  local function parse_output(_, data)
    if not data then
      return
    end

    for _, line in ipairs(data) do
      parse_line(line)
    end
  end

  local function add_grouped_failures()
    for _, group in pairs(parser.failure_groups) do
      local count = #group.details
      local text = group.details[1]
      if count > 1 then
        local lines = { string.format('[%d failures] %s', count, group.summaries[1]) }
        for index, detail in ipairs(group.details) do
          table.insert(lines, '')
          table.insert(lines, string.format('--- Failure %d of %d ---', index, count))
          table.insert(lines, detail)
        end
        text = table.concat(lines, '\n')
      end

      add_quickfix_item {
        filename = group.filename,
        lnum = group.lnum,
        col = group.col,
        text = count > 1 and quickfix_text(string.format('[%d failures] %s', count, group.summaries[1])) or quickfix_text(group.summaries[1]),
        type = 'E',
        user_data = {
          dotnet_test = {
            detail = text,
          },
        },
      }
    end
  end

  local job_id = vim.fn.jobstart(test_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = parse_output,
    on_stderr = parse_output,

    on_exit = function(_, code)
      flush_failure()
      add_grouped_failures()

      if parser.run_error_message and #parser.qf_list == 0 then
        add_failure_without_location(parser.run_error_message)
      end

      if code ~= 0 and #parser.qf_list == 0 then
        add_failure_without_location('dotnet test failed with exit code ' .. code)
      end

      if #parser.qf_list > 0 then
        sort_quickfix()
        set_quickfix(parser.qf_list, 'dotnet test')
        for _, item in ipairs(parser.qf_list) do
          local detail = dotnet_test_detail(item)
          if detail and item.filename then
            source_failure_details[item.filename] = source_failure_details[item.filename] or {}
            source_failure_details[item.filename][item.lnum or 1] = detail
          end
        end
        open_quickfix 'dotnet_test'
      end

      if code == 0 then
        test_status.finish(utils.command_icons.success .. ' Tests passed.', vim.log.levels.INFO)
      else
        test_status.finish(utils.command_icons.error .. ' Tests failed with exit code ' .. code, vim.log.levels.ERROR)
      end
    end,
  })

  if job_id <= 0 then
    test_status.finish(utils.command_icons.error .. ' Failed to start dotnet test', vim.log.levels.ERROR)
  end
end

M.run = dotnet_test_quickfix_async
M.show_failure = show_current_failure

vim.api.nvim_create_user_command('DotnetTestShowFailure', function()
  show_current_failure()
end, {})

local qf_group = vim.api.nvim_create_augroup('DotnetTestQuickfix', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = qf_group,
  pattern = 'qf',
  callback = function(event)
    local qf = vim.fn.getqflist { title = 1 }
    if qf.title ~= 'dotnet test' then
      return
    end

    vim.keymap.set('n', 'K', show_current_failure, { buffer = event.buf, silent = true, desc = 'Show dotnet test failure' })
  end,
})

return M
