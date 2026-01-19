---Bookmark management module
---Allows saving commands by filetype, project, or pattern

local M = {}

---@class Bookmark
---@field name string Display name for the bookmark
---@field command string The command string
---@field type "filetype"|"project"|"pattern" The bookmark type
---@field matcher string The filetype name, project pattern, or regex pattern
---@field description string? Optional description

---@type Bookmark[]
local bookmarks = {}

local config = nil

---Initialize the bookmark module
---@param opts table Configuration options
function M.setup(opts)
	config = opts or {}
	M.load()
end

---Add a bookmark
---@param bookmark Bookmark The bookmark to add
function M.add(bookmark)
	if not bookmark or not bookmark.command or not bookmark.name then
		return
	end

	-- Check if bookmark with same name already exists
	for i, existing in ipairs(bookmarks) do
		if existing.name == bookmark.name then
			bookmarks[i] = bookmark
			M.save()
			return
		end
	end

	table.insert(bookmarks, bookmark)
	M.save()
end

---Remove a bookmark by name
---@param name string The bookmark name
function M.remove(name)
	for i, bookmark in ipairs(bookmarks) do
		if bookmark.name == name then
			table.remove(bookmarks, i)
			M.save()
			return true
		end
	end
	return false
end

---Get all bookmarks
---@return Bookmark[]
function M.get_all()
	return vim.deepcopy(bookmarks)
end

---Get bookmarks matching current context
---@param filetype string? Current filetype
---@param project_path string? Current project path
---@return Bookmark[]
function M.get_matching(filetype, project_path)
	local matching = {}

	for _, bookmark in ipairs(bookmarks) do
		if M._matches_context(bookmark, filetype, project_path) then
			table.insert(matching, bookmark)
		end
	end

	return matching
end

---Check if a bookmark matches the current context
---@param bookmark Bookmark
---@param filetype string?
---@param project_path string?
---@return boolean
function M._matches_context(bookmark, filetype, project_path)
	if bookmark.type == "filetype" then
		return filetype and bookmark.matcher == filetype
	elseif bookmark.type == "project" then
		if not project_path then
			return false
		end
		-- Check if project_path matches the pattern
		return vim.fn.match(project_path, bookmark.matcher) >= 0
	elseif bookmark.type == "pattern" then
		-- Pattern bookmarks match always (they're regex-based search)
		return true
	end
	return false
end

---Clear all bookmarks
function M.clear()
	bookmarks = {}
	M.save()
end

---Get the bookmarks file path
---@return string
local function get_bookmarks_file()
	local data_path = vim.fn.stdpath("data")
	return data_path .. "/compile-mode-bookmarks.json"
end

---Save bookmarks to disk
function M.save()
	local file = get_bookmarks_file()
	local data = vim.json.encode(bookmarks)
	local f = io.open(file, "w")
	if f then
		f:write(data)
		f:close()
	end
end

---Load bookmarks from disk
function M.load()
	local file = get_bookmarks_file()
	local f = io.open(file, "r")
	if f then
		local data = f:read("*all")
		f:close()
		local ok, decoded = pcall(vim.json.decode, data)
		if ok and decoded then
			bookmarks = decoded
		end
	end
end

return M
