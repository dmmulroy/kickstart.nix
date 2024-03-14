vim.api.nvim_create_user_command("CopyFilePathToClipboard", function()
	vim.fn.setreg("+", vim.fn.expand("%:p"))
end, {})
