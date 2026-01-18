---@class CommandHistoryEntry
---@field command string The command text
---@field frequency integer Number of times the command has been run
---@field last_run integer Timestamp of last run (os.time())
---@field project string|nil Project root where command was run
---@field filetype string|nil File type when command was run

---@class CompileModeHistory
local M = {}

local config = nil
local history_file = vim.fn.stdpath("data") .. "/compile-mode-history.json"

---@type table<string, CommandHistoryEntry>
local history = {}

---Load configuration
local function load_config()
	if not config then
		config = require("compile-mode.config.internal")
	end
	return config
end

---Get the maximum history size from config
---@return integer
local function get_max_history_size()
	local cfg = load_config()
	return cfg.max_history_size or 100
end

---Load history from file
local function load_history()
	local file = io.open(history_file, "r")
	if not file then
		return {}
	end
	
	local content = file:read("*all")
	file:close()
	
	if content == "" then
		return {}
	end
	
	local ok, decoded = pcall(vim.json.decode, content)
	if not ok then
		vim.notify("Failed to load command history: " .. decoded, vim.log.levels.WARN)
		return {}
	end
	
	return decoded or {}
end

---Save history to file
local function save_history()
	-- Ensure directory exists
	local data_dir = vim.fn.stdpath("data")
	vim.fn.mkdir(data_dir, "p")
	
	local file = io.open(history_file, "w")
	if not file then
		vim.notify("Failed to save command history", vim.log.levels.ERROR)
		return
	end
	
	local ok, encoded = pcall(vim.json.encode, history)
	if not ok then
		vim.notify("Failed to encode command history: " .. encoded, vim.log.levels.ERROR)
		file:close()
		return
	end
	
	file:write(encoded)
	file:close()
end

---Initialize history system
function M.setup()
	history = load_history()
end

---Add or update a command in history
---@param command string The command to add
---@param opts? {project?: string, filetype?: string}
function M.add(command, opts)
	opts = opts or {}
	
	local key = command
	local now = os.time()
	
	if history[key] then
		history[key].frequency = history[key].frequency + 1
		history[key].last_run = now
	else
		history[key] = {
			command = command,
			frequency = 1,
			last_run = now,
			project = opts.project,
			filetype = opts.filetype,
		}
	end
	
	-- Enforce history size limit
	local max_size = get_max_history_size()
	local entries = vim.tbl_values(history)
	if #entries > max_size then
		-- Sort by frequency (descending) and last_run (descending)
		table.sort(entries, function(a, b)
			if a.frequency == b.frequency then
				return a.last_run > b.last_run
			end
			return a.frequency > b.frequency
		end)
		
		-- Keep only the top max_size entries
		local new_history = {}
		for i = 1, math.min(max_size, #entries) do
			local entry = entries[i]
			new_history[entry.command] = entry
		end
		history = new_history
	end
	
	save_history()
end

---Get all commands sorted by frequency (descending)
---@param opts? {project?: string, filetype?: string}
---@return CommandHistoryEntry[]
function M.get_sorted(opts)
	opts = opts or {}
	
	local entries = vim.tbl_values(history)
	
	-- Filter by project or filetype if specified
	if opts.project or opts.filetype then
		entries = vim.tbl_filter(function(entry)
			if opts.project and entry.project ~= opts.project then
				return false
			end
			if opts.filetype and entry.filetype ~= opts.filetype then
				return false
			end
			return true
		end, entries)
	end
	
	-- Sort by frequency (descending) then by last_run (descending)
	table.sort(entries, function(a, b)
		if a.frequency == b.frequency then
			return a.last_run > b.last_run
		end
		return a.frequency > b.frequency
	end)
	
	return entries
end

---Get recent commands (sorted by last_run)
---@param limit? integer Maximum number of commands to return
---@param opts? {project?: string, filetype?: string}
---@return CommandHistoryEntry[]
function M.get_recent(limit, opts)
	limit = limit or 10
	opts = opts or {}
	
	local entries = vim.tbl_values(history)
	
	-- Filter by project or filetype if specified
	if opts.project or opts.filetype then
		entries = vim.tbl_filter(function(entry)
			if opts.project and entry.project ~= opts.project then
				return false
			end
			if opts.filetype and entry.filetype ~= opts.filetype then
				return false
			end
			return true
		end, entries)
	end
	
	-- Sort by last_run (descending)
	table.sort(entries, function(a, b)
		return a.last_run > b.last_run
	end)
	
	-- Return only the first 'limit' entries
	local result = {}
	for i = 1, math.min(limit, #entries) do
		table.insert(result, entries[i])
	end
	
	return result
end

---Clear all history
function M.clear()
	history = {}
	save_history()
end

---Remove a specific command from history
---@param command string The command to remove
function M.remove(command)
	if history[command] then
		history[command] = nil
		save_history()
		return true
	end
	return false
end

---Get the count of commands in history
---@return integer
function M.count()
	return vim.tbl_count(history)
end

return M
