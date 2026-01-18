---Completion functions for compile-mode
local M = {}

---@type table<string, table<string, any>>
local command_completions = {
	go = {
		build = {},
		run = {},
		mod = { "tidy", "vendor", "download", "edit", "graph", "init", "verify", "why" },
		test = {},
		get = {},
		install = {},
		fmt = {},
		vet = {},
	},
	docker = {
		build = {},
		run = {},
		ps = {},
		images = {},
		pull = {},
		push = {},
		stop = {},
		rm = {},
		rmi = {},
		exec = {},
		logs = {},
	},
	git = {
		add = {},
		commit = {},
		push = {},
		pull = {},
		status = {},
		log = {},
		branch = {},
		checkout = {},
		merge = {},
		rebase = {},
		diff = {},
		clone = {},
		remote = { "add", "remove", "rename", "set-url", "show", "prune" },
		fetch = {},
		tag = {},
	},
}

---Custom completion function for Compile command
---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
function M.compile_input_complete(arglead, cmdline, cursorpos)
	local parts = vim.split(cmdline, "%s+", { trimempty = false })
	
	-- The last part is the argument we are trying to complete, so don't include it in the traversal path
	if not vim.endswith(cmdline, " ") then
		parts = vim.list_slice(parts, 1, #parts - 1)
	end
	
	local completion_source = command_completions
	for _, part in ipairs(parts) do
		if type(completion_source) == "table" and completion_source[part] then
			completion_source = completion_source[part]
		else
			-- Can't go deeper, so no custom completions available
			completion_source = nil
			break
		end
	end
	
	if type(completion_source) == "table" then
		local keys = vim.tbl_keys(completion_source)
		if #keys > 0 then
			return keys
		end
		
		-- If it's a list (array), return it
		if #completion_source > 0 then
			return completion_source
		end
	end
	
	-- Fallback to default if no custom completions were found or list was empty
	local results = vim.fn.getcompletion("!" .. cmdline, "cmdline")
	return results
end

---Word completion for Compile command (simpler version)
---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
function M.compile_input_complete_word(arglead, cmdline, cursorpos)
	local results = vim.fn.getcompletion("!" .. cmdline, "cmdline")
	return results
end

-- Register the completion functions globally for VimL compatibility
_G.CompileInputComplete = M.compile_input_complete
_G.CompileInputCompleteWord = M.compile_input_complete_word

return M
