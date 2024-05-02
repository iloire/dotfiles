require("ivan.packer")
require("ivan.set")
require("ivan.telescope")
require("ivan.feline")
require("ivan.bufferline")
require("ivan.autocmd")
require("ivan.nvimtree")

-- snippets
require("luasnip").filetype_extend("javascriptreact", { "html" })
require('luasnip').filetype_extend("typescriptreact", { "html" })
require("luasnip/loaders/from_vscode").lazy_load()
require("ivan.snippets.index")

require('nvim_comment').setup()
require("mason").setup()

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
require('lspconfig')['pyright'].setup {
  capabilities = capabilities
}
