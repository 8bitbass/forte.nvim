local Path = {}

-- Normalize using Neovim's built-in function
function Path.normalize(p)
  return vim.fs.normalize(p)
end

-- Join path segments
function Path.join(...)
  return table.concat({ ... }, "/")
end

-- Compute path of `target` relative to `base`
function Path.relative_to(base, target)
  base = Path.normalize(base)
  target = Path.normalize(target)

  if base:sub(-1) ~= "/" then
    base = base .. "/"
  end

  if target:sub(1, #base) == base then
    local rel = target:sub(#base + 1 - 1)  -- strip base prefix
    return rel:gsub("^/", "")  -- strip leading slash
  end

  -- fallback: manual diff
  local base_parts, target_parts = {}, {}
  for part in base:gmatch("[^/]+") do table.insert(base_parts, part) end
  for part in target:gmatch("[^/]+") do table.insert(target_parts, part) end

  while #base_parts > 0 and #target_parts > 0 and base_parts[1] == target_parts[1] do
    table.remove(base_parts, 1)
    table.remove(target_parts, 1)
  end

  local rel_parts = {}
  for _ = 1, #base_parts do table.insert(rel_parts, "..") end
  for _, part in ipairs(target_parts) do table.insert(rel_parts, part) end

  return table.concat(rel_parts, "/")
end

return Path


