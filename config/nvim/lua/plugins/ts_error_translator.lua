return {
	{
		dir = "~/Code/personal/ts-error-translator.nvim",
		enabled = false,
		-- branch = "pr18",
		config = function()
			require("ts-error-translator").setup()
		end,
	},
}
