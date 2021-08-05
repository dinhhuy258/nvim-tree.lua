local lib = require("nvim-tree.lib")
local pops = require("nvim-tree.populate")
local state = require("nvim-tree.state")
local utils = require("nvim-tree.utils")
local fs = require("nvim-tree.fs")
local fs_custom = require("nvim-tree.fs-custom")

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

		print("Remove selected nodes ? y/n")
		local ans = utils.get_user_input_char()
		utils.clear_prompt()

		if ans:match("^y") then
			fs_custom.batch_delete(nodes)
			lib.refresh_tree()
			state.clear_selections()
		end
	end,
	toggle_hidden = function()
		pops.show_ignored = not pops.show_ignored
		pops.show_dotfiles = not pops.show_dotfiles

		lib.refresh_tree()
	end,
}

return M
