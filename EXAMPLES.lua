-- Example configurations and usage patterns for NVim-IDE

-- This file demonstrates how to use and customize the NVim-IDE configuration
-- Copy these examples into your configuration files as needed

--[[
EXAMPLE 1: Custom Language Server Configuration
Add a new language server by modifying lua/plugins/lsp.lua
]]--

-- Add to servers table in lsp.lua:
servers = {
  -- Existing servers...
  
  -- Add Rust support
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
        },
        checkOnSave = {
          command = "clippy",
        },
      },
    },
  },
  
  -- Add Tailwind CSS support
  tailwindcss = {
    filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
}

--[[
EXAMPLE 2: Custom Key Mappings
Add to lua/config/keymaps.lua
]]--

-- Custom development shortcuts
vim.keymap.set("n", "<leader>cr", "<cmd>!cargo run<cr>", { desc = "Cargo Run" })
vim.keymap.set("n", "<leader>ct", "<cmd>!cargo test<cr>", { desc = "Cargo Test" })
vim.keymap.set("n", "<leader>py", "<cmd>!python %<cr>", { desc = "Run Python File" })
vim.keymap.set("n", "<leader>go", "<cmd>!go run %<cr>", { desc = "Run Go File" })
vim.keymap.set("n", "<leader>cc", "<cmd>!gcc % -o %:r && ./%:r<cr>", { desc = "Compile and Run C" })

-- Django specific shortcuts
vim.keymap.set("n", "<leader>dm", "<cmd>!python manage.py migrate<cr>", { desc = "Django Migrate" })
vim.keymap.set("n", "<leader>ds", "<cmd>!python manage.py runserver<cr>", { desc = "Django Server" })
vim.keymap.set("n", "<leader>dt", "<cmd>!python manage.py test<cr>", { desc = "Django Tests" })

--[[
EXAMPLE 3: Custom Auto Commands
Add to lua/config/autocmds.lua
]]--

-- Auto-format on save for specific file types
local format_group = vim.api.nvim_create_augroup("AutoFormat", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = format_group,
  pattern = { "*.py", "*.go", "*.js", "*.ts", "*.json", "*.lua" },
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- Set specific options for Django templates
vim.api.nvim_create_autocmd("FileType", {
  pattern = "htmldjango",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    -- Enable Emmet for Django templates
    vim.b.user_emmet_settings = {
      ["html"] = {
        ["snippets"] = {
          ["!!!"] = "<!DOCTYPE html>",
        },
      },
    }
  end,
})

--[[
EXAMPLE 4: Custom Plugin Configuration
Add to lua/plugins/ directory
]]--

-- Example: Adding a new plugin (save as lua/plugins/custom.lua)
return {
  -- Database integration
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
    cmd = { "DBUI", "DBUIToggle" },
    keys = {
      { "<leader>du", "<cmd>DBUIToggle<cr>", desc = "Toggle Database UI" },
    },
    config = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_winwidth = 30
    end,
  },

  -- REST client
  {
    "rest-nvim/rest.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = "http",
    keys = {
      { "<leader>rr", "<cmd>Rest run<cr>", desc = "Run REST request" },
    },
    opts = {},
  },
}

--[[
EXAMPLE 5: Project-Specific Configuration
Create .nvim.lua in your project root
]]--

-- Project-specific settings (save as .nvim.lua in project root)
-- This file will be automatically loaded when you open the project

-- Python Django project example
vim.opt_local.path:append("apps/**")  -- Add Django apps to path
vim.g.python_recommended_style = 0   -- Disable Python style recommendations

-- Set project-specific environment
vim.env.DJANGO_SETTINGS_MODULE = "myproject.settings.development"

-- Custom commands for this project
vim.api.nvim_create_user_command("DjangoMigrate", "!python manage.py migrate", {})
vim.api.nvim_create_user_command("DjangoShell", "!python manage.py shell", {})
vim.api.nvim_create_user_command("DjangoTest", "!python manage.py test", {})

-- Go project example
-- vim.opt_local.makeprg = "go build"
-- vim.opt_local.errorformat = "%f:%l:%c: %m"

--[[
EXAMPLE 6: Custom Snippets
Add to after/plugin/snippets.lua
]]--

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- Django model snippet
ls.add_snippets("python", {
  s("djmodel", {
    t("class "), i(1, "ModelName"), t("(models.Model):"), t({ "", "    " }),
    i(2, "# Add fields here"), t({ "", "", "    def __str__(self):", "        return self." }),
    i(3, "name"), t({ "", "", "    class Meta:", "        verbose_name = '" }),
    i(4, "Model Name"), t("'"), t({ "", "        verbose_name_plural = '" }),
    i(5, "Model Names"), t("'"),
  }),
})

-- Go struct snippet
ls.add_snippets("go", {
  s("struct", {
    t("type "), i(1, "StructName"), t(" struct {"), t({ "", "\t" }),
    i(2, "Field"), t(" "), i(3, "string"), t({ "", "}" }),
  }),
})

-- HTML5 Django template snippet
ls.add_snippets("htmldjango", {
  s("html5", {
    t("<!DOCTYPE html>"), t({ "", "<html lang=\"en\">", "<head>" }),
    t({ "", "\t<meta charset=\"UTF-8\">" }),
    t({ "", "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">" }),
    t({ "", "\t<title>" }), i(1, "Page Title"), t("</title>"),
    t({ "", "</head>", "<body>" }), t({ "", "\t" }), i(2, "<!-- Content -->"),
    t({ "", "</body>", "</html>" }),
  }),
})

--[[
EXAMPLE 7: Terminal Integration Examples
]]--

-- Custom terminal functions
function _G.open_project_terminal()
  local Terminal = require("toggleterm.terminal").Terminal
  local term = Terminal:new({
    cmd = "cd " .. vim.fn.getcwd() .. " && bash",
    direction = "horizontal",
    size = 15,
  })
  term:toggle()
end

-- Map to key
vim.keymap.set("n", "<leader>pt", "<cmd>lua open_project_terminal()<cr>", { desc = "Project Terminal" })

--[[
EXAMPLE 8: Language-Specific Formatters
Add to lua/plugins/languages.lua
]]--

-- Custom formatter configuration
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    -- Add custom formatters
    sql = { "sqlformat" },
    dockerfile = { "dockfmt" },
    terraform = { "terraform_fmt" },
  },
  
  -- Custom formatter definitions
  formatters = {
    sqlformat = {
      command = "sqlformat",
      args = { "--reindent", "--keywords", "upper", "--identifiers", "lower", "-" },
    },
  },
})

--[[
EXAMPLE 9: Debugging Configuration
Add to your LSP configuration
]]--

-- Python debugging setup
local dap = require("dap")
local dap_python = require("dap-python")

-- Configure Python debugger
dap_python.setup("python") -- Use system Python

-- Django debugging configuration
dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Django",
    program = vim.fn.getcwd() .. "/manage.py",
    args = { "runserver", "--noreload" },
    django = true,
    justMyCode = true,
  },
}

-- Go debugging
dap.adapters.delve = {
  type = "server",
  port = "${port}",
  executable = {
    command = "dlv",
    args = { "dap", "-l", "127.0.0.1:${port}" },
  }
}

dap.configurations.go = {
  {
    type = "delve",
    name = "Debug",
    request = "launch",
    program = "${file}"
  },
}

--[[
EXAMPLE 10: Custom UI Enhancements
]]--

-- Custom status line components
local function django_env()
  local django_settings = vim.env.DJANGO_SETTINGS_MODULE
  if django_settings then
    return "Django: " .. django_settings:match("([^.]+)$")
  end
  return ""
end

-- Add to lualine configuration
require("lualine").setup({
  sections = {
    lualine_c = {
      "filename",
      django_env, -- Custom Django environment indicator
    },
  },
})

--[[
USAGE TIPS:

1. Language-Specific Workflows:

   Python/Django:
   - Use <leader>vs to select virtual environment
   - Use <leader>dm for Django migrations
   - Django templates have syntax highlighting
   - Use :DBUIToggle for database management

   Go:
   - Use <leader>go to run current file
   - GoTest for running tests
   - Automatic goimports on save
   - Delve debugging integration

   C/C++:
   - Use <leader>ch to switch header/source
   - clang-format on save
   - Build with :make
   - GDB debugging support

   JavaScript/TypeScript:
   - ESLint integration
   - Prettier formatting
   - React component support
   - Node.js debugging

2. File Management:
   - <leader>e to toggle file explorer
   - <leader>ff to find files
   - <leader>fg to search in files
   - <leader>fb to browse buffers

3. Git Workflow:
   - <leader>gs for git status
   - <leader>gg for lazygit
   - ]h/[h to navigate hunks
   - <leader>ghs to stage hunks

4. Terminal Usage:
   - <C-\> for floating terminal
   - <leader>tp for Python REPL
   - <leader>tn for Node.js REPL
   - Multiple terminal instances

5. Debugging:
   - <leader>db to toggle breakpoint
   - <leader>dc to continue debugging
   - Built-in DAP UI for debugging
   - Language-specific configurations
]]--