---UI Manager for command history and bookmarks (neogit/oil style)
---@class CompileModeUIManager
local M = {}

local api = vim.api
local history = require("compile-mode.history")
local bookmarks = require("compile-mode.bookmarks")

---@type integer|nil
local manager_bufnr = nil

---@type integer|nil
local manager_winid = nil

---@type "history"|"bookmarks"
local current_view = "history"

---@type table<integer, CommandHistoryEntry|BookmarkEntry>
local line_to_entry = {}

---Create or get the manager buffer
---@return integer bufnr
local function get_or_create_buffer()
	if manager_bufnr and api.nvim_buf_is_valid(manager_bufnr) then
		return manager_bufnr
	end
	
	manager_bufnr = api.nvim_create_buf(false, true)
	api.nvim_buf_set_name(manager_bufnr, "compile-mode-manager")
	api.nvim_buf_set_option(manager_bufnr, "buftype", "nofile")
	api.nvim_buf_set_option(manager_bufnr, "bufhidden", "hide")
	api.nvim_buf_set_option(manager_bufnr, "swapfile", false)
	api.nvim_buf_set_option(manager_bufnr, "filetype", "compile-mode-manager")
	api.nvim_buf_set_option(manager_bufnr, "modifiable", false)
	
	setup_keymaps(manager_bufnr)
	
	return manager_bufnr
end

---Setup keymaps for the manager buffer
---@param bufnr integer
local function setup_keymaps(bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }
	
	-- Execute command under cursor
	vim.keymap.set("n", "<CR>", function()
		M.execute_current_line()
	end, opts)
	
	-- Toggle between history and bookmarks
	vim.keymap.set("n", "t", function()
		M.toggle_view()
	end, opts)
	
	-- Refresh view
	vim.keymap.set("n", "r", function()
		M.refresh()
	end, opts)
	
	-- Delete entry under cursor
	vim.keymap.set("n", "d", function()
		M.delete_current_line()
	end, opts)
	
	-- Add bookmark from history (only in history view)
	vim.keymap.set("n", "b", function()
		M.bookmark_current_line()
	end, opts)
	
	-- Close manager
	vim.keymap.set("n", "q", function()
		M.close()
	end, opts)
	
	-- Help
	vim.keymap.set("n", "?", function()
		M.show_help()
	end, opts)
end

---Render the history view
---@return string[] lines
---@return table<integer, CommandHistoryEntry> mapping
local function render_history()
	local lines = {
		"# Command History (sorted by frequency)",
		"# Press <CR> to execute, 't' to toggle view, 'b' to bookmark, 'd' to delete, 'r' to refresh, 'q' to close",
		"",
	}
	local mapping = {}
	
	local entries = history.get_sorted()
	
	if #entries == 0 then
		table.insert(lines, "No commands in history")
		return lines, mapping
	end
	
	for _, entry in ipairs(entries) do
		local line_num = #lines + 1
		mapping[line_num] = entry
		
		local info = string.format("[%dx]", entry.frequency)
		if entry.filetype then
			info = info .. string.format(" [%s]", entry.filetype)
		end
		if entry.project then
			local project_name = vim.fn.fnamemodify(entry.project, ":t")
			info = info .. string.format(" [%s]", project_name)
		end
		
		table.insert(lines, string.format("%s %s", info, entry.command))
	end
	
	return lines, mapping
end

---Render the bookmarks view
---@return string[] lines
---@return table<integer, BookmarkEntry> mapping
local function render_bookmarks()
	local lines = {
		"# Bookmarks",
		"# Press <CR> to execute, 't' to toggle view, 'd' to delete, 'r' to refresh, 'q' to close",
		"",
	}
	local mapping = {}
	
	local entries = bookmarks.get_all()
	
	if #entries == 0 then
		table.insert(lines, "No bookmarks defined")
		return lines, mapping
	end
	
	for _, entry in ipairs(entries) do
		local line_num = #lines + 1
		mapping[line_num] = entry
		
		local info = string.format("[%s]", entry.name)
		if entry.filetype then
			local ft = type(entry.filetype) == "table" and table.concat(entry.filetype, ",") or entry.filetype
			info = info .. string.format(" [%s]", ft)
		end
		if entry.project then
			info = info .. string.format(" [%s]", entry.project)
		end
		
		local desc = entry.description and string.format(" # %s", entry.description) or ""
		table.insert(lines, string.format("%s %s%s", info, entry.command, desc))
	end
	
	return lines, mapping
end

---Refresh the buffer content
function M.refresh()
	local bufnr = get_or_create_buffer()
	
	local lines, mapping
	if current_view == "history" then
		lines, mapping = render_history()
	else
		lines, mapping = render_bookmarks()
	end
	
	line_to_entry = mapping
	
	-- Update buffer
	api.nvim_buf_set_option(bufnr, "modifiable", true)
	api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	api.nvim_buf_set_option(bufnr, "modifiable", false)
	
	-- Apply syntax highlighting
	apply_highlights(bufnr)
end

---Apply syntax highlighting to the buffer
---@param bufnr integer
local function apply_highlights(bufnr)
	local ns_id = api.nvim_create_namespace("compile_mode_manager")
	api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	
	local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		if line:match("^#") then
			api.nvim_buf_add_highlight(bufnr, ns_id, "Comment", i - 1, 0, -1)
		elseif line:match("^%[") then
			-- Highlight the info part
			local info_end = line:find("%]") or 0
			api.nvim_buf_add_highlight(bufnr, ns_id, "Special", i - 1, 0, info_end)
		end
	end
end

---Toggle between history and bookmarks view
function M.toggle_view()
	current_view = current_view == "history" and "bookmarks" or "history"
	M.refresh()
end

---Execute the command on the current line
function M.execute_current_line()
	local line_num = api.nvim_win_get_cursor(0)[1]
	local entry = line_to_entry[line_num]
	
	if not entry then
		vim.notify("No command on this line", vim.log.levels.WARN)
		return
	end
	
	local command = entry.command
	if not command then
		vim.notify("Invalid entry", vim.log.levels.ERROR)
		return
	end
	
	-- Close the manager window
	M.close()
	
	-- Execute the command
	vim.schedule(function()
		local compile_mode = require("compile-mode")
		compile_mode.compile({ args = command })
	end)
end

---Delete the entry on the current line
function M.delete_current_line()
	local line_num = api.nvim_win_get_cursor(0)[1]
	local entry = line_to_entry[line_num]
	
	if not entry then
		vim.notify("No entry on this line", vim.log.levels.WARN)
		return
	end
	
	if current_view == "history" then
		---@cast entry CommandHistoryEntry
		history.remove(entry.command)
		vim.notify("Removed from history", vim.log.levels.INFO)
	else
		---@cast entry BookmarkEntry
		bookmarks.remove(entry.name)
		vim.notify("Removed bookmark: " .. entry.name, vim.log.levels.INFO)
	end
	
	M.refresh()
end

---Bookmark the command on the current line (only works in history view)
function M.bookmark_current_line()
	if current_view ~= "history" then
		vim.notify("Bookmarking only works in history view", vim.log.levels.WARN)
		return
	end
	
	local line_num = api.nvim_win_get_cursor(0)[1]
	local entry = line_to_entry[line_num]
	
	if not entry then
		vim.notify("No command on this line", vim.log.levels.WARN)
		return
	end
	
	---@cast entry CommandHistoryEntry
	local input = require("compile-mode.input")
	input.input({
		prompt = "Bookmark name",
		default = "",
		on_submit = function(name)
			if not name or name == "" then
				return
			end
			
			bookmarks.add({
				name = name,
				command = entry.command,
				filetype = entry.filetype,
				project = entry.project,
			})
			vim.notify("Bookmarked: " .. name, vim.log.levels.INFO)
		end,
	})
end

---Show help message
function M.show_help()
	local help = {
		"Compile Mode Manager Help",
		"",
		"Keybindings:",
		"  <CR>  - Execute command under cursor",
		"  t     - Toggle between history and bookmarks",
		"  r     - Refresh view",
		"  d     - Delete entry under cursor",
		"  b     - Bookmark current command (history view only)",
		"  q     - Close manager",
		"  ?     - Show this help",
	}
	
	vim.notify(table.concat(help, "\n"), vim.log.levels.INFO)
end

---Open the manager window
---@param opts? {view?: "history"|"bookmarks"}
function M.open(opts)
	opts = opts or {}
	
	if opts.view then
		current_view = opts.view
	end
	
	local bufnr = get_or_create_buffer()
	M.refresh()
	
	-- Create or focus window
	if manager_winid and api.nvim_win_is_valid(manager_winid) then
		api.nvim_set_current_win(manager_winid)
		return
	end
	
	-- Create a new split window
	vim.cmd("botright vsplit")
	manager_winid = api.nvim_get_current_win()
	api.nvim_win_set_buf(manager_winid, bufnr)
	api.nvim_win_set_width(manager_winid, 80)
	
	-- Set window options
	api.nvim_win_set_option(manager_winid, "number", false)
	api.nvim_win_set_option(manager_winid, "relativenumber", false)
	api.nvim_win_set_option(manager_winid, "cursorline", true)
	api.nvim_win_set_option(manager_winid, "wrap", false)
end

---Close the manager window
function M.close()
	if manager_winid and api.nvim_win_is_valid(manager_winid) then
		api.nvim_win_close(manager_winid, true)
		manager_winid = nil
	end
end

return M
