-- Inspect configured swap directories without loading buffers or triggering read hooks.
local M = {}
local function normalize(path)
    path = vim.fn.fnamemodify(path, ":p")
    return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

function M.guard()
    local directories = {}
    local pid, host = vim.fn.getpid(), vim.uv.os_gethostname()
    return function(path)
        local target = normalize(path)
        local basename = vim.fs.basename(path)
        local encoded = path:gsub("[/\\:]", "%%")
        for _, option in ipairs(vim.opt.directory:get()) do
            if option ~= "" then
                local directory = option
                if option == "." then directory = vim.fs.dirname(path)
                elseif option:match("^%.[/\\]") then directory = vim.fs.dirname(path) .. option:sub(2) end
                directory = normalize(directory)
                if not directories[directory] then
                    local swaps = {}
                    local scan = vim.uv.fs_scandir(directory)
                    while scan do
                        local name = vim.uv.fs_scandir_next(scan)
                        if not name then break end
                        if name:match("%.s%l%l$") then
                            local swap = directory .. "/" .. name
                            local ok, info = pcall(vim.fn.swapinfo, swap)
                            if ok and type(info) == "table" then
                                if info.error then
                                    swaps[#swaps + 1] = { name = name, path = swap }
                                elseif info.pid ~= pid or info.host ~= host then
                                    swaps[#swaps + 1] = { target = normalize(info.fname), path = swap }
                                end
                            end
                        end
                    end
                    directories[directory] = swaps
                end
                for _, swap in ipairs(directories[directory]) do
                    if swap.target == target then return swap.path end
                    if swap.name then
                        local base = swap.name:sub(1, -5)
                        if base == encoded or base == basename or base == "." .. basename then return swap.path end
                    end
                end
            end
        end
    end
end

return M
