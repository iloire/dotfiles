set nocompatible
set exrc "customizations
set background=dark
set nohlsearch
set nu
set relativenumber
set nowrap
set formatoptions=tcqrn1
set tabstop=4 softtabstop=4
set expandtab
set smartindent
set shiftwidth=4
set noswapfile
set nobackup
set undofile
set undodir=/.vim/undodir
set noshiftround
set incsearch
set scrolloff=12
set colorcolumn=80
set signcolumn=yes
set titlestring=%t
set updatetime=50
set backspace=indent,eol,start
set matchpairs+=<:> " use % to jump between pairs

highlight Normal guibg=none

function! JournalMode()
  execute 'normal gg'
  let filename = '#' . ' ' . expand('%:r')
  call setline(1, filename)
endfunction

augroup vimrcEx
  au!
  "autocmd FileType text setlocal textwidth=78
  "autocmd VimEnter * NERDTree
augroup END

augroup journal
  autocmd!
" Cursor motion
  autocmd VimEnter */journal/**   :call JournalMode()

  " not that useful as it messes with the break lines (to fix)
  "autocmd VimEnter */journal/**   0r ~/.vim/templates/journal.skeleton
augroup end

" Commenting blocks of code.
augroup commenting_blocks_of_code
  autocmd!
  autocmd FileType c,cpp,java,scala let b:comment_leader = '// '
  autocmd FileType sh,ruby,python   let b:comment_leader = '# '
  autocmd FileType conf,fstab       let b:comment_leader = '# '
  autocmd FileType tex              let b:comment_leader = '% '
  autocmd FileType mail             let b:comment_leader = '> '
  autocmd FileType vim              let b:comment_leader = '" '
augroup END

noremap <silent> ,cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> ,cu :<C-B>silent <C-E>s/^\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'prettier/vim-prettier', { 'do': 'yarn install --frozen-lockfile --production' }
Plug 'preservim/nerdtree'
Plug 'gruvbox-community/gruvbox'
call plug#end()

colorscheme gruvbox

runtime! macros/matchit.vim

let NERDTreeShowHidden=1
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"

syntax on

filetype on
filetype plugin on
filetype indent on

nnoremap <C-y> "+y
vnoremap <C-y> "+y
nnoremap <C-p> "+gP
vnoremap <C-p> "+g
