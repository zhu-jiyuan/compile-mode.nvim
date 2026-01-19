---FZF-lua integration for command history and bookmarks

local history = require("compile-mode.history")
local bookmarks = require("compile-mode.bookmarks")

local M = {}

---Check if fzf-lua is available
---@return boolean
local function has_fzf_lua()
	return pcall(require, "fzf-lua")
end

---Pick and execute a command from history using fzf-lua
function M.pick_history()
	if not has_fzf_lua() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end

	local fzf = require("fzf-lua")
	local history_entries = history.get_sorted()

	if #history_entries == 0 then
		vim.notify("No command history available", vim.log.levels.INFO)
		return
	end

	local entries = {}
	for i, entry in ipairs(history_entries) do
		local label = string.format("[%3d] %s", entry.count, entry.command)
		if entry.directory then
			label = label .. string.format(" (in %s)", entry.directory)
		end
		table.insert(entries, label)
	end

	fzf.fzf_exec(entries, {
		prompt = "History> ",
		preview = function(selected)
			local idx = tonumber(selected[1]:match("%[%s*(%d+)%]"))
			if idx then
				for _, entry in ipairs(history_entries) do
					if entry.count == idx then
						return string.format(
							"Command: %s\nExecuted: %d times\nLast used: %s\nDirectory: %s",
							entry.command,
							entry.count,
							os.date("%Y-%m-%d %H:%M:%S", entry.last_used),
							entry.directory or "N/A"
						)
					end
				end
			end
			return ""
		end,
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local command = selected[1]:match("%]%s*(.-)%s*%(") or selected[1]:match("%]%s*(.+)")
					if command then
						local compile_mode = require("compile-mode")
						compile_mode.compile({ args = command })
					end
				end
			end,
			["ctrl-d"] = function(selected)
				if selected and #selected > 0 then
					local command = selected[1]:match("%]%s*(.-)%s*%(") or selected[1]:match("%]%s*(.+)")
					if command then
						history.remove(command)
						vim.notify("Removed from history: " .. command, vim.log.levels.INFO)
					end
				end
			end,
		},
	})
end

---Pick and execute a command from bookmarks using fzf-lua
function M.pick_bookmarks()
	if not has_fzf_lua() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end

	local fzf = require("fzf-lua")
	local bookmark_list = bookmarks.get_all()

	if #bookmark_list == 0 then
		vim.notify("No bookmarks available", vim.log.levels.INFO)
		return
	end

	local entries = {}
	for i, bookmark in ipairs(bookmark_list) do
		local label = string.format("[%s] %s: %s", bookmark.type, bookmark.name, bookmark.command)
		if bookmark.description then
			label = label .. string.format(" - %s", bookmark.description)
		end
		table.insert(entries, label)
	end

	fzf.fzf_exec(entries, {
		prompt = "Bookmarks> ",
		preview = function(selected)
			local name = selected[1]:match("%]%s*(.-):")
			if name then
				for _, bookmark in ipairs(bookmark_list) do
					if bookmark.name == name then
						return string.format(
							"Name: %s\nType: %s\nMatcher: %s\nCommand: %s\nDescription: %s",
							bookmark.name,
							bookmark.type,
							bookmark.matcher,
							bookmark.command,
							bookmark.description or "N/A"
						)
					end
				end
			end
			return ""
		end,
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local command = selected[1]:match(":%s*(.-)%s*%-") or selected[1]:match(":%s*(.+)")
					if command then
						local compile_mode = require("compile-mode")
						compile_mode.compile({ args = command })
					end
				end
			end,
			["ctrl-d"] = function(selected)
				if selected and #selected > 0 then
					local name = selected[1]:match("%]%s*(.-):")
					if name then
						bookmarks.remove(name)
						vim.notify("Removed bookmark: " .. name, vim.log.levels.INFO)
					end
				end
			end,
		},
	})
end

---Pick from both history and bookmarks
function M.pick_all()
	if not has_fzf_lua() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end

	local fzf = require("fzf-lua")
	local entries = {}

	-- Add history entries
	local history_entries = history.get_sorted()
	for _, entry in ipairs(history_entries) do
		local label = string.format("[HISTORY] [%3d] %s", entry.count, entry.command)
		if entry.directory then
			label = label .. string.format(" (in %s)", entry.directory)
		end
		table.insert(entries, label)
	end

	-- Add bookmark entries
	local bookmark_list = bookmarks.get_all()
	for _, bookmark in ipairs(bookmark_list) do
		local label = string.format("[BOOKMARK] [%s] %s: %s", bookmark.type, bookmark.name, bookmark.command)
		table.insert(entries, label)
	end

	if #entries == 0 then
		vim.notify("No history or bookmarks available", vim.log.levels.INFO)
		return
	end

	fzf.fzf_exec(entries, {
		prompt = "Commands> ",
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local line = selected[1]
					local command
					if line:match("^%[HISTORY%]") then
						command = line:match("%]%s*(.-)%s*%(") or line:match("%]%s*(.+)")
					else
						command = line:match(":%s*(.+)")
					end
					if command then
						local compile_mode = require("compile-mode")
						compile_mode.compile({ args = command })
					end
				end
			end,
		},
	})
end

return M
