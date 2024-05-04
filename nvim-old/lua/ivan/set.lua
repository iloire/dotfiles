vim.cmd("colorscheme gruvbox")

global = vim.g
options = vim.opt

global.mapleader = " "

options.guicursor="n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

options.nu = true
options.relativenumber = true

options.errorbells = false

options.autoindent = true
options.tabstop = 2
options.softtabstop = 2
options.shiftwidth = 2
options.expandtab = true
options.ignorecase = true
options.mouse = "a"                             -- allow the mouse to be used in neovim
options.showtabline = 2                         -- always show tabs
options.smartindent = true
options.list = true
options.wrap = false

options.swapfile = false
options.backup = false

options.hlsearch = false
options.incsearch = true

options.termguicolors = true

options.scrolloff = 15
options.signcolumn = "yes"
options.isfname:append("@-@")

-- Give more space for displaying messages.
options.cmdheight = 1

-- Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
-- delays and poor user experience.
options.updatetime = 50

-- Don't pass messages to |ins-completion-menu|.
options.shortmess:append("c")

options.colorcolumn = "80"

