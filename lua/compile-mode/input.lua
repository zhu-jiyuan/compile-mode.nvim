---Custom input module using a floating terminal-like buffer
---@class CompileModeInput
local M = {}

local api = vim.api

---@class InputOpts
---@field prompt? string Prompt text to display
---@field default? string Default text
---@field completion? string Completion function
---@field on_submit? fun(text: string|nil) Callback when input is submitted

---Create a floating window for input
---@param opts InputOpts
---@return integer bufnr, integer winid
local function create_input_window(opts)
	opts = opts or {}
	
	-- Calculate window size
	local width = math.floor(vim.o.columns * 0.6)
	local height = 1
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	
	-- Create buffer
	local bufnr = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	api.nvim_buf_set_option(bufnr, "filetype", "compile-mode-input")
	
	-- Create border buffer for prompt
	local border_bufnr = api.nvim_create_buf(false, true)
	
	-- Create border window
	local border_winid = api.nvim_open_win(border_bufnr, false, {
		relative = "editor",
		width = width + 2,
		height = height + 2,
		row = row - 1,
		col = col - 1,
		style = "minimal",
		border = "rounded",
		title = opts.prompt or "Input",
		title_pos = "center",
	})
	
	-- Create main window
	local winid = api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
	})
	
	-- Set window options
	api.nvim_win_set_option(winid, "cursorline", false)
	api.nvim_win_set_option(winid, "number", false)
	api.nvim_win_set_option(winid, "relativenumber", false)
	api.nvim_win_set_option(winid, "signcolumn", "no")
	
	-- Store border window id for cleanup
	api.nvim_buf_set_var(bufnr, "compile_mode_border_winid", border_winid)
	
	return bufnr, winid
end

---Setup input buffer with default text and keymaps
---@param bufnr integer
---@param winid integer
---@param opts InputOpts
local function setup_input_buffer(bufnr, winid, opts)
	-- Set default text
	if opts.default then
		api.nvim_buf_set_lines(bufnr, 0, -1, false, { opts.default })
		-- Move cursor to end of line
		vim.schedule(function()
			if api.nvim_win_is_valid(winid) then
				local line = api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
				api.nvim_win_set_cursor(winid, { 1, #line })
			end
		end)
	end
	
	-- Enter insert mode
	vim.schedule(function()
		if api.nvim_win_is_valid(winid) then
			vim.cmd("startinsert!")
		end
	end)
	
	-- Store callback
	if opts.on_submit then
		api.nvim_buf_set_var(bufnr, "compile_mode_on_submit", opts.on_submit)
	end
	
	-- Setup completion if provided
	if opts.completion then
		api.nvim_buf_set_option(bufnr, "completefunc", opts.completion)
	end
	
	-- Setup keymaps
	local function close_and_submit()
		local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local text = lines[1] or ""
		
		-- Close windows
		local ok, border_winid = pcall(api.nvim_buf_get_var, bufnr, "compile_mode_border_winid")
		if ok and api.nvim_win_is_valid(border_winid) then
			api.nvim_win_close(border_winid, true)
		end
		if api.nvim_win_is_valid(winid) then
			api.nvim_win_close(winid, true)
		end
		
		-- Call callback
		if opts.on_submit then
			vim.schedule(function()
				opts.on_submit(text)
			end)
		end
	end
	
	local function close_and_cancel()
		-- Close windows
		local ok, border_winid = pcall(api.nvim_buf_get_var, bufnr, "compile_mode_border_winid")
		if ok and api.nvim_win_is_valid(border_winid) then
			api.nvim_win_close(border_winid, true)
		end
		if api.nvim_win_is_valid(winid) then
			api.nvim_win_close(winid, true)
		end
		
		-- Call callback with nil
		if opts.on_submit then
			vim.schedule(function()
				opts.on_submit(nil)
			end)
		end
	end
	
	-- Keymap for submit (Enter in normal mode, Ctrl-M in insert mode)
	api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "", {
		noremap = true,
		silent = true,
		callback = close_and_submit,
	})
	api.nvim_buf_set_keymap(bufnr, "i", "<CR>", "", {
		noremap = true,
		silent = true,
		callback = close_and_submit,
	})
	
	-- Keymap for cancel (Esc)
	api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "", {
		noremap = true,
		silent = true,
		callback = close_and_cancel,
	})
	api.nvim_buf_set_keymap(bufnr, "i", "<Esc>", "", {
		noremap = true,
		silent = true,
		callback = close_and_cancel,
	})
	
	-- Keymap for cancel (Ctrl-C)
	api.nvim_buf_set_keymap(bufnr, "i", "<C-c>", "", {
		noremap = true,
		silent = true,
		callback = close_and_cancel,
	})
	
	-- Auto-close on buffer leave
	api.nvim_create_autocmd({ "BufLeave" }, {
		buffer = bufnr,
		once = true,
		callback = function()
			vim.schedule(function()
				if api.nvim_buf_is_valid(bufnr) then
					close_and_cancel()
				end
			end)
		end,
	})
end

---Show input window and get user input asynchronously
---@param opts InputOpts
function M.input(opts)
	opts = opts or {}
	
	local bufnr, winid = create_input_window(opts)
	setup_input_buffer(bufnr, winid, opts)
end

---Synchronous version of input (blocks until user submits)
---@param opts InputOpts
---@return string|nil
function M.input_sync(opts)
	opts = opts or {}
	
	local result = nil
	local done = false
	
	local original_on_submit = opts.on_submit
	opts.on_submit = function(text)
		result = text
		done = true
		if original_on_submit then
			original_on_submit(text)
		end
	end
	
	M.input(opts)
	
	-- Wait for completion
	vim.wait(30000, function()
		return done
	end, 10)
	
	return result
end

return M
