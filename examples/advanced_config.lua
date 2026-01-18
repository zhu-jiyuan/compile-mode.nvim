-- Example configuration for compile-mode.nvim with all new features
-- This file demonstrates how to use the new history, bookmarks, and UI features

-- Basic configuration
vim.g.compile_mode = {
	-- Enable custom floating input (default: true)
	use_custom_input = true,
	
	-- Maximum number of commands in history (default: 100)
	max_history_size = 100,
	
	-- Other existing options
	default_command = "make -k ",
	ask_about_save = true,
	ask_to_interrupt = true,
}

-- Keymaps for new features
vim.keymap.set("n", "<leader>cm", "<cmd>CompileManager<cr>", { desc = "Open compile manager" })
vim.keymap.set("n", "<leader>ch", "<cmd>CompileHistory<cr>", { desc = "Open compile history" })
vim.keymap.set("n", "<leader>cb", "<cmd>CompileBookmarks<cr>", { desc = "Open compile bookmarks" })

-- fzf-lua integration keymaps (if fzf-lua is installed)
if pcall(require, "fzf-lua") then
	vim.keymap.set("n", "<leader>cfh", "<cmd>CompileFzfHistory<cr>", { desc = "Fuzzy search compile history" })
	vim.keymap.set("n", "<leader>cfb", "<cmd>CompileFzfBookmarks<cr>", { desc = "Fuzzy search compile bookmarks" })
	vim.keymap.set("n", "<leader>cfr", "<cmd>CompileFzfRecent<cr>", { desc = "Fuzzy search recent commands" })
	vim.keymap.set("n", "<leader>cfc", "<cmd>CompileFzfCombined<cr>", { desc = "Fuzzy search all commands" })
end

-- Example: Programmatically add bookmarks
local bookmarks = require("compile-mode.bookmarks")

-- Add a C/C++ build bookmark
bookmarks.add({
	name = "build-debug",
	command = "cmake --build build --config Debug",
	filetype = { "c", "cpp" },
	description = "Build project in Debug mode",
})

-- Add a Rust bookmark
bookmarks.add({
	name = "cargo-test",
	command = "cargo test",
	filetype = "rust",
	description = "Run Rust tests",
})

-- Add a project-specific bookmark with regex
bookmarks.add({
	name = "npm-dev",
	command = "npm run dev",
	filetype = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	project = ".*my-project.*", -- Regex pattern for project path
	description = "Start development server",
})

-- Example: Access command history programmatically
local history = require("compile-mode.history")

-- Get all commands sorted by frequency
local frequent_commands = history.get_sorted()
if #frequent_commands > 0 then
	print("Most frequently used command: " .. frequent_commands[1].command)
end

-- Get recent commands
local recent_commands = history.get_recent(5)
for i, entry in ipairs(recent_commands) do
	print(string.format("%d. %s (used %dx)", i, entry.command, entry.frequency))
end

-- Example: Custom autocommand to add bookmarks for specific file types
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		-- Add Python-specific bookmarks on first load
		bookmarks.add({
			name = "python-test",
			command = "python -m pytest",
			filetype = "python",
			description = "Run Python tests",
		})
		
		bookmarks.add({
			name = "python-lint",
			command = "ruff check .",
			filetype = "python",
			description = "Run Python linter",
		})
	end,
	once = true,
})

-- Example: Export bookmarks for sharing
-- You can export bookmarks to a file and share with team
local function export_bookmarks_to_file(filepath)
	local all_bookmarks = bookmarks.export()
	local file = io.open(filepath, "w")
	if file then
		file:write(vim.json.encode(all_bookmarks))
		file:close()
		print("Bookmarks exported to: " .. filepath)
	end
end

-- Example: Import bookmarks from a file
local function import_bookmarks_from_file(filepath)
	local file = io.open(filepath, "r")
	if file then
		local content = file:read("*all")
		file:close()
		local ok, decoded = pcall(vim.json.decode, content)
		if ok then
			bookmarks.import(decoded)
			print("Bookmarks imported from: " .. filepath)
		end
	end
end

-- Add commands for export/import
vim.api.nvim_create_user_command("CompileExportBookmarks", function(opts)
	export_bookmarks_to_file(opts.args)
end, { nargs = 1, complete = "file" })

vim.api.nvim_create_user_command("CompileImportBookmarks", function(opts)
	import_bookmarks_from_file(opts.args)
end, { nargs = 1, complete = "file" })
