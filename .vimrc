filetype off                  " required
set clipboard=unnamedplus
set number
set nocompatible              " be iMproved, required
set hlsearch
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'valloric/youcompleteme'
let g:ycm_enable_diagnostic_signs = 0
let g:ycm_enable_diagnostic_highlighting = 0
set completeopt-=preview

Plugin 'bfrg/vim-cpp-modern'

Plugin 'scrooloose/nerdtree'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
Plugin 'xuyuanp/nerdtree-git-plugin'
let g:NERDTreeGitStatusShowClean = 1

Plugin 'vim-airline/vim-airline'

Plugin 'jiangmiao/auto-pairs'

Plugin 'tpope/vim-commentary'

Plugin 'Chiel92/vim-autoformat'
"au BufWrite * :Autoformat

call vundle#end()            " required
" To ignore plugin indent changes, instead use:
filetype plugin indent on    " required
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

colorscheme pablo
set expandtab tabstop=4
set tabstop=4
set shiftwidth=4

set foldenable
imap <A-Up> <Esc>VdkPe
nmap <A-Up> VdkP
vmap <A-Up> dkP
imap <A-Down> <Esc>VdjPe
nmap <A-Down> VdjP
vmap <A-Down> djP
map e i
map E I
imap <C-e> <Esc>
vmap <C-e> <Esc>
map <A-Left> gT
map <A-Right> gt
imap <A-Left> <Esc>gTe
imap <A-Right> <Esc>gte
command -nargs=1 FindReplace :%s/<args>/g
cnoreabbrev t tabnew
