local M = {}

local clipboard = {
  selections = {}
}

function M.toggle_selection(node)
  if node.name == '..' then return end

  for idx, entry in ipairs(clipboard.selections) do
    if entry.absolute_path == node.absolute_path then
      table.remove(clipboard.selections, idx)
      return
    end
  end

  table.insert(clipboard.selections, node)
end

function M.is_selected(node)
  for _, entry in ipairs(clipboard.selections) do
    if entry.absolute_path == node.absolute_path then
      return true
    end
  end

  return false
end

function M.clear_selections()
  for idx, _ in ipairs(clipboard.selections) do
    clipboard.selections[idx] = nil
  end
end

function M.get_selected_nodes()
  return clipboard.selections
end

return  M

