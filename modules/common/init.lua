local options = {
	number = true,
	termguicolors = true,
	-- Save changes in swapfile
	updatetime = 100,
	-- Open new split panes to right and below
	splitright = true,
	splitbelow = true,
	-- Terminal Title
	title = true,
	-- Completion look
	completeopt = "noinsert,menuone,noselect",

	-- Keep n lines between the cursor and the edge of the screen
	scrolloff = 3,

	-- Make macros complete faster
	lazyredraw = true,

	-- Insensitive search
	smartcase = true,
	-- Insensitive search in command mode for files and directories
	wildignorecase = true,
	ignorecase = true,

	-- Show in real time what :s will do
	inccommand = "nosplit",
	-- Show the match when closing brackets
	showmatch = true,

	-- Do not break words
	linebreak = true,

	-- PaperColor/gruvbox light theme
	-- background = "light"
}

for k, v in pairs(options) do
	vim.o[k] = v
end

vim.cmd.colorscheme "gruvbox"
-- vim.cmd.colorscheme "PaperColor"
-- vim.cmd.highlight("Normal guibg=NONE ctermbg=NONE")

-- Completion look
vim.go.shortmess = vim.go.shortmess .. "c"

-- make = not considered as part of filenames
vim.cmd.set "isfname-=="

-- Netrw Tree
vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- Far
vim.g["far#source"] = "rg"
vim.g["far#glob_mode"] = "native"
vim.g['far#enable_undo'] = 1
vim.g['far#auto_preview'] = 0

-- Show space line endings
vim.cmd.match([[WarningMsg /\s\+$/]])

-- Highlight yanks
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		-- silent!
		vim.highlight.on_yank { on_visual = false }
	end,
	group = vim.api.nvim_create_augroup('yank_conf', { clear = true })
})

vim.api.nvim_create_user_command("RemoveTrailingSpaces", [[%s/\s\+$//]], { force = true })
vim.api.nvim_create_user_command("ReplaceAllSpaces", [[%s/ /./g]], { force = true })
vim.api.nvim_create_user_command("ReplaceAllPuncts", [[%s/[ \-\[\]()'"_.]\+/./g]], { force = true })
vim.api.nvim_create_user_command("TrimDots", [[%s/\.\././g]], { force = true })

-- Terminal Configuration
vim.keymap.set('t', '²', [[<C-\><C-n>]], {})
vim.api.nvim_create_autocmd('TermOpen', {
	callback = function()
		vim.bo.nonu = true
		vim.cmd.startinsert()
	end,
	group = vim.api.nvim_create_augroup('terminal_conf', { clear = true })
})

-- map ù to /log what's under the cursor/
local stdout = vim.api.nvim_create_augroup('stdout', { clear = true })
local stdoutautocmd = function(filetype, text)
	vim.api.nvim_create_autocmd('Filetype', {
		pattern = filetype,
		callback = function()
			vim.keymap.set('n', 'ù', 'yiwo' .. text .. '<esc>')
			vim.keymap.set('v', 'ù', 'yo' .. text .. '<esc>')
		end,
		group = stdout
	})
end
stdoutautocmd('python', 'print(f"<Esc>pa: {<Esc>pa}")')
stdoutautocmd('fish', 'echo <Esc>pa: $<Esc>p')
stdoutautocmd('java', 'System.out.println("<Esc>pa:" + <Esc>pa);')
stdoutautocmd('javascript', 'console.log("<Esc>pa:", <Esc>pa);')
stdoutautocmd('typescript', 'console.log("<Esc>pa:", <Esc>pa);')
stdoutautocmd('rust', 'dbg!(<Esc>pa);')
stdoutautocmd('c', 'printf("<Esc>pa: %s", <Esc>pa);')
stdoutautocmd('go', 'fmt.Printf("<Esc>pa: %v\\n", <Esc>pa)')
stdoutautocmd('lua', 'print("<Esc>pa:", <Esc>pa)')

vim.api.nvim_create_autocmd('Filetype', {
	pattern = "markdown",
	callback = function()
		vim.keymap.set('n', 'o', 'A<cr>')
		vim.keymap.set('n', 'O', 'kA<cr>')
	end,
	group = vim.api.nvim_create_augroup('md:fix-o-bug', { clear = true })
})

-- LSP config

if steroids or enableGo or enableNixd then
	-- nvim_lspconfig
	-- See `:help vim.diagnostic.*` for documentation on any of the below functions
	vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
	vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
	vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
	vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

	local lspgroup = vim.api.nvim_create_augroup('UserLspConfig', { clear = true })

	-- Use LspAttach autocommand to only map the following keys
	-- after the language server attaches to the current buffer
	vim.api.nvim_create_autocmd('LspAttach', {
		group = lspgroup,
		callback = function(ev)
			-- Enable completion triggered by <c-x><c-o>
			vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

			local client = vim.lsp.get_client_by_id(ev.data.client_id)

			-- Format on save
			vim.api.nvim_create_user_command('W', function()
				vim.lsp.buf.format()
				vim.cmd("w")
			end, { force = true })

			--[[
			if client.server_capabilities.documentFormattingProvider then
				vim.api.nvim_create_autocmd('BufWritePre', {
					callback = function()
						vim.lsp.buf.format()
					end,
					group = lspgroup,
					buffer = ev.buf,
				})
			end
			]]

			-- Buffer local mappings.
			-- See `:help vim.lsp.*` for documentation on any of the below functions
			local opts = { buffer = ev.buf }
			vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
			vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
			vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
			vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
			vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
			vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
			vim.keymap.set('n', '<space>wl', function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, opts)
			vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
			vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
			vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
			vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
			vim.keymap.set('n', '<space>f', function()
				vim.lsp.buf.format { async = true }
			end, opts)
		end,
	})

	if enableNixd then
		vim.lsp.enable('nixd')
	end

	if enableGo then
		vim.api.nvim_create_autocmd('FileType',
			{
				pattern = 'go',
				group = vim.api.nvim_create_augroup('gotab', { clear = true }),
				command = "set tabstop=4 shiftwidth=4 softtabstop=-1"
			})

		vim.lsp.enable('gopls')
	end

	if steroids then
		vim.g.vim_markdown_folding_disabled = 1
		vim.g.vim_markdown_toc_autofit = 1

		-- LSP config
		vim.lsp.enable('bashls')
		vim.lsp.enable('ccls')
		vim.lsp.enable('cssls')
		vim.lsp.enable('html')
		vim.lsp.enable('jsonls')
		vim.lsp.enable('jsonnet_ls')
		-- vim.lsp.enable('ltex')
		-- vim.lsp.enable('pylizer')
		vim.lsp.enable('ruff')
		vim.lsp.enable('rust_analyzer')
		vim.lsp.enable('svelte')
		vim.lsp.enable('tailwindcss')
		vim.lsp.enable('denols')
		-- vim.lsp.enable('ts_ls')
		vim.lsp.enable('vuels')
		vim.lsp.enable('yamlls')

		vim.lsp.config('lua_ls', {
			settings = {
				Lua = {
					runtime = { version = 'LuaJIT' },
					diagnostics = { globals = { 'vim' } }, -- recognize the `vim` global
					workspace = { -- aware of Neovim runtime files (long)
						library = vim.api.nvim_get_runtime_file("", true)
					},
					telemetry = { enable = false },
				}
			}
		})
		vim.lsp.enable('lua_ls')
	end
end

local source_if_exists = function(filename)
	local file_exists = function(filename)
		local f = io.open(filename, "r")
		if f ~= nil then
			io.close(f)
			return true
		else
			return false
		end
	end
	local filename = vim.fs.normalize(filename)
	if file_exists(filename) then
		vim.cmd.source(filename)
	end
end
source_if_exists "~/.config/nvim/init.lua"
