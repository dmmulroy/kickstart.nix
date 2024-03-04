return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost" },
		cmd = { "LspInfo", "LspInstall", "LspUninstall", "Mason" },
		dependencies = {
			-- Plugin(s) and UI to automatically install LSPs to stdpath
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Install lsp autocompletions
			"hrsh7th/cmp-nvim-lsp",

			-- Progress/Status update for LSP
			{ "j-hui/fidget.nvim", opts = {} },
		},
		config = function()
			local map_lsp_keybinds = require("user.keymaps").map_lsp_keybinds -- Has to load keymaps before pluginslsp

			-- Override tsserver diagnostics to filter out specific messages
			local messages_to_filter = {
				"This may be converted to an async function.",
				"'_Assertion' is declared but never used.",
				"'__Assertion' is declared but never used.",
				"The signature '(data: string): string' of 'atob' is deprecated.",
				"The signature '(data: string): string' of 'btoa' is deprecated.",
			}

			local function tsserver_on_publish_diagnostics_override(_, result, ctx, config)
				local filtered_diagnostics = {}

				for _, diagnostic in ipairs(result.diagnostics) do
					local found = false
					for _, message in ipairs(messages_to_filter) do
						if diagnostic.message == message then
							found = true
							break
						end
					end
					if not found then
						table.insert(filtered_diagnostics, diagnostic)
					end
				end

				result.diagnostics = filtered_diagnostics

				vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
			end

			-- Default handlers for LSP
			local default_handlers = {
				["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
				["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
			}

			-- Function to run when neovim connects to a Lsp client
			---@diagnostic disable-next-line: unused-local
			local on_attach = function(_client, buffer_number)
				-- Pass the current buffer to map lsp keybinds
				map_lsp_keybinds(buffer_number)

				-- Create a command `:Format` local to the LSP buffer
				--[[ vim.api.nvim_buf_create_user_command(buffer_number, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "LSP: Format current buffer with LSP" }) ]]
			end

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP Specification.
			--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			-- LSP servers to install (see list here: https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers )
			--  Add any additional override configuration in the following tables. Available keys are:
			--  - cmd (table): Override the default command used to start the server
			--  - filetypes (table): Override the default list of associated filetypes for the server
			--  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
			--  - settings (table): Override the default settings passed when initializing the server.
			--        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
			local servers_and_tools = {
				-- LSP Servers
				bashls = {},
				cssls = {},
				html = {},
				jsonls = {},
				lua_ls = {
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							workspace = {
								checkThirdParty = false,
								-- Tells lua_ls where to find all the Lua files that you have loaded
								-- for your neovim configuration.
								library = {
									"${3rd}/luv/library",
									unpack(vim.api.nvim_get_runtime_file("", true)),
								},
							},
							telemetry = { enabled = false },
						},
					},
				},
				marksman = {},
				nil_ls = {},
				pyright = {},
				sqlls = {},
				tailwindcss = {},
				tsserver = {
					settings = {
						maxTsServerMemory = 12000,
					},
					handlers = {
						["textDocument/publishDiagnostics"] = vim.lsp.with(
							tsserver_on_publish_diagnostics_override,
							{}
						),
					},
				},
				yamlls = {},

				-- Formatters
				prettierd = {},
				stylua = {},

				-- Linters
				eslint_d = {},
			}

			local ensure_installed = vim.tbl_keys(servers_and_tools)

			-- Setup mason so it can manage 3rd party LSP servers
			require("mason").setup({
				ui = {
					border = "rounded",
				},
			})

			-- Configure mason to auto install servers
			require("mason-tool-installer").setup({
				auto_update = true,
				run_on_start = true,
				start_delay = 3000,
				debounce_hours = 12,
				ensure_installed = ensure_installed,
			})

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers_and_tools[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for tsserver)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						server.on_attach = on_attach
						server.handlers = vim.tbl_deep_extend("force", {}, default_handlers, server.handlers or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})

			-- Configure borderd for LspInfo ui
			require("lspconfig.ui.windows").default_options.border = "rounded"

			-- Configure diagnostics border
			vim.diagnostic.config({
				float = {
					border = "rounded",
				},
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			notify_on_error = true,
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			formatters_by_ft = {
				javascript = { { "elint_d", "eslint" }, { "prettierd", "prettier" } },
				typescript = { { "elint_d", "eslint" }, { "prettierd", "prettier" } },
				lua = { "stylua" },
			},
		},
	},
}
