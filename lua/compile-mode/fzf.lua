---fzf-lua integration for compile-mode
---@class CompileModeFzf
local M = {}

local history = require("compile-mode.history")
local bookmarks = require("compile-mode.bookmarks")

---Check if fzf-lua is available
---@return boolean
local function is_fzf_available()
	local ok = pcall(require, "fzf-lua")
	return ok
end

---Execute a command using compile-mode
---@param command string
local function execute_command(command)
	local compile_mode = require("compile-mode")
	compile_mode.compile({ args = command })
end

---Show command history picker
---@param opts? {project?: string, filetype?: string}
function M.history_picker(opts)
	if not is_fzf_available() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end
	
	local fzf = require("fzf-lua")
	opts = opts or {}
	
	local entries = history.get_sorted(opts)
	
	if #entries == 0 then
		vim.notify("No commands in history", vim.log.levels.WARN)
		return
	end
	
	-- Format entries for fzf
	local formatted_entries = {}
	for _, entry in ipairs(entries) do
		local info = string.format("[%dx]", entry.frequency)
		if entry.filetype then
			info = info .. string.format(" [%s]", entry.filetype)
		end
		if entry.project then
			local project_name = vim.fn.fnamemodify(entry.project, ":t")
			info = info .. string.format(" [%s]", project_name)
		end
		
		table.insert(formatted_entries, string.format("%s %s", info, entry.command))
	end
	
	fzf.fzf_exec(formatted_entries, {
		prompt = "Command History> ",
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					return
				end
				
				-- Extract command from the formatted string
				local line = selected[1]
				local command = line:match("%]%s+(.+)$")
				if not command then
					command = line:match("%s+(.+)$")
				end
				
				if command then
					execute_command(command)
				end
			end,
			["ctrl-d"] = function(selected)
				if not selected or #selected == 0 then
					return
				end
				
				-- Extract command and delete from history
				local line = selected[1]
				local command = line:match("%]%s+(.+)$")
				if not command then
					command = line:match("%s+(.+)$")
				end
				
				if command then
					history.remove(command)
					vim.notify("Removed from history", vim.log.levels.INFO)
				end
			end,
		},
		previewer = false,
		winopts = {
			height = 0.6,
			width = 0.8,
		},
	})
end

---Show bookmarks picker
---@param opts? {project?: string, filetype?: string}
function M.bookmarks_picker(opts)
	if not is_fzf_available() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end
	
	local fzf = require("fzf-lua")
	opts = opts or {}
	
	local entries = bookmarks.get_all(opts)
	
	if #entries == 0 then
		vim.notify("No bookmarks defined", vim.log.levels.WARN)
		return
	end
	
	-- Format entries for fzf
	local formatted_entries = {}
	for _, entry in ipairs(entries) do
		local info = string.format("[%s]", entry.name)
		if entry.filetype then
			local ft = type(entry.filetype) == "table" and table.concat(entry.filetype, ",") or entry.filetype
			info = info .. string.format(" [%s]", ft)
		end
		if entry.project then
			info = info .. string.format(" [%s]", entry.project)
		end
		
		local desc = entry.description and string.format(" # %s", entry.description) or ""
		table.insert(formatted_entries, string.format("%s %s%s", info, entry.command, desc))
	end
	
	fzf.fzf_exec(formatted_entries, {
		prompt = "Bookmarks> ",
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					return
				end
				
				-- Extract command from the formatted string
				local line = selected[1]
				local command = line:match("%]%s+([^#]+)")
				if command then
					command = vim.trim(command)
					execute_command(command)
				end
			end,
			["ctrl-d"] = function(selected)
				if not selected or #selected == 0 then
					return
				end
				
				-- Extract bookmark name and delete
				local line = selected[1]
				local name = line:match("^%[([^%]]+)%]")
				
				if name then
					bookmarks.remove(name)
					vim.notify("Removed bookmark: " .. name, vim.log.levels.INFO)
				end
			end,
		},
		previewer = false,
		winopts = {
			height = 0.6,
			width = 0.8,
		},
	})
end

---Show recent commands picker (last N commands)
---@param limit? integer Number of recent commands to show (default 20)
function M.recent_picker(limit)
	if not is_fzf_available() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end
	
	local fzf = require("fzf-lua")
	limit = limit or 20
	
	local entries = history.get_recent(limit)
	
	if #entries == 0 then
		vim.notify("No recent commands", vim.log.levels.WARN)
		return
	end
	
	-- Format entries for fzf
	local formatted_entries = {}
	for _, entry in ipairs(entries) do
		local time_str = os.date("%Y-%m-%d %H:%M", entry.last_run)
		table.insert(formatted_entries, string.format("[%s] %s", time_str, entry.command))
	end
	
	fzf.fzf_exec(formatted_entries, {
		prompt = "Recent Commands> ",
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					return
				end
				
				-- Extract command from the formatted string
				local line = selected[1]
				local command = line:match("%]%s+(.+)$")
				
				if command then
					execute_command(command)
				end
			end,
		},
		previewer = false,
		winopts = {
			height = 0.6,
			width = 0.8,
		},
	})
end

---Show combined picker (history + bookmarks)
function M.combined_picker()
	if not is_fzf_available() then
		vim.notify("fzf-lua is not installed", vim.log.levels.ERROR)
		return
	end
	
	local fzf = require("fzf-lua")
	
	local history_entries = history.get_sorted()
	local bookmark_entries = bookmarks.get_all()
	
	if #history_entries == 0 and #bookmark_entries == 0 then
		vim.notify("No commands or bookmarks available", vim.log.levels.WARN)
		return
	end
	
	-- Format entries for fzf
	local formatted_entries = {}
	
	-- Add bookmarks first
	for _, entry in ipairs(bookmark_entries) do
		local info = string.format("[BOOKMARK: %s]", entry.name)
		table.insert(formatted_entries, string.format("%s %s", info, entry.command))
	end
	
	-- Add history entries
	for _, entry in ipairs(history_entries) do
		local info = string.format("[HISTORY: %dx]", entry.frequency)
		table.insert(formatted_entries, string.format("%s %s", info, entry.command))
	end
	
	fzf.fzf_exec(formatted_entries, {
		prompt = "Commands & Bookmarks> ",
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					return
				end
				
				-- Extract command from the formatted string
				local line = selected[1]
				local command = line:match("%]%s+(.+)$")
				
				if command then
					execute_command(command)
				end
			end,
		},
		previewer = false,
		winopts = {
			height = 0.6,
			width = 0.8,
		},
	})
end

return M
