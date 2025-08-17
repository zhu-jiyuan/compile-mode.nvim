local M = {}

function M.setup()
	vim.api.nvim_set_hl(0, "CompileModeMessage", { fg = "NONE", underline = true, default = true })
	vim.api.nvim_set_hl(0, "CompileModeMessageRow", { fg = "Magenta", default = true })
	vim.api.nvim_set_hl(0, "CompileModeMessageCol", { fg = "Cyan", default = true })
	vim.api.nvim_set_hl(0, "CompileModeError", { fg = "Red", default = true })
	vim.api.nvim_set_hl(0, "CompileModeWarning", { fg = "DarkYellow", default = true })
	vim.api.nvim_set_hl(0, "CompileModeInfo", { fg = "Green", default = true })
	vim.api.nvim_set_hl(0, "CompileModeCommandOutput", { fg = "#6699ff", default = true })
	vim.api.nvim_set_hl(0, "CompileModeDirectoryMessage", { fg = "#6699ff", default = true })
	vim.api.nvim_set_hl(0, "CompileModeOutputFile", { fg = "#9966cc", default = true })
	vim.api.nvim_set_hl(0, "CompileModeCheckResult", { fg = "#ff9966", bold = true, default = true })
	vim.api.nvim_set_hl(0, "CompileModeCheckTarget", { fg = "#ff9966", default = true })
	vim.api.nvim_set_hl(0, "CompileModeErrorLocus", { link = "Visual" })
end

return M
