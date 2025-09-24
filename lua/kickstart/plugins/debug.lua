return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = {
    {
      '<leader>dr',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<leader>de',
      function()
        require('dap').terminate { all = true }
      end,
      desc = '[D]ebug: [E]nd',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = '[D]ebug: Step [O]ver',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = '[D]ebug: Step [I]nto',
    },
    {
      '<S-F11>',
      function()
        require('dap').step_out()
      end,
      desc = '[D]ebug: Step [O]ut',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = '[D]ebug: Toggle [B]reakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = '[D]ebug: Set [B]reakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    local ok, dotnet = pcall(require, 'custom.dap-dotnet')
    if not ok then
      print 'Failed to load custom.nvim-dap-dotnet'
    else
      print 'Loaded custom.nvim-dap-dotnet successfully'
    end

    local mason_path = vim.fn.stdpath 'data' .. '/mason/packages/netcoredbg/netcoredbg'

    local netcoredbg_adapter = {
      type = 'executable',
      command = mason_path,
      args = {
        '--interpreter=vscode',
      },
    }
    -- Needed for normal debugging
    dap.adapters.netcoredbg = netcoredbg_adapter
    --
    -- Needed for unit test debugging
    dap.adapters.coreclr = netcoredbg_adapter

    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'NetCoreDbg - Debug',
        request = 'launch',
        program = function()
          return dotnet.build_dll_path()
        end,
        stopAtEntry = false,
      },
      -- {
      --   type = 'coreclr',
      --   name = 'NetCoreDbg - Debug nearest xUnit Test',
      --   request = 'launch',
      --   program = 'dotnet',
      --   args = function()
      --     local dllPath = dotnet.build_dll_path()
      --     local test_name = require('custom.dap-dotnet').find_nearest_xunit_test()
      --     if test_name then
      --       return {
      --         'vstest',
      --         dllPath,
      --         '--TestCaseFilter:FullyQualifiedName~' .. test_name,
      --       }
      --     else
      --       return { 'vstest', dllPath }
      --     end
      --   end,
      --   env = { VSTEST_HOST_DEBUG = '1', DOTNET_Configuration = 'Debug' },
      --   cwd = '${workspaceFolder}',
      --   console = 'integratedTerminal',
      --   stopAtEntry = false,
      -- },
    }
    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'cppdbg',
        'netcoredbg',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }
  end,
}
