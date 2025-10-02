local Path = require("forte.path")
local Utils = require("forte.utils")

local function find_fsproj_and_virtual_path()
    local file_path = Path.normalize(vim.fn.expand("%:p"))

    -- Walk up to find .fsproj
    local dir = vim.fn.fnamemodify(file_path, ":h")
    local fsproj_path
    while dir and dir ~= "" do
        local matches = vim.fn.globpath(dir, "*.fsproj", false, true)
        if #matches > 0 then
            fsproj_path = Path.normalize(matches[1])
            break
        end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            break
        end
        dir = parent
    end

    if not fsproj_path then
        return nil, nil
    end

    local fsproj_dir = Path.normalize(vim.fn.fnamemodify(fsproj_path, ":p:h"))
    local virtual_path = Path.relative_to(fsproj_dir, file_path)

    return fsproj_path, virtual_path
end

local function add_file_above()
    local fsproj, virtual_path = find_fsproj_and_virtual_path()
    if not fsproj then
        vim.notify("No .fsproj file found starting from current file", vim.log.levels.ERROR)
        return
    end

    local fsproj_dir = Path.normalize(vim.fn.fnamemodify(fsproj, ":p:h"))

    vim.ui.input({ prompt = "New file name (relative to project): " }, function(input)
        if not input or input == "" then
            return
        end

        local safe_input = Utils.ensure_fsharp_extension(input)

        local params = {
            FsProj = fsproj,
            FileVirtualPath = virtual_path,
            NewFile = safe_input,
        }

        vim.lsp.buf_request(0, "fsproj/addFileAbove", params, function(err, _, _, _)
            if err then
                vim.notify("Error calling addFileAbove: " .. err.message, vim.log.levels.ERROR)
                return
            end

            --  Build absolute path to the new file
            local new_file_path = Path.join(fsproj_dir, safe_input)
            new_file_path = Path.normalize(new_file_path)
            local moduleName = Utils.to_module_name(safe_input)

            -- If file does not exist or is empty, write initial module declaration
            local file_exists = vim.fn.filereadable(new_file_path) == 1
            local lines = file_exists and vim.fn.readfile(new_file_path) or {}

            if #lines == 0 then
                vim.fn.writefile({ "module " .. moduleName }, new_file_path)
            end

            --  Open the new file
            vim.cmd("edit " .. vim.fn.fnameescape(new_file_path))

            vim.notify("Added and opened file: " .. new_file_path, vim.log.levels.INFO)
        end)
    end)
end

local M = {}

M.setup = function(cfg)
    vim.api.nvim_create_autocmd("LspAttach", {

        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client.name ~= "fsautocomplete" then
                return
            end

            vim.api.nvim_create_user_command("FSharpAddFileAbove", add_file_above, {})
        end,
    })
end

return M
