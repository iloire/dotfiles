local Remap = require("ivan.keymap")
local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local xnoremap = Remap.xnoremap
local nmap = Remap.nmap

-- next greatest remap ever : asbjornHaland
nnoremap("<leader>y", "\"+y")
vnoremap("<leader>y", "\"+y")
nmap("<leader>Y", "\"+Y")

--- Navigate buffers
nnoremap(")", ":bnext<CR>")
nnoremap("(", ":bprevious<CR>")
nnoremap("<bs>", "<c-^>")

nnoremap("L", "$")
nnoremap("H", "^")
nnoremap("J", "<C-d>")
nnoremap("K", "<C-u>")

-- Insert --
-- Press jk fast to enter
inoremap("jk", "<ESC>")
inoremap("jf", "<ESC>")

nnoremap(";", "<C-w>h")
nnoremap("'", "<C-w>l")
nnoremap("_", "<C-w>w")

-- nvim tree toggle
nnoremap("<leader>e", ":NvimTreeToggle<CR>")

nnoremap("<leader>w", ":w<CR>")
nnoremap("<leader>q", ":q<CR>")

nnoremap("U","<C-R>") -- redo

nnoremap("<leader>x", "*``cgn")

nnoremap("<c-cr>","i<cr><Esc>")

-- Don't use arrow keys
nnoremap("<up>","<nop>")
nnoremap("<down>","<nop>")
nnoremap("<left>","<nop>")
nnoremap("<right>","<nop>")

nnoremap("QQ", ":q!<CR>")
nnoremap("qq", ":q!<CR>")
