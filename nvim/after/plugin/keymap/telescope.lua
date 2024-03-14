local Remap = require("ivan.keymap")
local nnoremap = Remap.nnoremap
local builtin = require("telescope.builtin")

nnoremap("ff", builtin.find_files, {})
nnoremap("fg", builtin.live_grep, {})
nnoremap("fh", builtin.help_tags, {})
nnoremap("fb", ":Telescope git_branches<CR>")
nnoremap("fs", ":Telescope luasnip<CR>")
nnoremap("fd", ":Telescope git_status<CR>")
