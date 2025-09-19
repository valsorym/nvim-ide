-- Language-specific formatting and tools
return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" } })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
    opts = {
      formatters_by_ft = {
        bash = { "shfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        css = { "prettier" },
        go = { "goimports", "gofumpt" },
        html = { "prettier" },
        javascript = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        lua = { "stylua" },
        markdown = { "prettier" },
        python = { "isort", "black" },
        scss = { "prettier" },
        sh = { "shfmt" },
        typescript = { "prettier" },
        yaml = { "prettier" },
      },
      format_on_save = function(bufnr)
        if vim.g.format_on_save == false then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2" },
        },
        black = {
          prepend_args = { "--line-length", "88" },
        },
        clang_format = {
          prepend_args = { "--style=Google" },
        },
      },
    },
  },

  -- Language servers additional configurations
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- CSS/SCSS language server
        cssls = {
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
          },
        },
        
        -- HTML language server
        html = {
          filetypes = { "html", "htmldjango" },
          settings = {
            html = {
              format = {
                templating = true,
                wrapLineLength = 120,
                wrapAttributes = "auto",
              },
              hover = {
                documentation = true,
                references = true,
              },
            },
          },
        },
        
        -- Emmet for HTML/CSS expansion
        emmet_ls = {
          filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact" },
        },
      },
    },
  },

  -- Django template support
  {
    "tweekmonster/django-plus.vim",
    ft = { "python", "htmldjango" },
  },

  -- Jinja2 template support (for Django and other Python frameworks)
  {
    "Glench/Vim-Jinja2-Syntax",
    ft = { "jinja", "jinja2", "htmljinja", "htmldjango" },
  },

  -- Better Python indentation
  {
    "Vimjas/vim-python-pep8-indent",
    ft = "python",
  },

  -- Python docstring generator
  {
    "heavenshell/vim-pydocstring",
    ft = "python",
    build = "make install",
    keys = {
      { "<leader>pd", "<Plug>(pydocstring)", desc = "Generate Python Docstring", ft = "python" },
    },
  },

  -- Go development enhancements
  {
    "fatih/vim-go",
    ft = "go",
    build = ":GoUpdateBinaries",
    init = function()
      vim.g.go_def_mapping_enabled = 0 -- Disable vim-go's gd mapping
      vim.g.go_doc_keywordprg_enabled = 0 -- Disable vim-go's K mapping
      vim.g.go_fmt_autosave = 1
      vim.g.go_imports_autosave = 1
      vim.g.go_mod_fmt_autosave = 1
      vim.g.go_highlight_types = 1
      vim.g.go_highlight_fields = 1
      vim.g.go_highlight_functions = 1
      vim.g.go_highlight_function_calls = 1
      vim.g.go_highlight_operators = 1
      vim.g.go_highlight_extra_types = 1
      vim.g.go_highlight_build_constraints = 1
    end,
  },

  -- C/C++ enhancements
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp" },
    opts = {},
  },

  -- TypeScript/JavaScript specific tools
  {
    "jose-elias-alvarez/typescript.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      server = {
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      },
    },
  },

  -- Package.json management
  {
    "vuki656/package-info.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    ft = "json",
    opts = {},
  },

  -- Bash language server
  {
    "bash-lsp/bash-language-server",
    ft = { "sh", "bash" },
  },

  -- YAML support
  {
    "stephpy/vim-yaml",
    ft = "yaml",
  },

  -- TOML support
  {
    "cespare/vim-toml",
    ft = "toml",
  },
}