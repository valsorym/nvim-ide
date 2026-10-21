-- Single source for global mappings, the command palette and the key reference.
local M = {}
M.groups = {
    b = "Buffers / explorer", c = "Code / language", d = "Document / formatting",
    e = "Editing", f = "Find / replace", g = "Git", o = "Options / tools",
    r = "Run / terminal", t = "Tabs", u = "Interface", w = "Workspaces / sessions",
    x = "Checks / diagnostics",
}

local function command(cmd) return "<Cmd>" .. cmd .. "<CR>" end
local function call(module, method, ...)
    local args = { ... }
    return function() return require(module)[method](unpack(args)) end
end
local function telescope(method, opts)
    return function() require("telescope.builtin")[method](opts or {}) end
end
local function tree_history()
    require("lazy").load({ plugins = { "nvim-tree.lua" } })
    _G.NvimTreeHistory.show_history()
end
local function git_hunk(action)
    return function()
        local mode = vim.fn.mode()
        local range
        if mode == "v" or mode == "V" then
            local a, b = vim.fn.line("v"), vim.fn.line(".")
            range = { math.min(a, b), math.max(a, b) }
        end
        require("gitsigns")[action](range)
    end
end
local function render()
    if require("config.performance").is_large(0) then
        vim.notify("Rendering is disabled for large files", vim.log.levels.WARN)
    elseif vim.bo.filetype == "markdown" then
        require("render-markdown").buf_toggle()
    elseif vim.bo.filetype == "rst" then
        require("config.rst").toggle()
    else
        vim.notify("Rendering is available for Markdown and RST")
    end
end

function M.palette(group)
    local entries = {}
    for _, entry in ipairs(M.entries) do
        -- The palette opens in Normal mode; visual-only actions stay on their keys.
        local modes = type(entry[4]) == "table" and entry[4] or { entry[4] or "n" }
        if vim.tbl_contains(modes, "n") and (not group or entry[1]:sub(1, 9) == "<leader>" .. group) then
            entries[#entries + 1] = entry
        end
    end
    vim.ui.select(entries, { prompt = group and M.groups[group] or "Commands",
        format_item = function(entry) return entry[1] .. "  " .. entry[3] end }, function(entry)
        if not entry then return end
        -- Replay the English mapping; langremap is off so its output stays literal.
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(entry[1], true, false, true), "m", false)
    end)
end

function M.browse()
    local groups = vim.tbl_keys(M.groups)
    table.sort(groups)
    vim.ui.select(groups, { prompt = "Key groups", format_item = function(key)
        return "<leader>" .. key .. "  " .. M.groups[key]
    end }, function(key) if key then M.palette(key) end end)
end

M.entries = {
    { "<leader><leader>", function() M.palette() end, "Search commands" },
    { "<leader>?", function() M.browse() end, "Browse key groups" },
    { "<leader>:", telescope("commands"), "Search Ex commands" },
    { "<leader>bb", telescope("buffers"), "Find buffer" },
    { "<leader>bn", command("bnext"), "Next buffer" },
    { "<leader>bp", command("bprevious"), "Previous buffer" },
    { "<leader>bd", command("confirm bdelete"), "Delete buffer" },
    { "<leader>be", command("NvimTreeModal"), "File explorer" },
    { "<leader>bh", tree_history, "Project history" },
    { "<leader>ca", call("vim.lsp.buf", "code_action"), "Code action", { "n", "x" } },
    { "<leader>cr", call("vim.lsp.buf", "rename"), "Rename symbol" },
    { "<leader>cd", call("config.lsp", "jump", "definition"), "Go to definition in tab" },
    { "<leader>cD", call("config.lsp", "jump", "declaration"), "Go to declaration in tab" },
    { "<leader>ci", call("config.lsp", "jump", "implementation"), "Go to implementation in tab" },
    { "<leader>ct", call("config.lsp", "jump", "type_definition"), "Go to type definition in tab" },
    { "<leader>ch", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature help" },
    { "<leader>cs", command("CodeInspector"), "Document symbols" },
    { "<leader>cS", command("CodeInspectorGrouped"), "Grouped document symbols" },
    { "<leader>cw", telescope("lsp_workspace_symbols"), "Workspace symbols" },
    { "<leader>co", command("AerialToggle!"), "Toggle code outline" },
    { "<leader>cO", command("AerialNavToggle"), "Outline navigation" },
    { "<leader>cva", command("VenvActivate"), "Detect Python environment" },
    { "<leader>cvc", command("VenvSelect"), "Select Python environment" },
    { "<leader>cvd", command("VenvDeactivate"), "Use system Python" },
    { "<leader>cvs", command("VenvStatus"), "Python environment status" },
    { "<leader>cvf", command("VenvFind"), "Refresh Python environment" },
    { "<leader>cpt", command("CopilotToggle"), "Toggle Copilot" },
    { "<leader>cps", command("Copilot status"), "Copilot status" },
    { "<leader>cpa", command("Copilot setup"), "Copilot setup" },
    { "<leader>cpx", command("Copilot signout"), "Copilot sign out" },
    { "<leader>df", call("config.formatting", "format"), "Format document" },
    { "<leader>di", call("config.formatting", "format", { only = "isort" }), "Sort Python imports" },
    { "<leader>db", call("config.formatting", "format", { only = "black" }), "Format Python with Black" },
    { "<leader>ds", command("FormatToggle"), "Toggle format on save" },
    { "<leader>dx", call("config.formatting", "trim"), "Trim trailing whitespace" },
    { "<leader>d2", command("Indent2"), "Use two-space indentation" },
    { "<leader>d4", command("Indent4"), "Use four-space indentation" },
    { "<leader>dt", command("IndentTab"), "Use tab indentation" },
    { "<leader>dS", command("TabsToSpaces"), "Convert tabs to spaces" },
    { "<leader>dT", command("SpacesToTabs"), "Convert spaces to tabs" },
    { "<leader>dI", command("IndentInfo"), "Show indentation settings" },
    { "<leader>dr", render, "Toggle Markdown / RST rendering" },
    { "<leader>ed", '"_d', "Delete without yanking", { "n", "x" } },
    { "<leader>ec", '"_c', "Change without yanking", { "n", "x" } },
    { "<leader>ey", '"+y', "Yank to system clipboard", { "n", "x" } },
    { "<leader>ep", '"+p', "Paste system clipboard", { "n", "x" } },
    { "<leader>ea", 'ggVG"+y', "Yank entire document" },
    { "<leader>eu", command("UndotreeToggle"), "Undo history" },
    { "<leader>ej", ":move '>+1<CR>gv=gv", "Move selection down", "x" },
    { "<leader>ek", ":move '<-2<CR>gv=gv", "Move selection up", "x" },
    { "<leader>ff", telescope("find_files"), "Find files" },
    { "<leader>fg", telescope("live_grep"), "Search project text" },
    { "<leader>fG", telescope("live_grep", { file_ignore_patterns = {}, additional_args = { "--hidden", "--no-ignore", "--glob", "!.git/**" } }), "Search including ignored files" },
    { "<leader>fo", telescope("oldfiles"), "Recent files" },
    { "<leader>fh", telescope("help_tags"), "Find help" },
    { "<leader>fr", call("config.replace", "search", false), "Find and replace in project" },
    { "<leader>fR", call("config.replace", "search", true), "Find and replace including ignored files" },
    { "<leader>fw", call("config.replace", "word"), "Replace current word in project" },
    { "<leader>fj", call("flash", "jump"), "Flash jump", { "n", "x", "o" } },
    { "<leader>fJ", call("flash", "treesitter"), "Flash syntax selection", { "n", "x", "o" } },
    { "<leader>gs", git_hunk("stage_hunk"), "Stage Git hunk", { "n", "x" } },
    { "<leader>gr", git_hunk("reset_hunk"), "Reset Git hunk", { "n", "x" } },
    { "<leader>gp", call("gitsigns", "preview_hunk"), "Preview Git hunk" },
    { "<leader>gb", call("gitsigns", "blame_line", { full = true }), "Blame current line" },
    { "<leader>gd", call("gitsigns", "diffthis"), "Diff current file" },
    { "<leader>gt", call("gitsigns", "toggle_current_line_blame"), "Toggle line blame" },
    { "<leader>ol", command("Lazy"), "Plugin manager" },
    { "<leader>om", command("Mason"), "Language tool manager" },
    { "<leader>oc", function() require("config.nvim-tabs").open(vim.fn.stdpath("config") .. "/init.lua") end, "Open editor configuration" },
    { "<leader>rf", call("config.terminal", "toggle", "float"), "Floating terminal" },
    { "<leader>rh", call("config.terminal", "toggle", "horizontal"), "Horizontal terminal" },
    { "<leader>rv", call("config.terminal", "toggle", "vertical"), "Vertical terminal" },
    { "<leader>rp", call("config.terminal", "run", "python"), "Python REPL" },
    { "<leader>rn", call("config.terminal", "run", "node"), "Node REPL" },
    { "<leader>rd", call("config.terminal", "run", "django"), "Django shell" },
    { "<leader>rr", call("config.terminal", "run", "runserver"), "Django development server" },
    { "<leader>tn", call("config.nvim-tabs", "new"), "New tab" },
    { "<leader>tq", call("config.nvim-tabs", "close", false), "Close current tab" },
    { "<leader>tQ", call("config.nvim-tabs", "close", true), "Discard and close current tab" },
    { "<leader>tc", call("config.nvim-tabs", "close_saved"), "Close saved tabs" },
    { "<leader>to", command("confirm tabonly"), "Close other tabs" },
    { "<leader>tl", call("config.tabs-list", "show_tabs_window"), "Tab list" },
    { "<leader>th", call("config.nvim-tabs", "move_tab_left"), "Move tab left" },
    { "<leader>tj", call("config.nvim-tabs", "move_tab_right"), "Move tab right" },
    { "<leader>ta", command("confirm qall"), "Quit editor" },
    { "<leader>ut", call("config.theme", "pick", false), "Preview and select theme" },
    { "<leader>us", call("config.theme", "pick", true), "Select and save theme" },
    { "<leader>ui", command("ThemeInfo"), "Current theme" },
    { "<leader>uI", function() require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled }) end, "Toggle indent guides" },
    { "<leader>uw", function() vim.wo.wrap = not vim.wo.wrap end, "Toggle wrapping" },
    { "<leader>ul", function() vim.wo.list = not vim.wo.list end, "Toggle whitespace marks" },
    { "<leader>uc", function() vim.wo.colorcolumn = vim.wo.colorcolumn == "" and "79" or "" end, "Toggle column guide" },
    { "<leader>ws", command("SessionSave"), "Save session" },
    { "<leader>wr", command("SessionRestore"), "Restore session" },
    { "<leader>wl", command("SessionLast"), "Restore last session" },
    { "<leader>wD", command("SessionDelete"), "Delete current session" },
    { "<leader>wf", command("SessionFind"), "Find session" },
    { "<leader>wL", command("SessionLegacy"), "Import legacy session" },
    { "<leader>ww", command("WorkspaceFind"), "Find workspace" },
    { "<leader>wa", command("WorkspaceAdd"), "Add workspace" },
    { "<leader>xx", function() vim.diagnostic.open_float({ scope = "line" }) end, "Line diagnostics" },
    { "<leader>xb", command("Trouble diagnostics toggle filter.buf=0"), "Buffer diagnostics" },
    { "<leader>xw", command("Trouble diagnostics toggle"), "Workspace diagnostics" },
    { "<leader>xq", command("Trouble qflist toggle"), "Quickfix list" },
    { "<leader>xl", command("Trouble loclist toggle"), "Location list" },
    { "<leader>xt", command("TodoTelescope"), "Find TODO comments" },
    { "<leader>xT", command("TodoTelescope keywords=TODO,FIX,FIXME"), "Find TODO / FIXME" },
    { "<leader>xp", command("PythonToolsStatus"), "Python tools status" },
    { "<leader>xi", command("checkhealth vim.lsp"), "LSP health" },
    { "<leader>xh", command("checkhealth nvim_ide"), "Editor / terminal health" },
    { "<leader>xL", command("LargeFileInfo"), "Buffer performance mode" },
    { "<F2>", call("config.safe-save", "smart_write"), "Save file", { "n", "i" } },
    { "<F5>", command("tabprevious"), "Previous tab" },
    { "<F6>", command("tabnext"), "Next tab" },
    { "<F7>", command("CodeInspector"), "Document symbols" },
    { "<F8>", call("config.tabs-list", "show_tabs_window"), "Tab list" },
    { "<F9>", command("NvimTreeModal"), "File explorer" },
    { "<F10>", telescope("buffers"), "Buffer list" },
    { "gd", call("config.lsp", "jump", "definition"), "Go to definition in tab" },
    { "gD", call("config.lsp", "jump", "declaration"), "Go to declaration in tab" },
    { "gri", call("config.lsp", "jump", "implementation"), "Go to implementation in tab" },
    { "grt", call("config.lsp", "jump", "type_definition"), "Go to type definition in tab" },
    { "gl", function() vim.diagnostic.open_float({ scope = "line" }) end, "Line diagnostics" },
    { "<C-LeftMouse>", call("config.lsp", "jump", "definition"), "Go to definition in tab" },
    { "zR", call("ufo", "openAllFolds"), "Open all folds" },
    { "zM", call("ufo", "closeAllFolds"), "Close all folds" },
    { "zr", call("ufo", "openFoldsExceptKinds"), "Open folds except configured kinds" },
    { "zm", call("ufo", "closeFoldsWith"), "Fold one more level" },
    { "zp", function() if not require("ufo").peekFoldedLinesUnderCursor() then vim.lsp.buf.hover() end end, "Preview fold" },
    { "]t", call("todo-comments", "jump_next"), "Next TODO" },
    { "[t", call("todo-comments", "jump_prev"), "Previous TODO" },
    { "]c", function() if vim.wo.diff then vim.cmd("normal! ]c") else require("gitsigns").nav_hunk("next") end end, "Next Git hunk" },
    { "[c", function() if vim.wo.diff then vim.cmd("normal! [c") else require("gitsigns").nav_hunk("prev") end end, "Previous Git hunk" },
    { "<Esc>", command("nohlsearch"), "Clear search highlight" },
}

function M.setup()
    vim.ui.select = require("config.picker").select
    for _, entry in ipairs(M.entries) do
        vim.keymap.set(entry[4] or "n", entry[1], entry[2], { silent = true, desc = entry[3] })
    end
    -- Keep native operators, Ctrl-W windows, Ctrl-T tags, Ctrl-K digraphs and z folds.
    vim.keymap.set("x", "<", "<gv", { silent = true })
    vim.keymap.set("x", ">", ">gv", { silent = true })
    vim.api.nvim_create_user_command("TabsList", call("config.tabs-list", "show_tabs_window"), {})
    vim.api.nvim_create_user_command("KeymapLegend", function() M.palette() end, {})
end
return M
