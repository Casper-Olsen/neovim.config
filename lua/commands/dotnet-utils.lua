local M = {}

function M.find_sln_file(start_path)
  local function is_sln_file(name)
    return name:match '%.sln$'
  end

  local path = vim.fn.expand(start_path or '%:p:h')
  while path ~= '/' and path ~= '' do
    local files = vim.fn.readdir(path)
    for _, filename in ipairs(files) do
      if is_sln_file(filename) then
        return path .. '/' .. filename
      end
    end
    path = vim.fn.fnamemodify(path .. '/..', ':p') or ''
  end
  return nil
end

return M
