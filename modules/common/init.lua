vim.cmd.colorscheme "gruvbox"

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
}

for k, v in pairs(options) do
	vim.go[k] = v
end

-- Completion look
vim.go.shortmess = vim.go.shortmess .. "c"

-- make = not considered as part of filenames
vim.cmd.set "isfname-=="

-- Netrw Tree
vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

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
	vim.api.nvim_create_autocmd('Filetype ' .. filetype, {
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
stdoutautocmd('rust', 'println!("<Esc>pa: {}", <Esc>pa);')
stdoutautocmd('c', 'printf("<Esc>pa: %s", <Esc>pa);')
stdoutautocmd('go', 'fmt.Printf("<Esc>pa: %v\\n", <Esc>pa)')
stdoutautocmd('lua', 'print("<Esc>pa:", <Esc>pa)')

-- LSP config
local lspconfig = require 'lspconfig'
lspconfig.nixd.setup {}

if steroids then
	vim.g.vim_markdown_folding_disabled = 1
	vim.g.vim_markdown_toc_autofit = 1

	-- LSP config
	lspconfig.gopls.setup {}
	lspconfig.bashls.setup {}
	lspconfig.ltex.setup {}
	lspconfig.rust_analyzer.setup {}

	lspconfig.html.setup {}
	lspconfig.jsonls.setup {}
	lspconfig.cssls.setup {}

	lspconfig.tailwindcss.setup {}
	lspconfig.svelte.setup {}

	lspconfig.lua_ls.setup { settings = {
		Lua = {
			runtime = { version = 'LuaJIT' },
			diagnostics = { globals = { 'vim' } }, -- recognize the `vim` global
			workspace = {                       -- aware of Neovim runtime files (long)
				library = vim.api.nvim_get_runtime_file("", true)
			},
			telemetry = { enable = false },
		}
	} }
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
