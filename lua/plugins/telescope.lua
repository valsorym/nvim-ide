-- Telescope fuzzy finder
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
    { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
    { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
    { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace Symbols" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    { "<leader>ft", "<cmd>Telescope treesitter<cr>", desc = "Treesitter" },
    { "gr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
    { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Definitions" },
    { "gi", "<cmd>Telescope lsp_implementations<cr>", desc = "Implementations" },
    { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search in current buffer" },
  },
  opts = {
    defaults = {
      prompt_prefix = " ",
      selection_caret = " ",
      mappings = {
        i = {
          ["<C-n>"] = "move_selection_next",
          ["<C-p>"] = "move_selection_previous",
          ["<C-c>"] = "close",
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          ["<C-q>"] = "send_to_qflist",
          ["<C-l>"] = "complete_tag",
          ["<C-/>"] = "which_key",
        },
        n = {
          ["<esc>"] = "close",
          ["<CR>"] = "select_default",
          ["<C-q>"] = "send_to_qflist",
          ["j"] = "move_selection_next",
          ["k"] = "move_selection_previous",
          ["H"] = "move_to_top",
          ["M"] = "move_to_middle",
          ["L"] = "move_to_bottom",
          ["<Down>"] = "move_selection_next",
          ["<Up>"] = "move_selection_previous",
          ["gg"] = "move_to_top",
          ["G"] = "move_to_bottom",
          ["<C-u>"] = "preview_scrolling_up",
          ["<C-d>"] = "preview_scrolling_down",
          ["<PageUp>"] = "results_scrolling_up",
          ["<PageDown>"] = "results_scrolling_down",
          ["?"] = "which_key",
        },
      },
    },
    pickers = {
      find_files = {
        theme = "dropdown",
        previewer = false,
        hidden = true,
        file_ignore_patterns = { "node_modules", ".git", ".venv" },
      },
      live_grep = {
        additional_args = function(opts)
          return {"--hidden"}
        end,
        file_ignore_patterns = { "node_modules", ".git", ".venv" },
      },
      buffers = {
        theme = "dropdown",
        previewer = false,
        initial_mode = "normal",
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  },
  config = function(_, opts)
    require("telescope").setup(opts)
    
    -- Load extensions
    pcall(require("telescope").load_extension, "fzf")
  end,
}