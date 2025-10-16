return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "pyright", "ruff", "tailwindcss" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Lua LSP
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
        root_dir = lspconfig.util.root_pattern(".git", "init.lua", ".luarc.json"),
      })

      -- TypeScript LSP
      lspconfig.ts_ls.setup({
        cmd = { "typescript-language-server", "--stdio" },
        root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", ".git"),
      })

      -- Pyright (disable some features b/c Ruff handles them)
      lspconfig.pyright.setup({
        capabilities = capabilities,
        settings = {
          pyright = {
            disableOrganizeImports = true, -- Ruff organizes imports
          },
          python = {
            analysis = {
              ignore = { "*" }, -- Ruff is handling linting
            },
          },
        },
      })

      -- Ruff
      lspconfig.ruff.setup({
        capabilities = capabilities,
        init_options = {
          settings = {
            logLevel = "info",
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
        end,
      })

      -- Disable Ruff's hover in favor of Pyright
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
        desc = "LSP: Disable hover capability from Ruff",
      })

      -- Autoformat on save
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = vim.api.nvim_create_augroup("LspFormat." .. args.buf, { clear = true }),
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = args.buf,
                  filter = function(c)
                    -- prefer certain servers per language
                    if vim.bo.filetype == "python" then
                      return c.name == "ruff"
                    elseif
                        vim.bo.filetype == "javascript"
                        or vim.bo.filetype == "typescript"
                        or vim.bo.filetype == "javascriptreact"
                        or vim.bo.filetype == "typescriptreact"
                    then
                      return c.name == "null-ls"
                    elseif vim.bo.filetype == "lua" then
                      return c.name == "lua_ls"
                    end
                    return true
                  end,
                })
              end,
            })
          end
        end,
      })

      -- Tailwindcss
      lspconfig.tailwindcss.setup({
        capabilities = capabilities,
        filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "svelte", "vue", "astro" },
        root_dir = lspconfig.util.root_pattern("package.json", ".git"),
      })
    end,
  },
}
