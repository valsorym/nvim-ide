-- ~/.config/nvim/lua/plugins/sessions.lua
-- Sessions with full Telescope integration like workspace/tree-history

return {
    -- VSCode-like workspace integration.
    {
        "natecraddock/workspaces.nvim",
        config = function()
            require("workspaces").setup({
                path = vim.fn.stdpath("data") .. "/workspaces",
                cd_type = "global",
                sort = true,
                mru_sort = true,
                notify_info = function(msg, title)
                    vim.notify(msg, vim.log.levels.INFO, {
                        title = title or "Workspace",
                        icon = "",
                        timeout = 2000,
                    })
                end,
                hooks = {
                    add = function(name, path)
                        -- Auto-save session when adding workspace
                        if package.loaded["auto-session"] then
                            require("auto-session").SaveSession()
                        end
                    end,
                    remove = function(name, path)
                        -- Clean up session when removing workspace
                        if package.loaded["auto-session"] then
                            require("auto-session").DeleteSession()
                        end
                    end,
                    rename = function(name, path, old_name)
                        vim.notify("Workspace renamed: " .. old_name .. " → " .. name, vim.log.levels.INFO, {
                            title = "Workspaces",
                            icon = "",
                            timeout = 2500,
                        })
                    end,
                    open_pre = function(name, path, prev_path)
                        -- Save current session before switching
                        if package.loaded["auto-session"] then
                            require("auto-session").SaveSession()
                        end
                        -- Close nvim-tree
                        if _G.NvimTreeApi then
                            pcall(require("nvim-tree.api").tree.close)
                        end
                    end,
                    open = function(name, path, prev_path)
                        -- Restore session for new workspace
                        vim.defer_fn(function()
                            if package.loaded["auto-session"] then
                                require("auto-session").RestoreSession()
                            end
                        end, 100)

                        vim.notify("Opened workspace: " .. name, vim.log.levels.INFO, {
                            title = "Workspaces",
                            icon = "",
                            timeout = 2500,
                        })
                    end,
                },
            })

            -- Telescope integration
            require("telescope").load_extension("workspaces")

            -- Keymaps
            vim.keymap.set("n", "<leader>ww", "<cmd>Telescope workspaces<cr>", { desc = "Find workspaces" })
            vim.keymap.set("n", "<leader>wa", function()
                local name = vim.fn.input("Workspace name: ", vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
                if name ~= "" then
                    require("workspaces").add(vim.fn.getcwd(), name)
                end
            end, { desc = "Add workspace" })
        end,
    },
}