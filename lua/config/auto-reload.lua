-- ~/.config/nvim/lua/config/auto-reload.lua
-- Simple, safe auto-reload (no deps). Flat icons. Lazy-aware.

local M = {}

function M.setup(opts)
    opts = opts or {}
    local config_dir = vim.fn.stdpath("config")
    local debounce_ms = opts.debounce_ms or 150

    -- Nerd Font icons (flat).
    local ico_ok, ico_err, ico_cfg = "", "", ""

    -- Debounce timers per file.
    local pending = {}

    local function debounced(file, fn, delay)
        delay = delay or debounce_ms
        if pending[file] then
            pending[file]:stop()
            pending[file]:close()
        end
        local t = vim.loop.new_timer()
        pending[file] = t
        t:start(delay, 0, function()
            t:stop()
            t:close()
            pending[file] = nil
            vim.schedule(fn)
        end)
    end

    -- Echo helper.
    local function echo(msg, hl)
        vim.cmd('echo ""')
        vim.api.nvim_echo({{msg, hl or "MoreMsg"}}, false, {})
        vim.defer_fn(function() vim.cmd('echo ""') end, 2500)
    end

    -- Make module name from absolute path under 'lua/'.
    local function to_module(path)
        local rel = path:gsub("^" .. vim.pesc(config_dir), "")
        if not rel:match("^/lua/") then return nil end
        local mod = rel:gsub("^/lua/", "")
        mod = mod:gsub("%.lua$", "")
        mod = mod:gsub("/", ".")
        return mod
    end

    -- Try Lazy.nvim CLI if available.
    local function try_lazy_reload(arg)
        if vim.fn.exists(":Lazy") == 2 then
            if arg and arg ~= "" then
                vim.cmd("Lazy reload " .. arg)
            else
                vim.cmd("Lazy reload")
            end
            return true
        end
        return false
    end

    -- Best-effort reload of a single module.
    local function reload_module(mod)
        if not mod then return false end
        package.loaded[mod] = nil
        local ok, res = pcall(require, mod)
        if not ok then
            echo(ico_err .. "  Reload error: " .. mod, "ErrorMsg")
            return false
        end
        -- If module returns a table with setup(), call it.
        if type(res) == "table" and type(res.setup) == "function" then
            pcall(res.setup)
        end
        return true
    end

    -- Smart reload.
    local function reload_config(filepath)
        local norm = vim.fn.fnamemodify(filepath, ":p")

        -- 1) init.lua => clear config/plugins namespaces and re-run init.
        if norm == config_dir .. "/init.lua" then
            for name, _ in pairs(package.loaded) do
                if name:match("^config%.") or name:match("^plugins%.") then
                    package.loaded[name] = nil
                end
            end
            local ok, err = pcall(dofile, norm)
            if ok then
                echo(ico_ok .. "  " .. ico_cfg .. " init.lua reloaded")
            else
                echo(ico_err .. "  init.lua: " .. tostring(err), "ErrorMsg")
            end
            return
        end

        -- 2) lua/config/*.lua => reload module and call setup() if any.
        if norm:match("^" .. vim.pesc(config_dir) .. "/lua/config/") then
            local mod = to_module(norm)
            if reload_module(mod) then
                echo(ico_ok .. "  " .. ico_cfg .. "  " .. mod .. " reloaded")
            end
            return
        end

        -- 3) lua/plugins/*.lua => prefer Lazy reload if present.
        if norm:match("^" .. vim.pesc(config_dir) .. "/lua/plugins/") then
            -- Use file stem as reload pattern, fallback to full reload.
            local stem = vim.fn.fnamemodify(norm, ":t"):gsub("%.lua$", "")
            local ok = try_lazy_reload(stem)
            if not ok then
                -- Without Lazy, we only clear module to take effect on
                -- next restart; side effects (if any) are re-required.
                local mod = to_module(norm)
                reload_module(mod)
                echo(ico_ok .. "  plugins saved (reload on restart)")
                return
            end
            echo(ico_ok .. "  plugins reloaded: " .. stem)
            return
        end

        -- 4) Any other file under config: try module reload if mappable.
        local mod = to_module(norm)
        if mod and reload_module(mod) then
            echo(ico_ok .. " " .. ico_cfg .. " " .. mod .. " reloaded")
        else
            echo(ico_ok .. "  Ok", "MoreMsg")
        end
    end

    -- Autocmds.
    local group = vim.api.nvim_create_augroup(
        "ConfigAutoReload", { clear = true }
    )

    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = {
            config_dir .. "/init.lua",
            config_dir .. "/lua/config/*.lua",
            config_dir .. "/lua/plugins/*.lua",
        },
        callback = function(args)
            debounced(args.file, function()
                reload_config(args.file)
            end, debounce_ms)
        end,
        desc = "Auto-reload neovim config on save",
    })

    -- Manual command.
    vim.api.nvim_create_user_command("ReloadConfig", function(param)
        local arg = (param.fargs[1] or "")
        if arg == "init" then
            reload_config(config_dir .. "/init.lua")
        elseif arg == "plugins" then
            if not try_lazy_reload("") then
                echo(ico_err .. " Lazy not found", "ErrorMsg")
            end
        elseif arg == "current" then
            reload_config(vim.fn.expand("%:p"))
        else
            -- Fullish: clear config/plugins modules, re-run init.lua.
            for name, _ in pairs(package.loaded) do
                if name:match("^config%.") or name:match("^plugins%.") then
                    package.loaded[name] = nil
                end
            end
            local ok, err = pcall(dofile, config_dir .. "/init.lua")
            if ok then
                echo(ico_ok .. " " .. ico_cfg .. " config reloaded")
            else
                echo(ico_err .. " reload: " .. tostring(err), "ErrorMsg")
            end
        end
    end, {
        desc = "Manually reload config",
        nargs = "?",
        complete = function()
            return { "init", "plugins", "current" }
        end,
    })

    -- Keymap.
    vim.keymap.set(
        "n", "<leader>R", "<cmd>ReloadConfig current<cr>",
        { desc = "· Reload current config", silent = true }
    )

    -- Suppress default "file changed" prompts on sourced files.
    vim.opt.shortmess:append("F")
end

return M
