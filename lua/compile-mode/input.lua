---Mini terminal input buffer for command input
---Replaces vim.ui.input with a custom terminal-like interface

local M = {}

---@type integer? Buffer number for input
local input_buf = nil

---@type integer? Window ID for input
local input_win = nil

---@type function? Callback to execute with input
local input_callback = nil

---Open a mini terminal-style input buffer
---@param opts table Options with prompt, default, completion
---@param callback function Callback function to call with input
function M.open(opts, callback)
	opts = opts or {}
	input_callback = callback

	-- Create buffer
	input_buf = vim.api.nvim_create_buf(false, true)

	-- Calculate window size and position
	local width = math.min(80, vim.o.columns - 4)
	local height = 1
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create floating window
	input_win = vim.api.nvim_open_win(input_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = opts.prompt or "Input",
		title_pos = "left",
	})

	-- Setup buffer options
	vim.api.nvim_buf_set_option(input_buf, "buftype", "prompt")
	vim.api.nvim_buf_set_option(input_buf, "bufhidden", "wipe")

	-- Set prompt
	vim.fn.prompt_setprompt(input_buf, opts.prompt or "> ")

	-- Set default text if provided
	if opts.default and opts.default ~= "" then
		vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { opts.default })
		-- Move cursor to end of line
		vim.cmd("startinsert!")
	else
		vim.cmd("startinsert")
	end

	-- Setup keymaps
	M._setup_keymaps()

	-- Handle completion if provided
	if opts.completion then
		vim.api.nvim_buf_set_option(input_buf, "completefunc", opts.completion)
	end
end

---Setup keymaps for the input buffer
function M._setup_keymaps()
	if not input_buf then
		return
	end

	local opts = { buffer = input_buf, noremap = true, silent = true }

	-- Submit on Enter
	vim.keymap.set("i", "<CR>", function()
		M._submit()
	end, opts)

	-- Cancel on Escape
	vim.keymap.set("i", "<Esc>", function()
		M._cancel()
	end, opts)

	vim.keymap.set("n", "<Esc>", function()
		M._cancel()
	end, opts)

	vim.keymap.set("n", "q", function()
		M._cancel()
	end, opts)

	-- Tab completion
	vim.keymap.set("i", "<Tab>", function()
		return M._handle_completion()
	end, { buffer = input_buf, expr = true })
end

---Handle tab completion
---@return string
function M._handle_completion()
	-- Use built-in completion
	if vim.fn.pumvisible() == 1 then
		return "<C-n>"
	else
		return "<C-x><C-u>"
	end
end

---Submit the input
function M._submit()
	if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
		return
	end

	-- Get the input text (skip prompt)
	local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
	local text = lines[1] or ""

	-- Close the window
	M.close()

	-- Call the callback with the input
	if input_callback then
		input_callback(text)
		input_callback = nil
	end
end

---Cancel the input
function M._cancel()
	M.close()
	if input_callback then
		input_callback(nil)
		input_callback = nil
	end
end

---Close the input window
function M.close()
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_win_close(input_win, true)
	end
	input_win = nil
	input_buf = nil
end

return M
