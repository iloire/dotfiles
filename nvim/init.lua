require("ivan.packer")
require("ivan.set")
require("ivan.telescope")
require("ivan.feline")
require("ivan.bufferline")
require("ivan.autocmd")

require("luasnip/loaders/from_vscode").lazy_load()
require("ivan.snippets.all")

require('nvim_comment').setup()
require("mason").setup()
require'lspconfig'.pyright.setup{}

-- Set up lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
require('lspconfig')['pyright'].setup {
  capabilities = capabilities
}
