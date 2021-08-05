local lib = require'nvim-tree.lib'
local pops = require'nvim-tree.populate'
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
  delete = function(currentNode)
    local nodes = state.get_selected_nodes()

    if next(nodes) == nil then
      -- If select nothing then delete the current node
      fs.remove(currentNode)
      return
    end

    for _, node in ipairs(nodes) do
      fs.remove(node)
    end

    state.clear_selections()
  end,
  toggle_hidden = function()
    pops.show_ignored = not pops.show_ignored
    pops.show_dotfiles = not pops.show_dotfiles

    lib.refresh_tree()
  end,
}

return M
