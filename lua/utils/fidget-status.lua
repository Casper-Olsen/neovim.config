local M = {}

function M.notify(title, message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = title })
end

function M.start(title, message, opts)
  opts = opts or {}

  local ok, progress = pcall(require, 'fidget.progress')
  if not ok or not progress.handle or not progress.handle.create then
    M.notify(title, message)

    return {
      finish = function(finish_message, level)
        if opts.notify_on_finish == false then
          return
        end

        M.notify(title, finish_message, level)
      end,
    }
  end

  local handle = progress.handle.create {
    title = title,
    message = message,
    lsp_client = { name = title },
  }

  return {
    finish = function(finish_message, level)
      handle:report {
        message = finish_message,
      }
      handle:finish()

      if opts.notify_on_finish == false then
        return
      end

      local notify_ok, notification = pcall(require, 'fidget.notification')
      if notify_ok then
        notification.notify(finish_message, level or vim.log.levels.INFO, {
          key = handle.token,
          group = title,
          annote = title,
          ttl = 0,
          skip_history = true,
          data = true,
        })
      end
    end,
  }
end

return M
