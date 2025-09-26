-- ~/.config/nvim/lua/config/auto-reload.lua
-- Safe, minimal reload: no mass cache clearing, Lazy-aware.

local M = {}

function M.setup(opts)
    opts = opts or {}
    local config_dir = vim.fn.stdpath("config")
    local debounce_ms = opts.debounce_ms or 120

    local ico_ok, ico_err, ico_cfg = "", "", ""
    local uv = vim.uv or vim.loop

    local function pesc(s)
        if vim.pesc then return vim.pesc(s) end
        return (s:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
    end

    local function echo(msg, hl)
        vim.cmd('echo ""')
        vim.api.nvim_echo({{msg, hl or "MoreMsg"}}, false, {})
        vim.defer_fn(function() vim.cmd('echo ""') end, 1800)
    end

    local function is_dir(p) return vim.fn.isdirectory(p) == 1 end
    local function is_file(p) return vim.fn.filereadable(p) == 1 end

    local function try_lazy_reload(arg)
        if vim.fn.exists(":Lazy") == 2 then
            if arg and #arg > 0 then
                pcall(vim.cmd, "Lazy reload " .. arg)
            else
                pcall(vim.cmd, "Lazy reload")
            end
            return true
        end
        return false
    end

    local function stem(p)
        return vim.fn.fnamemodify(p, ":t"):gsub("%.lua$", "")
    end

    local function do_exec(path, label)
        local ok, err = pcall(dofile, path)
        if ok then
            echo(ico_ok .. "  " .. ico_cfg .. " " .. label .. " reloaded")
        else
            echo(ico_err .. "  " .. tostring(err), "ErrorMsg")
        end
    end

    local function reload_path(path)
        local norm = vim.fn.fnamemodify(path, ":p")

        -- Directories: handle special cases, no dofile on dirs.
        if is_dir(norm) then
            local plugdir = config_dir .. "/lua/plugins"
            if norm:match("^" .. pesc(plugdir) .. "/?$") then
                if try_lazy_reload("") then
                    echo(ico_ok .. "  " .. ico_cfg .. " plugins reloaded")
                else
                    echo(ico_err .. "  Lazy not found", "ErrorMsg")
                end
                return
            end
            if norm:match("^" .. pesc(config_dir)) then
                -- For generic config dir, safer to do nothing.
                echo(ico_ok .. "  In config dir (no-op)", "MoreMsg")
                return
            end
            echo(ico_ok .. "  Ok", "MoreMsg")
            return
        end

        -- Files
        if norm == config_dir .. "/init.lua" then
            do_exec(norm, "init.lua")
            return
        end

        if norm:match("^" .. pesc(config_dir) .. "/lua/plugins/") then
            local st = stem(norm)
            if try_lazy_reload(st) then
                echo(ico_ok .. "  " .. ico_cfg .. " plugin: " .. st)
                return
            end
            -- No Lazy: execute file directly (best effort)
            do_exec(norm, "plugin file")
            return
        end

        if norm:match("^" .. pesc(config_dir) .. "/lua/config/") then
            do_exec(norm, "config file")
            return
        end

        -- Any other file under config: best-effort execute.
        if norm:match("^" .. pesc(config_dir)) and is_file(norm) then
            do_exec(norm, "file")
        else
            echo(ico_err .. "  Not a file in config", "ErrorMsg")
        end
    end

    local timers = {}
    local function debounce(key, fn, delay)
        delay = delay or debounce_ms
        if timers[key] then
            timers[key]:stop()
            timers[key]:close()
        end
        local t = uv.new_timer()
        timers[key] = t
        t:start(delay, 0, function()
            t:stop(); t:close(); timers[key] = nil
            vim.schedule(fn)
        end)
    end

    local grp = vim.api.nvim_create_augroup("ConfigAutoReload", {clear=true})
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = grp,
        pattern = {
            config_dir .. "/init.lua",
            config_dir .. "/lua/config/*.lua",
            config_dir .. "/lua/plugins/*.lua",
        },
        callback = function(a)
            debounce(a.file, function() reload_path(a.file) end)
        end,
        desc = "Auto-reload minimal and safe",
    })

    vim.api.nvim_create_user_command("ReloadConfig", function(param)
        local arg = param.fargs[1]
        if arg == "current" or not arg then
            reload_path(vim.fn.expand("%:p"))
        elseif arg == "init" then
            reload_path(config_dir .. "/init.lua")
        elseif arg == "plugins" then
            if not try_lazy_reload("") then
                echo(ico_err .. "  Lazy not found", "ErrorMsg")
            else
                echo(ico_ok .. "  " .. ico_cfg .. " plugins reloaded")
            end
        else
            reload_path(arg)
        end
    end, {nargs = "?", complete = function()
        return {"init","plugins","current"}
    end})

    vim.keymap.set("n", "<leader>xR", function()
        reload_path(vim.fn.expand("%:p"))
    end, {desc = "· Reload VIM config", silent = true})

    vim.opt.shortmess:append("F")
end

return M
