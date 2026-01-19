local assert = require("luassert")
local history = require("compile-mode.history")

describe("history module", function()
	before_each(function()
		-- Clear history before each test
		history.clear()
		history.setup({ max_history = 10 })
	end)

	after_each(function()
		-- Clean up after tests
		history.clear()
	end)

	describe("add", function()
		it("should add a new command to history", function()
			history.add("echo hello", "/home/user")

			local all = history.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("echo hello", all[1].command)
			assert.are.equal(1, all[1].count)
		end)

		it("should increment count for existing command", function()
			history.add("echo hello", "/home/user")
			history.add("echo hello", "/home/user")

			local all = history.get_all()
			assert.are.equal(1, #all)
			assert.are.equal(2, all[1].count)
		end)

		it("should update directory and last_used", function()
			history.add("echo hello", "/home/user")
			local first_time = history.get_all()[1].last_used

			-- Wait a moment
			vim.loop.sleep(10)

			history.add("echo hello", "/home/other")

			local all = history.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("/home/other", all[1].directory)
			assert.is_true(all[1].last_used > first_time)
		end)

		it("should handle empty command", function()
			history.add("", "/home/user")
			local all = history.get_all()
			assert.are.equal(0, #all)
		end)

		it("should handle nil command", function()
			history.add(nil, "/home/user")
			local all = history.get_all()
			assert.are.equal(0, #all)
		end)
	end)

	describe("get_sorted", function()
		it("should sort by frequency descending", function()
			history.add("echo a", "/home")
			history.add("echo b", "/home")
			history.add("echo b", "/home")
			history.add("echo c", "/home")
			history.add("echo c", "/home")
			history.add("echo c", "/home")

			local sorted = history.get_sorted()
			assert.are.equal(3, #sorted)
			assert.are.equal("echo c", sorted[1].command)
			assert.are.equal(3, sorted[1].count)
			assert.are.equal("echo b", sorted[2].command)
			assert.are.equal(2, sorted[2].count)
			assert.are.equal("echo a", sorted[3].command)
			assert.are.equal(1, sorted[3].count)
		end)

		it("should use last_used as tiebreaker", function()
			history.add("echo a", "/home")
			vim.loop.sleep(10)
			history.add("echo b", "/home")

			local sorted = history.get_sorted()
			assert.are.equal("echo b", sorted[1].command)
			assert.are.equal("echo a", sorted[2].command)
		end)
	end)

	describe("remove", function()
		it("should remove a command from history", function()
			history.add("echo hello", "/home")
			history.add("echo world", "/home")

			local success = history.remove("echo hello")

			assert.is_true(success)
			local all = history.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("echo world", all[1].command)
		end)

		it("should return false for non-existent command", function()
			history.add("echo hello", "/home")

			local success = history.remove("echo world")

			assert.is_false(success)
		end)

		it("should rebuild index correctly after removal", function()
			history.add("echo a", "/home")
			history.add("echo b", "/home")
			history.add("echo c", "/home")

			history.remove("echo b")

			-- Add the same command again
			history.add("echo b", "/home")

			local all = history.get_all()
			assert.are.equal(3, #all)

			-- Verify we can still increment it
			history.add("echo b", "/home")
			local found = false
			for _, entry in ipairs(history.get_all()) do
				if entry.command == "echo b" then
					assert.are.equal(2, entry.count)
					found = true
				end
			end
			assert.is_true(found)
		end)
	end)

	describe("max_history", function()
		it("should trim history when exceeding max_history", function()
			history.setup({ max_history = 3 })

			history.add("echo 1", "/home")
			history.add("echo 2", "/home")
			history.add("echo 3", "/home")
			history.add("echo 4", "/home")

			local all = history.get_all()
			assert.are.equal(3, #all)
		end)

		it("should keep most recently used commands", function()
			history.setup({ max_history = 2 })

			history.add("echo old", "/home")
			vim.loop.sleep(10)
			history.add("echo new1", "/home")
			vim.loop.sleep(10)
			history.add("echo new2", "/home")

			local all = history.get_all()
			assert.are.equal(2, #all)

			-- Check that old command was removed
			local has_old = false
			for _, entry in ipairs(all) do
				if entry.command == "echo old" then
					has_old = true
				end
			end
			assert.is_false(has_old)
		end)
	end)

	describe("persistence", function()
		it("should save and load history", function()
			history.add("echo persistent", "/home")

			-- Create a new instance and load
			local history2 = require("compile-mode.history")
			history2.setup({ max_history = 10 })
			history2.load()

			local all = history2.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("echo persistent", all[1].command)
		end)
	end)
end)
