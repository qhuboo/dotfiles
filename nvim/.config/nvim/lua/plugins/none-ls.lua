return {
	-- ============================================================
	-- NONE-LS (formerly null-ls)
	-- none-ls is a bridge that lets non-LSP tools (formatters,
	-- linters) plug into Neovim's LSP client as if they were real
	-- language servers. This means they work with the same
	-- vim.lsp.buf.format() call and the same diagnostic system as
	-- your real language servers.
	--
	-- Sources are the individual tools plugged in:
	--   formatting sources  — called when you format a buffer
	--   diagnostic sources  — called to provide error/warning info
	-- ============================================================
	{
		"nvimtools/none-ls.nvim",
		dependencies = {
			"nvimtools/none-ls-extras.nvim",
		},
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {
					-- STYLUA: Lua formatter. Formats .lua files according to
					-- a stylua.toml config if present, otherwise uses defaults.
					-- Handles Lua instead of lua_ls so formatting is consistent
					-- and separate from the language server's other responsibilities.
					null_ls.builtins.formatting.stylua,

					-- PRETTIER: Formatter for JS, TS, JSX, TSX, CSS, HTML, JSON,
					-- Markdown and more. The industry standard for web projects.
					-- Reads your .prettierrc config file if one exists in the project.
					null_ls.builtins.formatting.prettier,

					-- ESLINT_D: Runs ESLint as a long-lived background process
					-- ("_d" = daemon) rather than spinning up a new Node process
					-- on every check. Provides linting diagnostics (errors/warnings)
					-- for JS/TS files based on your .eslintrc config.
					-- NOTE: must be installed via Mason — see mason-null-ls below.
					require("none-ls.diagnostics.eslint_d").with({
						condition = function()
							return vim.fn.executable("eslint_d") == 1
						end,
					}),
				},
			})
		end,
	},

	-- ============================================================
	-- MASON-NULL-LS
	-- The same way mason-lspconfig bridges Mason and nvim-lspconfig
	-- for language servers, mason-null-ls bridges Mason and none-ls
	-- for formatters and linters.
	--
	-- ensure_installed: these tools will be auto-installed by Mason
	-- if they are missing when you open Neovim — same behavior as
	-- the ensure_installed list in mason-lspconfig.
	--
	-- automatic_installation = true means if you add a none-ls source
	-- above that Mason knows about, it will be installed automatically
	-- without you needing to add it to ensure_installed manually.
	-- ============================================================
	{
		"jay-babu/mason-null-ls.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
		config = function()
			require("mason-null-ls").setup({
				ensure_installed = {
					"stylua", -- Lua formatter
					"prettier", -- JS/TS/CSS/HTML formatter
					"eslint_d", -- JS/TS linter
				},
				automatic_installation = true,
			})
		end,
	},
}
