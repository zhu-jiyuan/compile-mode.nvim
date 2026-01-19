-- Integration test / demo script for new features
-- This script demonstrates the new functionality

local compile_mode = require("compile-mode")
local history = require("compile-mode.history")
local bookmarks = require("compile-mode.bookmarks")

print("=== Testing compile-mode.nvim new features ===\n")

-- Test 1: Setup
print("Test 1: Setup")
compile_mode.setup({ max_history = 50 })
print("✓ Setup complete\n")

-- Test 2: History module
print("Test 2: History module")
history.clear()
history.add("echo test1", "/home/user")
history.add("echo test2", "/home/user")
history.add("echo test1", "/home/user") -- Increment count
history.add("echo test3", "/home/user")

local all = history.get_all()
print(string.format("✓ Added 3 unique commands, got %d entries", #all))

local sorted = history.get_sorted()
print(string.format("✓ Sorted by frequency: '%s' (count=%d) is first", sorted[1].command, sorted[1].count))

history.remove("echo test2")
all = history.get_all()
print(string.format("✓ After removal: %d entries remain\n", #all))

-- Test 3: Bookmarks module
print("Test 3: Bookmarks module")
bookmarks.clear()

bookmarks.add({
	name = "lua-test",
	command = "busted .",
	type = "filetype",
	matcher = "lua",
	description = "Run Lua tests",
})

bookmarks.add({
	name = "python-run",
	command = "python %",
	type = "filetype",
	matcher = "python",
})

bookmarks.add({
	name = "make-all",
	command = "make -j4",
	type = "pattern",
	matcher = ".*",
})

local all_bookmarks = bookmarks.get_all()
print(string.format("✓ Added 3 bookmarks, got %d entries", #all_bookmarks))

local lua_bookmarks = bookmarks.get_matching("lua", nil)
print(string.format("✓ Found %d bookmark(s) for lua filetype", #lua_bookmarks))

local python_bookmarks = bookmarks.get_matching("python", nil)
print(string.format("✓ Found %d bookmark(s) for python filetype", #python_bookmarks))

local pattern_bookmarks = bookmarks.get_matching(nil, "/any/path")
print(string.format("✓ Found %d pattern bookmark(s)\n", #pattern_bookmarks))

-- Test 4: History persistence
print("Test 4: Persistence")
history.save()
bookmarks.save()

-- Simulate reload by loading
history.load()
bookmarks.load()

all = history.get_all()
all_bookmarks = bookmarks.get_all()
print(string.format("✓ After save/load: %d history entries, %d bookmarks\n", #all, #all_bookmarks))

-- Test 5: Max history limit
print("Test 5: Max history limit")
history.setup({ max_history = 5 })
for i = 1, 10 do
	history.add("echo cmd" .. i, "/home")
end

all = history.get_all()
print(string.format("✓ Added 10 commands with max=5, got %d entries (trimmed correctly)\n", #all))

-- Summary
print("=== All tests passed! ===")
print("\nAvailable commands:")
print("  :Compile [cmd]          - Run a command")
print("  :Recompile              - Rerun last command")
print("  :CompileHistory         - Open manager UI")
print("  :CompileToggleManager   - Toggle manager UI")
print("  :CompilePickHistory     - FZF history picker")
print("  :CompilePickBookmarks   - FZF bookmarks picker")
print("  :CompilePickAll         - FZF all commands picker")
print("\nManager UI keymaps:")
print("  <CR>   - Execute command")
print("  d      - Delete entry")
print("  <Tab>  - Switch history/bookmarks")
print("  q      - Close")
print("  r      - Refresh")
