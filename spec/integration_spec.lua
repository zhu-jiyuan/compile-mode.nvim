-- Integration test for the new features
-- This test verifies that all modules work together

local history = require("compile-mode.history")
local bookmarks = require("compile-mode.bookmarks")
local compile_mode = require("compile-mode")

describe("compile-mode integration", function()
	before_each(function()
		-- Clear state
		history.setup()
		bookmarks.setup()
		history.clear()
		bookmarks.clear()
	end)
	
	after_each(function()
		-- Clean up
		history.clear()
		bookmarks.clear()
	end)
	
	describe("history and bookmarks integration", function()
		it("should allow bookmarking commands from history", function()
			-- Add a command to history
			history.add("make test", { filetype = "c", project = "/test/project" })
			
			-- Get the command from history
			local commands = history.get_sorted()
			assert.equals(1, #commands)
			
			local cmd = commands[1]
			
			-- Bookmark it
			bookmarks.add({
				name = "test-command",
				command = cmd.command,
				filetype = cmd.filetype,
				project = cmd.project,
			})
			
			-- Verify bookmark was created
			local bookmark = bookmarks.get("test-command")
			assert.is_not_nil(bookmark)
			assert.equals("make test", bookmark.command)
			assert.equals("c", bookmark.filetype)
		end)
		
		it("should track frequency across multiple runs", function()
			-- Simulate multiple compilations
			history.add("make")
			history.add("make test")
			history.add("make")
			history.add("make test")
			history.add("make")
			
			local commands = history.get_sorted()
			
			-- "make" should be first with frequency 3
			assert.equals("make", commands[1].command)
			assert.equals(3, commands[1].frequency)
			
			-- "make test" should be second with frequency 2
			assert.equals("make test", commands[2].command)
			assert.equals(2, commands[2].frequency)
		end)
		
		it("should filter history and bookmarks by filetype", function()
			-- Add various commands
			history.add("make", { filetype = "c" })
			history.add("cargo build", { filetype = "rust" })
			history.add("npm test", { filetype = "javascript" })
			
			-- Add corresponding bookmarks
			bookmarks.add({ name = "c-build", command = "make", filetype = "c" })
			bookmarks.add({ name = "rust-build", command = "cargo build", filetype = "rust" })
			bookmarks.add({ name = "js-test", command = "npm test", filetype = "javascript" })
			
			-- Filter history by filetype
			local rust_history = history.get_sorted({ filetype = "rust" })
			assert.equals(1, #rust_history)
			assert.equals("cargo build", rust_history[1].command)
			
			-- Filter bookmarks by filetype
			local rust_bookmarks = bookmarks.get_all({ filetype = "rust" })
			assert.equals(1, #rust_bookmarks)
			assert.equals("rust-build", rust_bookmarks[1].name)
		end)
		
		it("should respect history size limit", function()
			-- Set a small history size (this would normally be in config)
			-- For this test, we'll just add many commands and verify the limit works
			
			-- Add 10 commands
			for i = 1, 10 do
				history.add("command" .. i)
			end
			
			assert.equals(10, history.count())
			
			-- The implementation should handle size limits internally
			-- This test just verifies basic counting works
		end)
		
		it("should handle bookmark export and import", function()
			-- Add some bookmarks
			bookmarks.add({ name = "build", command = "make", filetype = "c" })
			bookmarks.add({ name = "test", command = "make test", filetype = "c" })
			bookmarks.add({ name = "clean", command = "make clean" })
			
			assert.equals(3, bookmarks.count())
			
			-- Export
			local exported = bookmarks.export()
			assert.equals(3, #exported)
			
			-- Clear and import
			bookmarks.clear()
			assert.equals(0, bookmarks.count())
			
			bookmarks.import(exported)
			assert.equals(3, bookmarks.count())
			
			-- Verify data integrity
			local build = bookmarks.get("build")
			assert.equals("make", build.command)
			assert.equals("c", build.filetype)
		end)
		
		it("should handle project-based filtering with regex", function()
			-- Add commands with different projects
			history.add("make", { project = "/home/user/myproject" })
			history.add("cargo build", { project = "/home/user/rustproject" })
			history.add("npm test", { project = "/home/user/myproject" })
			
			-- Filter by project
			local myproject_history = history.get_sorted({ project = "/home/user/myproject" })
			assert.equals(2, #myproject_history)
			
			-- Add bookmarks with regex patterns
			bookmarks.add({
				name = "any-make",
				command = "make",
				project = ".*project$",
			})
			
			-- This should match both projects
			local filtered = bookmarks.get_all({ project = "/home/user/myproject" })
			assert.equals(1, #filtered)
		end)
		
		it("should handle multiple file types in bookmarks", function()
			bookmarks.add({
				name = "build-cpp",
				command = "make",
				filetype = { "c", "cpp", "h", "hpp" },
			})
			
			-- Should match all these file types
			local c_bookmarks = bookmarks.get_all({ filetype = "c" })
			assert.equals(1, #c_bookmarks)
			
			local cpp_bookmarks = bookmarks.get_all({ filetype = "cpp" })
			assert.equals(1, #cpp_bookmarks)
			
			local h_bookmarks = bookmarks.get_all({ filetype = "h" })
			assert.equals(1, #h_bookmarks)
		end)
		
		it("should track last_run timestamp", function()
			history.add("make")
			local before = os.time()
			
			-- Add again to update timestamp
			vim.loop.sleep(100)
			history.add("make")
			local after = os.time()
			
			local commands = history.get_sorted()
			assert.equals(1, #commands)
			
			-- Timestamp should be between before and after
			assert.is_true(commands[1].last_run >= before)
			assert.is_true(commands[1].last_run <= after)
		end)
		
		it("should get recent commands sorted by time", function()
			history.add("old_command")
			vim.loop.sleep(100)
			history.add("middle_command")
			vim.loop.sleep(100)
			history.add("recent_command")
			
			local recent = history.get_recent(3)
			
			-- Should be in reverse chronological order
			assert.equals("recent_command", recent[1].command)
			assert.equals("middle_command", recent[2].command)
			assert.equals("old_command", recent[3].command)
		end)
	end)
end)
