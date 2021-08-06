local api = vim.api
local luv = vim.loop

local utils = require("nvim-tree.utils")
local events = require("nvim-tree.events")
local lib = require'nvim-tree.lib'
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

local function rename_loaded_buffers(old_name, new_name)
    for _, buf in pairs(api.nvim_list_bufs()) do
      if api.nvim_buf_is_loaded(buf) then
        if api.nvim_buf_get_name(buf) == old_name then
          api.nvim_buf_set_name(buf, new_name)
          -- to avoid the 'overwrite existing file' error message on write
          vim.api.nvim_buf_call(buf, function() vim.cmd("silent! w!") end)
        end
      end
    end
end

local function do_cut(source, destination)
  local success = luv.fs_rename(source, destination)
  if not success then
    return success
  end
  rename_loaded_buffers(source, destination)
  return true
end

local function do_copy(source, destination)
  local source_stats = luv.fs_stat(source)

  if source_stats and source_stats.type == 'file' then
    return luv.fs_copyfile(source, destination)
  end

  local handle = luv.fs_scandir(source)

  if type(handle) == 'string' then
    return false, handle
  end

  luv.fs_mkdir(destination, source_stats.mode)

  while true do
    local name, _ = luv.fs_scandir_next(handle)
    if not name then break end

    local new_name = utils.path_join({source, name})
    local new_destination = utils.path_join({destination, name})
    local success, msg = do_copy(new_name, new_destination)
    if not success then return success, msg end
  end

  return true
end

local function do_single_paste(source, dest, action_type, action_fn)
  local dest_stats = luv.fs_stat(dest)
  local should_process = true
  local should_rename = false

  if dest_stats then
		utils.clear_prompt()
    print(dest..' already exists. Overwrite? y/n/r(ename)')
    local ans = utils.get_user_input_char()
    utils.clear_prompt()
    should_process = ans:match('^y')
    should_rename = ans:match('^r')
  end

  if should_rename then
    local new_dest = vim.fn.input('New name: ', dest)
    return do_single_paste(source, new_dest, action_type, action_fn)
  end

  if should_process then
    local success, errmsg = action_fn(source, dest)
    if not success then
      api.nvim_err_writeln('Could not '..action_type..' '..source..' - '..errmsg)
    end
  end
end

local function do_paste(node, nodes, action_type, action_fn)
  node = lib.get_last_group_node(node)
  if node.name == '..' then return end

  local destination = node.absolute_path
  local stats = luv.fs_stat(destination)
  local is_dir = stats and stats.type == 'directory'

  if not is_dir then
    destination = vim.fn.fnamemodify(destination, ':p:h')
  elseif not node.open then
    destination = vim.fn.fnamemodify(destination, ':p:h:h')
  end

  for _, entry in ipairs(nodes) do
    local dest = utils.path_join({destination, entry.name })
    do_single_paste(entry.absolute_path, dest, action_type, action_fn)
  end
end

function M.delete(nodes)
	-- TODO: unify_ancestors
	for _, node in ipairs(nodes) do
		remove(node)
	end
end

function M.copy(node, nodes)
	-- TODO: unify_ancestors
  do_paste(node, nodes, "copy", do_copy)
end

function M.cut(node, nodes)
	-- TODO: unify_ancestors
  do_paste(node, nodes, "copy", do_cut)
end

return M
