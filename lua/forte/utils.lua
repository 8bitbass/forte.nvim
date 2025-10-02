local M = {}

function M.ensure_fsharp_extension(name)
    if name:match("%.fs[ix]?$") then
        return name
    else
        return name .. ".fs"
    end
end

function M.to_module_name(filename)
    local moduleName = filename:gsub("%.fs[ix]?$", ""):gsub("[^%w_]", "")
    return moduleName
end

return M


