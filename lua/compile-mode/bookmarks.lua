---@class BookmarkEntry
---@field name string Display name for the bookmark
---@field command string The command to execute
---@field filetype? string|string[] File type(s) this bookmark applies to
---@field project? string Project pattern (regex) this bookmark applies to
---@field description? string Optional description

---@class CompileModeBookmarks
local M = {}

local bookmarks_file = vim.fn.stdpath("data") .. "/compile-mode-bookmarks.json"

---@type BookmarkEntry[]
local bookmarks = {}

---Load bookmarks from file
local function load_bookmarks()
	local file = io.open(bookmarks_file, "r")
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
		vim.notify("Failed to load bookmarks: " .. decoded, vim.log.levels.WARN)
		return {}
	end
	
	return decoded or {}
end

---Save bookmarks to file
local function save_bookmarks()
	-- Ensure directory exists
	local data_dir = vim.fn.stdpath("data")
	vim.fn.mkdir(data_dir, "p")
	
	local file = io.open(bookmarks_file, "w")
	if not file then
		vim.notify("Failed to save bookmarks", vim.log.levels.ERROR)
		return
	end
	
	local ok, encoded = pcall(vim.json.encode, bookmarks)
	if not ok then
		vim.notify("Failed to encode bookmarks: " .. encoded, vim.log.levels.ERROR)
		file:close()
		return
	end
	
	file:write(encoded)
	file:close()
end

---Initialize bookmarks system
function M.setup()
	bookmarks = load_bookmarks()
end

---Add a new bookmark
---@param entry BookmarkEntry
---@return boolean success
function M.add(entry)
	if not entry.name or not entry.command then
		vim.notify("Bookmark must have name and command", vim.log.levels.ERROR)
		return false
	end
	
	-- Check if bookmark with this name already exists
	for i, bookmark in ipairs(bookmarks) do
		if bookmark.name == entry.name then
			bookmarks[i] = entry
			save_bookmarks()
			return true
		end
	end
	
	table.insert(bookmarks, entry)
	save_bookmarks()
	return true
end

---Remove a bookmark by name
---@param name string
---@return boolean success
function M.remove(name)
	for i, bookmark in ipairs(bookmarks) do
		if bookmark.name == name then
			table.remove(bookmarks, i)
			save_bookmarks()
			return true
		end
	end
	return false
end

---Get all bookmarks
---@param opts? {filetype?: string, project?: string}
---@return BookmarkEntry[]
function M.get_all(opts)
	opts = opts or {}
	
	if not opts.filetype and not opts.project then
		return vim.deepcopy(bookmarks)
	end
	
	local current_project = opts.project or vim.fn.getcwd()
	local current_filetype = opts.filetype
	
	local filtered = vim.tbl_filter(function(bookmark)
		-- Check filetype match
		if bookmark.filetype then
			local filetypes = type(bookmark.filetype) == "table" and bookmark.filetype or { bookmark.filetype }
			local filetype_match = false
			for _, ft in ipairs(filetypes) do
				if current_filetype and current_filetype:match(ft) then
					filetype_match = true
					break
				end
			end
			if not filetype_match then
				return false
			end
		end
		
		-- Check project match (regex)
		if bookmark.project then
			if not current_project:match(bookmark.project) then
				return false
			end
		end
		
		return true
	end, bookmarks)
	
	return filtered
end

---Get a bookmark by name
---@param name string
---@return BookmarkEntry|nil
function M.get(name)
	for _, bookmark in ipairs(bookmarks) do
		if bookmark.name == name then
			return vim.deepcopy(bookmark)
		end
	end
	return nil
end

---Clear all bookmarks
function M.clear()
	bookmarks = {}
	save_bookmarks()
end

---Export bookmarks to a table for configuration
---@return BookmarkEntry[]
function M.export()
	return vim.deepcopy(bookmarks)
end

---Import bookmarks from a table (replaces existing)
---@param entries BookmarkEntry[]
function M.import(entries)
	bookmarks = entries
	save_bookmarks()
end

---Get the count of bookmarks
---@return integer
function M.count()
	return #bookmarks
end

return M
