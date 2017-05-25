filetype plugin indent on

""""""""""""""""
" => Status Line
"""""""""""""""""

" Always show the status line
set laststatus=2

" Format the status line
set statusline+=\ %m%r%h\ \ 
set statusline+=\ path:\ [%{getcwd()}/%f]\ \  
set statusline+=\ type:\ %y\ \ 
set statusline+=%=
set statusline+=%<
set statusline+=\ char:\ [%c]\ \ 
set statusline+=\ line:\ [%l\ of\ %L,\ %3P]\ \ 
"set statusline+=\ :\ [%3P]\ \ 
set statusline+=%<
set statusline+=\ byte:\ %3b\ \ 
set statusline+=\ hex:\ 0x%2B\ \ 

"""""""""""
" => Indent
"""""""""""

" show existing tab with 4 spaces width
set tabstop=4

" when indenting with visual mode >, use 4 spaces width
set shiftwidth=4

" On pressing tab, insert 4 spaces
set expandtab

""""""""""""""""""""""
" => Colors and Fonts
""""""""""""""""""""""

set term=xterm-256color

" Enable syntax highlighting
syntax enable

try
    colorscheme desert
catch
endtry

set background=dark

" Line numbers
set number
highlight LineNr term=bold ctermfg=Red gui=bold guifg=Red
highlight CursorLineNr term=bold ctermfg=Yellow gui=bold guifg=Yellow

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

"""""""""""""""""""
" => User Interface
"""""""""""""""""""

" Wrap at 80 lines
set textwidth=80

" Properly show invisibles
set list listchars=tab:·\ ,trail:•

" Always show current position
set ruler

" Height of the command bar
set cmdheight=2

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" Highlight spelling mistakes
" set spell

" Mouse scrolling in a terminal
" Use [alt/option] to default back to terminal select
" set mouse=a
