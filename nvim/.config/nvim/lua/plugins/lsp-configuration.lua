return {

  -- ============================================================
  -- MASON.NVIM
  -- Mason is a package manager that runs inside Neovim.
  -- It downloads and installs language servers, formatters, and
  -- linters (e.g. typescript-language-server, lua-language-server)
  -- and puts them somewhere Neovim can find them.
  -- It has no knowledge of LSP config itself — it just installs
  -- the executables. Think of it like brew/apt but for editor tooling.
  -- ============================================================
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },

  -- ============================================================
  -- MASON-LSPCONFIG.NVIM
  -- Mason and nvim-lspconfig use different naming conventions for
  -- the same servers (e.g. Mason calls it "lua-language-server",
  -- lspconfig calls it "lua_ls"). This plugin bridges that gap.
  --
  -- ensure_installed: a list of servers (using lspconfig names)
  -- that Mason will auto-install if they are missing when you
  -- open Neovim. You never have to manually run :MasonInstall.
  -- ============================================================
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "pyright",
          "ruff",
          "tailwindcss",
        },
      })
    end,
  },

  -- ============================================================
  -- NVIM-LSPCONFIG
  -- This plugin is a community-maintained library of pre-written
  -- server definitions — it knows the launch command, filetypes,
  -- and root detection patterns for hundreds of language servers.
  --
  -- IMPORTANT: lspconfig is NOT the LSP client. Neovim itself is
  -- the LSP client (vim.lsp.*). lspconfig is just a data provider.
  --
  -- AS OF NEOVIM 0.11, the old API:
  --   require("lspconfig").lua_ls.setup({ ... })
  -- is DEPRECATED. It used to handle both config AND activation.
  --
  -- The new API separates those two responsibilities:
  --   vim.lsp.config("server", { ... })  -- define/override options
  --   vim.lsp.enable({ "server", ... })  -- actually activate them
  --
  -- vim.lsp.config and vim.lsp.enable are built into Neovim itself,
  -- not lspconfig. We still require("lspconfig") so it can register
  -- its server definitions (commands, filetypes, etc.) into Neovim's
  -- runtime — we just don't use .setup() anymore.
  -- ============================================================
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      -- Requiring lspconfig here causes it to register all of its
      -- built-in server definitions into Neovim's LSP system.
      -- Without this line, vim.lsp.enable("lua_ls") wouldn't know
      -- what command to run or what filetypes to activate on.
      -- We intentionally do NOT call lspconfig.server.setup() anywhere.
      require("lspconfig")

      -- ============================================================
      -- STEP 1: GLOBAL CAPABILITIES
      --
      -- "Capabilities" is a table that your editor (the LSP client)
      -- sends to the language server when connecting, declaring what
      -- features it supports — completions, hover, formatting, etc.
      --
      -- Neovim's default capabilities are fairly basic. nvim-cmp is
      -- your autocompletion plugin, and cmp_nvim_lsp extends the
      -- default capabilities to tell servers "this client supports
      -- richer completion data", so servers send back more detail.
      --
      -- Passing "*" as the server name sets these as the DEFAULT
      -- for ALL servers, so you don't have to repeat it per-server.
      -- ============================================================
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })

      -- ============================================================
      -- STEP 2: PER-SERVER CONFIGURATION
      --
      -- vim.lsp.config() lets you override specific options for a
      -- named server. These are merged on top of lspconfig's built-in
      -- defaults for that server, so you only need to specify what
      -- you want to change or add.
      --
      -- root_dir: a function that receives the buffer number and
      -- returns the project root path. vim.fs.root() walks up the
      -- directory tree from the current file and returns the first
      -- directory that contains any of the listed marker files/folders.
      -- This replaced the old lspconfig.util.root_pattern() in the
      -- new API — same concept, built into Neovim itself.
      -- ============================================================

      -- LUA
      -- lua_ls is the official Lua language server. Without the
      -- settings below it would throw errors all over your Neovim
      -- config because it doesn't know about Neovim's "vim" global
      -- or the Neovim runtime libraries.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              -- "vim" is a global injected by Neovim into the Lua
              -- environment. Without this, lua_ls flags every use
              -- of vim.* as an "undefined global" error.
              globals = { "vim" },
            },
            workspace = {
              -- Makes lua_ls aware of all Neovim runtime Lua files
              -- so it can understand vim.* APIs, provide completions
              -- for them, and not show "undefined field" warnings.
              library = vim.api.nvim_get_runtime_file("", true),
              -- Prevents lua_ls from asking "do you want to configure
              -- your work environment?" every time you open a file.
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
        root_dir = function(bufnr)
          return vim.fs.root(bufnr, { ".git", "init.lua", ".luarc.json" })
        end,
      })

      -- TYPESCRIPT / JAVASCRIPT
      -- ts_ls is the TypeScript language server. The cmd field tells
      -- Neovim the exact shell command used to launch the server process.
      -- lspconfig already knows this default, but it's kept here
      -- explicitly for clarity.
      vim.lsp.config("ts_ls", {
        cmd = { "typescript-language-server", "--stdio" },
        root_dir = function(bufnr)
          return vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" })
        end,
      })

      -- PYTHON — PYRIGHT
      -- Pyright handles type checking for Python. Ruff (below) handles
      -- linting and import sorting, so we disable those features in
      -- Pyright to prevent them from conflicting/duplicating.
      vim.lsp.config("pyright", {
        settings = {
          pyright = {
            -- Ruff organizes imports faster and better, so we tell
            -- Pyright to stay out of that lane entirely.
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              -- "basic" type checking catches common errors without
              -- being as strict as "strict" mode.
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      -- PYTHON — RUFF
      -- Ruff is a modern Python linter and formatter written in Rust.
      -- It replaces flake8, isort, and large parts of black all in one
      -- tool. It runs alongside Pyright — Pyright does type checking,
      -- Ruff does linting and formatting.
      vim.lsp.config("ruff", {
        init_options = {
          settings = {
            logLevel = "info",
          },
        },
      })

      -- TAILWIND CSS
      -- filetypes overrides the default list of filetypes this server
      -- activates on, extending it to cover JSX, TSX, Svelte, etc.
      vim.lsp.config("tailwindcss", {
        filetypes = {
          "html",
          "css",
          "scss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "svelte",
          "vue",
          "astro",
        },
        root_dir = function(bufnr)
          return vim.fs.root(bufnr, { "package.json", ".git" })
        end,
      })

      -- ============================================================
      -- STEP 3: ENABLE SERVERS
      --
      -- vim.lsp.config() only stores configuration — it does NOT
      -- start any servers. vim.lsp.enable() is what actually tells
      -- Neovim to activate these servers and connect them to buffers
      -- when the appropriate filetypes are opened.
      --
      -- This is the key difference from the old API, where .setup()
      -- did both configuration and activation in one call.
      -- ============================================================
      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "pyright",
        "ruff",
        "tailwindcss",
      })

      -- ============================================================
      -- STEP 4: KEYMAPS
      --
      -- LspAttach is a Neovim event that fires every time a language
      -- server successfully connects to a buffer (an open file).
      --
      -- We use an autocommand on this event to set keymaps scoped
      -- to that specific buffer ({ buffer = ev.buf }), meaning these
      -- keys only work in files where an LSP is active — they won't
      -- shadow your normal keymaps in plain text files, etc.
      --
      -- nvim_create_augroup gives this group of autocommands a name
      -- and clear = true ensures it's not re-registered every time
      -- you source your config, which would cause duplicate execution.
      -- ============================================================
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
        callback = function(ev)
          local opts = { buffer = ev.buf }

          -- NAVIGATION
          -- Jump to where the symbol under cursor is defined
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          -- Jump to where the symbol is declared. In most languages this
          -- is the same as definition. Most relevant in C/C++ where a
          -- function can be declared in a header and defined elsewhere.
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          -- Jump to where an interface or abstract method is actually
          -- implemented. Useful in TypeScript/Python when you're on an
          -- interface method and want to see the concrete class that
          -- implements it.
          vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
          -- Jump to the definition of the TYPE of the symbol, not the
          -- symbol itself. e.g. if cursor is on a variable "user", this
          -- jumps to the "User" type/interface definition.
          vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
          -- List every place the symbol under cursor is referenced across
          -- your project in a quickfix window
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

          -- INFORMATION
          -- Show documentation/type info for symbol under cursor in a
          -- floating window. Press K again to move focus into the float
          -- so you can scroll it.
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          -- Show the parameter signature of the function you are currently
          -- typing arguments into. Useful when you forget argument order.
          -- Triggered in insert mode while inside the parentheses.
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)

          -- SYMBOLS
          -- List all symbols (functions, classes, variables, etc.) in the
          -- current file. Opens in a quickfix/picker window.
          vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol, opts)
          -- Search for any symbol across the entire project/workspace.
          -- You'll be prompted to type a query.
          vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)

          -- CALL HIERARCHY
          -- Show all the places in your codebase that call the function
          -- under your cursor
          vim.keymap.set("n", "<leader>ci", vim.lsp.buf.incoming_calls, opts)
          -- Show all the functions that the function under your cursor
          -- calls internally
          vim.keymap.set("n", "<leader>co", vim.lsp.buf.outgoing_calls, opts)

          -- REFACTORING
          -- Show code actions the LSP is offering: quick fixes, auto-imports,
          -- extract variable/function, etc.
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          -- Rename the symbol under cursor everywhere it is used across
          -- the whole project
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

          -- DIAGNOSTICS
          -- Open the full diagnostic message for the current line in a
          -- floating window (useful when the inline text is truncated)
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          -- Dump all diagnostics for the current file into a location list
          -- window at the bottom — lets you see all errors at once and
          -- navigate between them
          vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
        end,
      })

      -- ============================================================
      -- DISABLE RUFF HOVER IN FAVOR OF PYRIGHT
      --
      -- On Python files, both Pyright and Ruff attach simultaneously.
      -- Both are capable of responding to the K (hover) keymap.
      -- Ruff's hover is minimal; Pyright's is much richer with full
      -- type information and documentation.
      --
      -- When Ruff attaches, we reach into its server_capabilities
      -- table (which the server sends on connection to declare what
      -- features it supports) and flip hoverProvider to false.
      -- Neovim then knows not to route hover requests to Ruff.
      -- ============================================================
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspDisableRuffHover", { clear = true }),
        desc = "LSP: Disable hover capability from Ruff",
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })

      -- ============================================================
      -- AUTOFORMAT ON SAVE
      --
      -- Outer autocmd: runs on LspAttach to check if the server that
      -- just connected supports document formatting. Only if it does
      -- do we bother setting up the BufWritePre handler for that buffer.
      --
      -- Inner autocmd: BufWritePre fires just before a buffer is
      -- written to disk. We use it to call vim.lsp.buf.format(), which
      -- sends a formatting request to the LSP server and applies edits.
      --
      -- The per-buffer augroup name ("LspFormat." .. args.buf) is a
      -- trick to make the augroup unique per buffer, so that when
      -- multiple servers attach to the same buffer, registering the
      -- BufWritePre handler again clears the previous one cleanly
      -- instead of stacking up duplicate format calls.
      -- ============================================================
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client and client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = vim.api.nvim_create_augroup(
                "LspFormat." .. args.buf,
                { clear = true }
              ),
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({
                  bufnr = args.buf,
                  -- filter() is called once per attached server that
                  -- supports formatting. Return true to allow that
                  -- server to format, false to skip it. This lets you
                  -- pick exactly one server per filetype when multiple
                  -- are running, preventing conflicting edits.
                  filter = function(c)
                    if vim.bo.filetype == "python" then
                      -- Ruff formats Python (replaces black + isort)
                      return c.name == "ruff"
                    elseif
                        vim.bo.filetype == "javascript"
                        or vim.bo.filetype == "typescript"
                        or vim.bo.filetype == "javascriptreact"
                        or vim.bo.filetype == "typescriptreact"
                    then
                      return c.name == "null-ls"
                    elseif vim.bo.filetype == "lua" then
                      return c.name == "null-ls"
                    end

                    -- For any filetype not listed above, allow whichever
                    -- server claims it can format to go ahead.
                    return true
                  end,
                })
              end,
            })
          end
        end,
      })
    end,
  },
}
