local bookmarks = require("compile-mode.bookmarks")

describe("compile-mode.bookmarks", function()
	before_each(function()
		-- Clear bookmarks before each test
		bookmarks.setup()
		bookmarks.clear()
	end)
	
	after_each(function()
		-- Clean up after tests
		bookmarks.clear()
	end)
	
	describe("add", function()
		it("should add a new bookmark", function()
			local success = bookmarks.add({
				name = "build",
				command = "make",
			})
			
			assert.is_true(success)
			assert.equals(1, bookmarks.count())
			
			local bookmark = bookmarks.get("build")
			assert.is_not_nil(bookmark)
			assert.equals("make", bookmark.command)
		end)
		
		it("should update existing bookmark with same name", function()
			bookmarks.add({
				name = "build",
				command = "make",
			})
			
			bookmarks.add({
				name = "build",
				command = "make -j4",
			})
			
			assert.equals(1, bookmarks.count())
			
			local bookmark = bookmarks.get("build")
			assert.equals("make -j4", bookmark.command)
		end)
		
		it("should store filetype and project information", function()
			bookmarks.add({
				name = "build",
				command = "make",
				filetype = "c",
				project = "myproject",
			})
			
			local bookmark = bookmarks.get("build")
			assert.equals("c", bookmark.filetype)
			assert.equals("myproject", bookmark.project)
		end)
		
		it("should fail without name or command", function()
			local success = bookmarks.add({
				name = "test",
			})
			assert.is_false(success)
			
			success = bookmarks.add({
				command = "make",
			})
			assert.is_false(success)
		end)
	end)
	
	describe("get_all", function()
		it("should return all bookmarks", function()
			bookmarks.add({ name = "build", command = "make" })
			bookmarks.add({ name = "test", command = "make test" })
			bookmarks.add({ name = "clean", command = "make clean" })
			
			local all = bookmarks.get_all()
			assert.equals(3, #all)
		end)
		
		it("should filter by filetype", function()
			bookmarks.add({
				name = "build-c",
				command = "make",
				filetype = "c",
			})
			bookmarks.add({
				name = "build-rust",
				command = "cargo build",
				filetype = "rust",
			})
			bookmarks.add({
				name = "test-js",
				command = "npm test",
				filetype = "javascript",
			})
			
			local filtered = bookmarks.get_all({ filetype = "rust" })
			assert.equals(1, #filtered)
			assert.equals("build-rust", filtered[1].name)
		end)
		
		it("should filter by project pattern", function()
			bookmarks.add({
				name = "build1",
				command = "make",
				project = "myproject",
			})
			bookmarks.add({
				name = "build2",
				command = "cargo build",
				project = "other.*",
			})
			
			local filtered = bookmarks.get_all({ project = "myproject" })
			assert.equals(1, #filtered)
			assert.equals("build1", filtered[1].name)
		end)
		
		it("should support multiple filetypes", function()
			bookmarks.add({
				name = "build",
				command = "make",
				filetype = { "c", "cpp" },
			})
			
			local filtered_c = bookmarks.get_all({ filetype = "c" })
			assert.equals(1, #filtered_c)
			
			local filtered_cpp = bookmarks.get_all({ filetype = "cpp" })
			assert.equals(1, #filtered_cpp)
			
			local filtered_rust = bookmarks.get_all({ filetype = "rust" })
			assert.equals(0, #filtered_rust)
		end)
	end)
	
	describe("get", function()
		it("should return a specific bookmark by name", function()
			bookmarks.add({ name = "build", command = "make" })
			bookmarks.add({ name = "test", command = "make test" })
			
			local bookmark = bookmarks.get("test")
			assert.is_not_nil(bookmark)
			assert.equals("make test", bookmark.command)
		end)
		
		it("should return nil for non-existent bookmark", function()
			local bookmark = bookmarks.get("nonexistent")
			assert.is_nil(bookmark)
		end)
	end)
	
	describe("remove", function()
		it("should remove a bookmark by name", function()
			bookmarks.add({ name = "build", command = "make" })
			bookmarks.add({ name = "test", command = "make test" })
			
			assert.equals(2, bookmarks.count())
			
			local removed = bookmarks.remove("build")
			assert.is_true(removed)
			assert.equals(1, bookmarks.count())
			
			local bookmark = bookmarks.get("build")
			assert.is_nil(bookmark)
		end)
		
		it("should return false when removing non-existent bookmark", function()
			bookmarks.add({ name = "build", command = "make" })
			
			local removed = bookmarks.remove("nonexistent")
			assert.is_false(removed)
			assert.equals(1, bookmarks.count())
		end)
	end)
	
	describe("clear", function()
		it("should clear all bookmarks", function()
			bookmarks.add({ name = "build", command = "make" })
			bookmarks.add({ name = "test", command = "make test" })
			bookmarks.add({ name = "clean", command = "make clean" })
			
			assert.equals(3, bookmarks.count())
			
			bookmarks.clear()
			
			assert.equals(0, bookmarks.count())
			local all = bookmarks.get_all()
			assert.equals(0, #all)
		end)
	end)
	
	describe("import and export", function()
		it("should export and import bookmarks", function()
			bookmarks.add({ name = "build", command = "make" })
			bookmarks.add({ name = "test", command = "make test" })
			
			local exported = bookmarks.export()
			assert.equals(2, #exported)
			
			-- Clear and import
			bookmarks.clear()
			assert.equals(0, bookmarks.count())
			
			bookmarks.import(exported)
			assert.equals(2, bookmarks.count())
			
			local bookmark = bookmarks.get("build")
			assert.is_not_nil(bookmark)
			assert.equals("make", bookmark.command)
		end)
	end)
	
	describe("count", function()
		it("should return the number of bookmarks", function()
			assert.equals(0, bookmarks.count())
			
			bookmarks.add({ name = "build", command = "make" })
			assert.equals(1, bookmarks.count())
			
			bookmarks.add({ name = "test", command = "make test" })
			assert.equals(2, bookmarks.count())
		end)
	end)
end)
