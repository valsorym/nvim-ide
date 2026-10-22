-- Filter exact directory components in rg, including nested environments.
local M = {}
local excluded = { "node_modules", "__pycache__", ".venv", "venv" }
local function flags(ignored)
    local args = { "--hidden", "--glob", "!.git/**" }
    if ignored then args[#args + 1] = "--no-ignore"
    else
        for _, directory in ipairs(excluded) do
            vim.list_extend(args, { "--glob", "!**/" .. directory .. "/**" })
        end
    end
    return args
end
function M.grep_args(ignored)
    return vim.list_extend({ "rg", "--color=never", "--no-heading", "--with-filename",
        "--line-number", "--column", "--smart-case" }, flags(ignored))
end
function M.file_args() return vim.list_extend({ "rg", "--files" }, flags(false)) end
return M
