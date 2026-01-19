local assert = require("luassert")
local bookmarks = require("compile-mode.bookmarks")

describe("bookmarks module", function()
	before_each(function()
		bookmarks.clear()
		bookmarks.setup()
	end)

	after_each(function()
		bookmarks.clear()
	end)

	describe("add", function()
		it("should add a new bookmark", function()
			local bookmark = {
				name = "test",
				command = "echo test",
				type = "filetype",
				matcher = "lua",
			}

			bookmarks.add(bookmark)

			local all = bookmarks.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("test", all[1].name)
			assert.are.equal("echo test", all[1].command)
		end)

		it("should update existing bookmark with same name", function()
			local bookmark1 = {
				name = "test",
				command = "echo first",
				type = "filetype",
				matcher = "lua",
			}

			bookmarks.add(bookmark1)

			local bookmark2 = {
				name = "test",
				command = "echo second",
				type = "filetype",
				matcher = "python",
			}

			bookmarks.add(bookmark2)

			local all = bookmarks.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("echo second", all[1].command)
			assert.are.equal("python", all[1].matcher)
		end)

		it("should handle bookmark with description", function()
			local bookmark = {
				name = "test",
				command = "echo test",
				type = "pattern",
				matcher = ".*",
				description = "A test bookmark",
			}

			bookmarks.add(bookmark)

			local all = bookmarks.get_all()
			assert.are.equal("A test bookmark", all[1].description)
		end)

		it("should not add invalid bookmark", function()
			bookmarks.add({ name = "no-command" })
			bookmarks.add({ command = "no-name" })
			bookmarks.add(nil)

			local all = bookmarks.get_all()
			assert.are.equal(0, #all)
		end)
	end)

	describe("remove", function()
		it("should remove a bookmark by name", function()
			bookmarks.add({
				name = "test1",
				command = "echo 1",
				type = "filetype",
				matcher = "lua",
			})
			bookmarks.add({
				name = "test2",
				command = "echo 2",
				type = "filetype",
				matcher = "python",
			})

			local success = bookmarks.remove("test1")

			assert.is_true(success)
			local all = bookmarks.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("test2", all[1].name)
		end)

		it("should return false for non-existent bookmark", function()
			local success = bookmarks.remove("nonexistent")
			assert.is_false(success)
		end)
	end)

	describe("get_matching", function()
		before_each(function()
			bookmarks.add({
				name = "lua-build",
				command = "lua build.lua",
				type = "filetype",
				matcher = "lua",
			})
			bookmarks.add({
				name = "python-test",
				command = "pytest",
				type = "filetype",
				matcher = "python",
			})
			bookmarks.add({
				name = "project-make",
				command = "make",
				type = "project",
				matcher = "/home/user/myproject",
			})
			bookmarks.add({
				name = "pattern-grep",
				command = "grep -r pattern",
				type = "pattern",
				matcher = ".*",
			})
		end)

		it("should match filetype bookmarks", function()
			local matching = bookmarks.get_matching("lua", nil)

			local found_lua = false
			local found_python = false
			for _, bookmark in ipairs(matching) do
				if bookmark.name == "lua-build" then
					found_lua = true
				end
				if bookmark.name == "python-test" then
					found_python = true
				end
			end

			assert.is_true(found_lua)
			assert.is_false(found_python)
		end)

		it("should match project bookmarks", function()
			local matching = bookmarks.get_matching(nil, "/home/user/myproject")

			local found = false
			for _, bookmark in ipairs(matching) do
				if bookmark.name == "project-make" then
					found = true
				end
			end

			assert.is_true(found)
		end)

		it("should match pattern bookmarks", function()
			local matching = bookmarks.get_matching("anything", "/any/path")

			local found = false
			for _, bookmark in ipairs(matching) do
				if bookmark.name == "pattern-grep" then
					found = true
				end
			end

			assert.is_true(found)
		end)

		it("should not match wrong filetype", function()
			local matching = bookmarks.get_matching("javascript", nil)

			for _, bookmark in ipairs(matching) do
				assert.is_not.equal("lua-build", bookmark.name)
				assert.is_not.equal("python-test", bookmark.name)
			end
		end)
	end)

	describe("persistence", function()
		it("should save and load bookmarks", function()
			bookmarks.add({
				name = "persistent",
				command = "echo persistent",
				type = "filetype",
				matcher = "lua",
			})

			-- Create new instance and load
			local bookmarks2 = require("compile-mode.bookmarks")
			bookmarks2.setup()
			bookmarks2.load()

			local all = bookmarks2.get_all()
			assert.are.equal(1, #all)
			assert.are.equal("persistent", all[1].name)
		end)
	end)
end)
