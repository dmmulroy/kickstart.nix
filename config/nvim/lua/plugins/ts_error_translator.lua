return {
	{
		dir = "~/Code/personal/ts-error-translator.nvim",
		-- branch = "pr18",
		config = function()
			require("ts-error-translator").setup()
		end,
	},
}