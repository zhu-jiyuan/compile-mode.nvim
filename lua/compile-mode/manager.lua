---Interactive buffer for managing history and bookmarks
---Similar to neogit or oil.nvim

local history = require("compile-mode.history")
local bookmarks = require("compile-mode.bookmarks")

local M = {}

---@type integer? Buffer number for the management UI
local buf = nil

---@type integer? Window ID for the management UI
local win = nil

---@type "history"|"bookmarks" Current view mode
local current_mode = "history"

---Open the management buffer
function M.open()
	-- Create or reuse buffer
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(buf, "compile-mode://manager")
	end

	-- Open in a split or reuse existing window
	if not win or not vim.api.nvim_win_is_valid(win) then
		vim.cmd("botright 20split")
		win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, buf)
	else
		vim.api.nvim_set_current_win(win)
	end

	-- Setup buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "compile-mode-manager")

	-- Setup keymaps
	M._setup_keymaps()

	-- Render initial content
	M.render()
end

---Close the management buffer
function M.close()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	win = nil
end

---Toggle the management buffer
function M.toggle()
	if win and vim.api.nvim_win_is_valid(win) then
		M.close()
	else
		M.open()
	end
end

---Switch between history and bookmarks view
function M.toggle_mode()
	if current_mode == "history" then
		current_mode = "bookmarks"
	else
		current_mode = "history"
	end
	M.render()
end

---Render the buffer content
function M.render()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = {}
	local highlights = {}

	if current_mode == "history" then
		table.insert(lines, "# Command History (sorted by frequency)")
		table.insert(lines, "# Press <Tab> to switch to bookmarks, <CR> to execute, d to delete")
		table.insert(lines, "")

		local history_entries = history.get_sorted()
		for i, entry in ipairs(history_entries) do
			local line = string.format("[%3d] %s", entry.count, entry.command)
			if entry.directory then
				line = line .. string.format(" (in %s)", entry.directory)
			end
			table.insert(lines, line)

			-- Store entry index for later retrieval
			table.insert(highlights, {
				line = #lines,
				entry = entry,
				type = "history",
			})
		end
	else
		table.insert(lines, "# Bookmarks")
		table.insert(lines, "# Press <Tab> to switch to history, <CR> to execute, d to delete")
		table.insert(lines, "")

		local bookmark_list = bookmarks.get_all()
		for i, bookmark in ipairs(bookmark_list) do
			local line = string.format("[%s] %s: %s", bookmark.type, bookmark.name, bookmark.command)
			if bookmark.description then
				line = line .. string.format(" - %s", bookmark.description)
			end
			table.insert(lines, line)

			table.insert(highlights, {
				line = #lines,
				entry = bookmark,
				type = "bookmark",
			})
		end
	end

	-- Update buffer content
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Store highlights data in buffer variable for keymaps to use
	vim.b[buf].compile_mode_entries = highlights
end

---Setup buffer keymaps
function M._setup_keymaps()
	if not buf then
		return
	end

	local opts = { buffer = buf, noremap = true, silent = true }

	-- Execute command under cursor
	vim.keymap.set("n", "<CR>", function()
		M._execute_current()
	end, opts)

	-- Delete entry under cursor
	vim.keymap.set("n", "d", function()
		M._delete_current()
	end, opts)

	-- Toggle between history and bookmarks
	vim.keymap.set("n", "<Tab>", function()
		M.toggle_mode()
	end, opts)

	-- Close buffer
	vim.keymap.set("n", "q", function()
		M.close()
	end, opts)

	-- Refresh
	vim.keymap.set("n", "r", function()
		M.render()
	end, opts)
end

---Execute the command under cursor
function M._execute_current()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local entries = vim.b[buf].compile_mode_entries

	if not entries then
		return
	end

	for _, item in ipairs(entries) do
		if item.line == line_num then
			local command = item.entry.command
			M.close()
			-- Execute the command using compile-mode
			local compile_mode = require("compile-mode")
			compile_mode.compile({ args = command })
			return
		end
	end
end

---Delete the entry under cursor
function M._delete_current()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local entries = vim.b[buf].compile_mode_entries

	if not entries then
		return
	end

	for _, item in ipairs(entries) do
		if item.line == line_num then
			if item.type == "history" then
				history.remove(item.entry.command)
				M.render()
			elseif item.type == "bookmark" then
				bookmarks.remove(item.entry.name)
				M.render()
			end
			return
		end
	end
end

return M
