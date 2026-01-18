local command = vim.api.nvim_create_user_command
local compile_mode = require("compile-mode")

command("Compile", compile_mode.compile, {
	nargs = "?",
	bang = true,
	count = true,
	complete = function(_, cmdline)
		local cmd = cmdline:gsub("Compile%s+", "")
		local results = vim.fn.getcompletion(("!%s"):format(cmd), "cmdline")
		return results
	end,
})
command("Recompile", compile_mode.recompile, { bang = true, count = true })
command("NextError", compile_mode.next_error, { count = 1 })
command("PrevError", compile_mode.prev_error, { count = 1 })
command("CurrentError", compile_mode.current_error, {})
command("FirstError", compile_mode.first_error, { count = 1 })
command("QuickfixErrors", function()
	compile_mode.send_to_qflist()
	vim.cmd("botright copen")
end, {})
command("NextErrorFollow", compile_mode.next_error_follow, {})

-- New commands for history, bookmarks, and UI manager
command("CompileManager", function()
	local manager = require("compile-mode.ui.manager")
	manager.open()
end, { desc = "Open compile mode manager" })

command("CompileHistory", function()
	local manager = require("compile-mode.ui.manager")
	manager.open({ view = "history" })
end, { desc = "Open compile mode history view" })

command("CompileBookmarks", function()
	local manager = require("compile-mode.ui.manager")
	manager.open({ view = "bookmarks" })
end, { desc = "Open compile mode bookmarks view" })

command("CompileFzfHistory", function()
	local fzf = require("compile-mode.fzf")
	fzf.history_picker()
end, { desc = "Open command history in fzf" })

command("CompileFzfBookmarks", function()
	local fzf = require("compile-mode.fzf")
	fzf.bookmarks_picker()
end, { desc = "Open bookmarks in fzf" })

command("CompileFzfRecent", function(opts)
	local fzf = require("compile-mode.fzf")
	local limit = tonumber(opts.args) or 20
	fzf.recent_picker(limit)
end, { nargs = "?", desc = "Open recent commands in fzf" })

command("CompileFzfCombined", function()
	local fzf = require("compile-mode.fzf")
	fzf.combined_picker()
end, { desc = "Open combined history and bookmarks in fzf" })

command("CompileAddBookmark", function(opts)
	local args = vim.split(opts.args, "%s+", { trimempty = true })
	if #args < 2 then
		vim.notify("Usage: CompileAddBookmark <name> <command>", vim.log.levels.ERROR)
		return
	end
	
	local name = args[1]
	local command_str = table.concat(vim.list_slice(args, 2), " ")
	
	local bookmarks = require("compile-mode.bookmarks")
	bookmarks.add({
		name = name,
		command = command_str,
		filetype = vim.bo.filetype ~= "" and vim.bo.filetype or nil,
		project = vim.fn.getcwd(),
	})
	vim.notify("Bookmark added: " .. name, vim.log.levels.INFO)
end, { nargs = "+", desc = "Add a new bookmark" })

command("CompileClearHistory", function()
	local history = require("compile-mode.history")
	local response = vim.fn.confirm("Clear all command history?", "&Yes\n&No")
	if response == 1 then
		history.clear()
		vim.notify("Command history cleared", vim.log.levels.INFO)
	end
end, { desc = "Clear command history" })
