---Command history management module
---Tracks command execution frequency and provides history functionality

local M = {}

---@class HistoryEntry
---@field command string The command string
---@field count integer Number of times executed
---@field last_used integer Timestamp of last execution
---@field directory string? The directory where command was run

---@type HistoryEntry[]
local history = {}

---@type table<string, integer> Map of command to index in history
local command_index = {}

local config = nil

---Initialize the history module with config
---@param opts table Configuration options
function M.setup(opts)
	config = opts or {}
	config.max_history = config.max_history or 100
	M.load()
end

---Add a command to history or increment its count
---@param command string The command to add
---@param directory string? The directory where command was run
function M.add(command, directory)
	if not command or command == "" then
		return
	end

	local idx = command_index[command]
	local now = os.time()

	if idx then
		-- Command exists, increment count
		history[idx].count = history[idx].count + 1
		history[idx].last_used = now
		history[idx].directory = directory
	else
		-- New command
		local entry = {
			command = command,
			count = 1,
			last_used = now,
			directory = directory,
		}
		table.insert(history, entry)
		command_index[command] = #history
	end

	-- Enforce max history limit
	if config and config.max_history and #history > config.max_history then
		M._trim_history()
	end

	M.save()
end

---Get all history entries sorted by frequency (descending)
---@return HistoryEntry[]
function M.get_sorted()
	local sorted = vim.deepcopy(history)
	table.sort(sorted, function(a, b)
		if a.count == b.count then
			return a.last_used > b.last_used
		end
		return a.count > b.count
	end)
	return sorted
end

---Get all history entries
---@return HistoryEntry[]
function M.get_all()
	return vim.deepcopy(history)
end

---Clear all history
function M.clear()
	history = {}
	command_index = {}
	M.save()
end

---Remove a command from history
---@param command string The command to remove
---@return boolean success
function M.remove(command)
	local idx = command_index[command]
	if not idx then
		return false
	end

	table.remove(history, idx)
	command_index[command] = nil

	-- Rebuild index
	for i = idx, #history do
		command_index[history[i].command] = i
	end

	M.save()
	return true
end

---Remove least recently used entries when exceeding max_history
function M._trim_history()
	if not config or not config.max_history then
		return
	end

	-- Sort by last_used ascending (oldest first)
	local sorted_indices = {}
	for i = 1, #history do
		table.insert(sorted_indices, i)
	end
	table.sort(sorted_indices, function(a, b)
		return history[a].last_used < history[b].last_used
	end)

	-- Remove oldest entries
	local to_remove = #history - config.max_history
	for i = 1, to_remove do
		local idx = sorted_indices[i]
		command_index[history[idx].command] = nil
	end

	-- Rebuild history and index
	local new_history = {}
	for i = to_remove + 1, #history do
		local idx = sorted_indices[i]
		table.insert(new_history, history[idx])
	end

	history = new_history
	command_index = {}
	for i, entry in ipairs(history) do
		command_index[entry.command] = i
	end
end

---Get the history file path
---@return string
local function get_history_file()
	local data_path = vim.fn.stdpath("data")
	return data_path .. "/compile-mode-history.json"
end

---Save history to disk
function M.save()
	local file = get_history_file()
	local data = vim.json.encode(history)
	local f = io.open(file, "w")
	if f then
		f:write(data)
		f:close()
	end
end

---Load history from disk
function M.load()
	local file = get_history_file()
	local f = io.open(file, "r")
	if f then
		local data = f:read("*all")
		f:close()
		local ok, decoded = pcall(vim.json.decode, data)
		if ok and decoded then
			history = decoded
			-- Rebuild command index
			command_index = {}
			for i, entry in ipairs(history) do
				command_index[entry.command] = i
			end
		end
	end
end

return M
