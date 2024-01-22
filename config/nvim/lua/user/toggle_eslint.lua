vim.api.nvim_create_user_command("ToggleESLint", function()
	require("null-ls").toggle("eslint")
end, {})
