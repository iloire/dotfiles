local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function() -- Packer can manage itself
    use("wbthomason/packer.nvim") -- packer itself

    use("nvim-lua/plenary.nvim") -- required by telescope
    use("nvim-telescope/telescope.nvim")
    use("theprimeagen/harpoon")

    -- parsing library for source code
    use("nvim-treesitter/nvim-treesitter", {
        run = ":TSUpdate"
    })
    use({
      "glepnir/lspsaga.nvim",
      branch = "main",
      config = function()
          require("lspsaga").setup({})
      end,
      requires = {
          {"nvim-tree/nvim-web-devicons"},
          --Please make sure you install markdown and markdown_inline parser
          {"nvim-treesitter/nvim-treesitter"}
      }
    })
    use("gruvbox-community/gruvbox")
    use("sbdchd/neoformat")

    use("neovim/nvim-lspconfig")

    -- Autocompletion framework
    use("hrsh7th/nvim-cmp")
    use({
        -- cmp LSP completion
        "hrsh7th/cmp-nvim-lsp",
        -- cmp Snippet completion
        "hrsh7th/cmp-vsnip",
        -- cmp Path completion
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-buffer",
        after = { "hrsh7th/nvim-cmp" },
        requires = { "hrsh7th/nvim-cmp" },
    })

    use("L3MON4D3/LuaSnip")
    use("rafamadriz/friendly-snippets")
    use("saadparwaiz1/cmp_luasnip")

    use("terrortylor/nvim-comment") -- commenting plugin

    -- tree explorer
    use("nvim-tree/nvim-web-devicons")
    use("nvim-tree/nvim-tree.lua")

    use("Yggdroot/indentLine")
    use("folke/which-key.nvim")

    -- A snazzy 💅 buffer line (with tabpage integration) for Neovim built using lua.
    use {"akinsho/bufferline.nvim", tag = "*", requires = "kyazdani42/nvim-web-devicons"}

    -- A minimal, stylish and customizable statusline / winbar for Neovim written in Lua
    use("feline-nvim/feline.nvim")
    use("williamboman/mason.nvim") -- easily install and manage LSP servers, DAP servers, linters, and formatters.

    -- git
    use("lewis6991/gitsigns.nvim")
    use("tpope/vim-fugitive")
    use("kdheepak/lazygit.nvim")

    use("tpope/vim-surround")

    -- language specific
    use("simrat39/rust-tools.nvim")
    use("ellisonleao/glow.nvim") -- markdown

    use("windwp/nvim-autopairs")

    if packer_bootstrap then
        require('packer').sync()
    end
end)
