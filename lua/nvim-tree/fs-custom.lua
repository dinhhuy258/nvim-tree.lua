local api = vim.api
local luv = vim.loop

local utils = require("nvim-tree.utils")
local events = require("nvim-tree.events")
local M = {}

local function clear_buffer(absolute_path)
	for _, buf in pairs(api.nvim_list_bufs()) do
		if vim.fn.bufloaded(buf) == 1 and api.nvim_buf_get_name(buf) == absolute_path then
			api.nvim_command(":bd! " .. buf)
		end
	end
end

local function remove_dir(cwd)
	local handle = luv.fs_scandir(cwd)
	if type(handle) == "string" then
		return api.nvim_err_writeln(handle)
	end

	while true do
		local name, t = luv.fs_scandir_next(handle)
		if not name then
			break
		end

		local new_cwd = utils.path_join({ cwd, name })
		if t == "directory" then
			local success = remove_dir(new_cwd)
			if not success then
				return false
			end
		else
			local success = luv.fs_unlink(new_cwd)
			if not success then
				return false
			end
			clear_buffer(new_cwd)
		end
	end

	return luv.fs_rmdir(cwd)
end

local function remove(node)
	if node.entries ~= nil then
		local success = remove_dir(node.absolute_path)
		if not success then
			return api.nvim_err_writeln("Could not remove " .. node.name)
		end
		events._dispatch_folder_removed(node.absolute_path)
	else
		local success = luv.fs_unlink(node.absolute_path)
		if not success then
			return api.nvim_err_writeln("Could not remove " .. node.name)
		end
		events._dispatch_file_removed(node.absolute_path)
		clear_buffer(node.absolute_path)
	end
end

function M.batch_delete(nodes)
	-- TODO: unify_ancestors
	for _, node in ipairs(nodes) do
		remove(node)
	end
end

return M
