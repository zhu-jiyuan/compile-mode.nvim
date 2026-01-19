local command = vim.api.nvim_create_user_command
local compile_mode = require("compile-mode")

-- Initialize the new features
compile_mode.setup()

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

-- New commands for history and bookmarks
command("CompileHistory", compile_mode.open_manager, {})
command("CompileToggleManager", compile_mode.toggle_manager, {})
command("CompilePickHistory", compile_mode.pick_history, {})
command("CompilePickBookmarks", compile_mode.pick_bookmarks, {})
command("CompilePickAll", compile_mode.pick_all, {})

