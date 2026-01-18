local history = require("compile-mode.history")

describe("compile-mode.history", function()
	before_each(function()
		-- Clear history before each test
		history.setup()
		history.clear()
	end)
	
	after_each(function()
		-- Clean up after tests
		history.clear()
	end)
	
	describe("add", function()
		it("should add a new command to history", function()
			history.add("make")
			
			local entries = history.get_sorted()
			assert.equals(1, #entries)
			assert.equals("make", entries[1].command)
			assert.equals(1, entries[1].frequency)
		end)
		
		it("should increment frequency for repeated commands", function()
			history.add("make")
			history.add("make")
			history.add("make")
			
			local entries = history.get_sorted()
			assert.equals(1, #entries)
			assert.equals("make", entries[1].command)
			assert.equals(3, entries[1].frequency)
		end)
		
		it("should store filetype and project information", function()
			history.add("make", { filetype = "lua", project = "/home/user/project" })
			
			local entries = history.get_sorted()
			assert.equals(1, #entries)
			assert.equals("lua", entries[1].filetype)
			assert.equals("/home/user/project", entries[1].project)
		end)
	end)
	
	describe("get_sorted", function()
		it("should sort commands by frequency", function()
			history.add("make")
			history.add("cargo build")
			history.add("cargo build")
			history.add("npm test")
			history.add("npm test")
			history.add("npm test")
			
			local entries = history.get_sorted()
			assert.equals(3, #entries)
			assert.equals("npm test", entries[1].command)
			assert.equals(3, entries[1].frequency)
			assert.equals("cargo build", entries[2].command)
			assert.equals(2, entries[2].frequency)
			assert.equals("make", entries[3].command)
			assert.equals(1, entries[3].frequency)
		end)
		
		it("should filter by filetype", function()
			history.add("make", { filetype = "c" })
			history.add("cargo build", { filetype = "rust" })
			history.add("npm test", { filetype = "javascript" })
			
			local entries = history.get_sorted({ filetype = "rust" })
			assert.equals(1, #entries)
			assert.equals("cargo build", entries[1].command)
		end)
		
		it("should filter by project", function()
			history.add("make", { project = "/home/user/project1" })
			history.add("cargo build", { project = "/home/user/project2" })
			history.add("npm test", { project = "/home/user/project1" })
			
			local entries = history.get_sorted({ project = "/home/user/project1" })
			assert.equals(2, #entries)
		end)
	end)
	
	describe("get_recent", function()
		it("should return recent commands sorted by time", function()
			-- Add some delay between adds to ensure different timestamps
			history.add("make")
			vim.loop.sleep(100)
			history.add("cargo build")
			vim.loop.sleep(100)
			history.add("npm test")
			
			local entries = history.get_recent(10)
			assert.equals(3, #entries)
			-- Most recent should be first
			assert.equals("npm test", entries[1].command)
			assert.equals("cargo build", entries[2].command)
			assert.equals("make", entries[3].command)
		end)
		
		it("should respect the limit parameter", function()
			for i = 1, 10 do
				history.add("command" .. i)
				vim.loop.sleep(10)
			end
			
			local entries = history.get_recent(5)
			assert.equals(5, #entries)
		end)
	end)
	
	describe("remove", function()
		it("should remove a command from history", function()
			history.add("make")
			history.add("cargo build")
			
			assert.equals(2, history.count())
			
			local removed = history.remove("make")
			assert.is_true(removed)
			assert.equals(1, history.count())
			
			local entries = history.get_sorted()
			assert.equals("cargo build", entries[1].command)
		end)
		
		it("should return false when removing non-existent command", function()
			history.add("make")
			
			local removed = history.remove("nonexistent")
			assert.is_false(removed)
			assert.equals(1, history.count())
		end)
	end)
	
	describe("clear", function()
		it("should clear all history", function()
			history.add("make")
			history.add("cargo build")
			history.add("npm test")
			
			assert.equals(3, history.count())
			
			history.clear()
			
			assert.equals(0, history.count())
			local entries = history.get_sorted()
			assert.equals(0, #entries)
		end)
	end)
	
	describe("count", function()
		it("should return the number of commands in history", function()
			assert.equals(0, history.count())
			
			history.add("make")
			assert.equals(1, history.count())
			
			history.add("cargo build")
			assert.equals(2, history.count())
			
			-- Adding the same command should not increase count
			history.add("make")
			assert.equals(2, history.count())
		end)
	end)
end)
