local lib = require'nvim-tree.lib'
local state = require'nvim-tree.state'
local fs = require'nvim-tree.fs'

local M = {}

M.keypress_funcs = {
  toggle_selection = function(node)
    state.toggle_selection(node)
    lib.redraw()
  end,
  clear_selections = function()
    state.clear_selections()
    lib.redraw()
  end,
  batch_delete = function()
    local nodes = state.get_selected_nodes()
    for _, node in ipairs(nodes) do
      fs.remove(node)
    end

    state.clear_selections()
  end
}

return M
