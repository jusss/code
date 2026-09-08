"autocomplete supertab, indent tab, highlight build-in, comment keybind, F5-run keybind"
set nocompatible
set autoindent
filetype on
filetype indent on
filetype plugin on
filetype plugin indent on
"there's no space in options or parameters, otherwise, it will be errors"
"encoding error, set fileencoding and reload, not set encoding"
"vim character override issue, caught by default ~/.bashrc, delete it and touch new ~/.bashrc will be fine"
set number
"set cursorline"
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,utf-8-bom,ucs-bom,cp936,big5,gbk,utf-16,utf-16le
set termencoding=utf-8
set fileformats=unix,dos
set expandtab
set shiftwidth=4
set tabstop=4
" use system clipboard for copy and paste, y and p, need +clipboard or
" +xterm_clipboard, compile it or install vim-gtk not vim-tiny
" https://vim.fandom.com/wiki/Accessing_the_system_clipboard
set clipboard^=unnamed,unnamedplus
"colorscheme happy_hacking"
"colorscheme github"
syntax on
set hidden
"disable macro recording"
map q <Nop>
"F5 run"
let current_filename = expand('%:t')
if stridx(current_filename,'.hs') > 0
    nnoremap <F5> <esc>:w<enter>:!runghc %:p<enter>
    inoremap <F5> <esc>:w<enter>:!runghc %:p<enter>
elseif stridx(current_filename, '.py') > 0
    nnoremap <F5> <esc>:w<enter>:!python3 %:p<enter>
    inoremap <F5> <esc>:w<enter>:!python3 %:p<enter>
"else
    "echom 'unsupport'
endif

"nnoremap <C-r> <esc>:w<enter>:!runghc %:p<enter>"
"inoremap <C-r> <esc>:w<enter>:!runghc %:p<enter>"

"avoid Press ENTER or type command to continue"
set shortmess+=F

"vim scp://root@moon:22//root/a.hs"
"if the only one slash, it means $HOME path, directory end with /, and use :Ex
"to back directory after view file "
"so vim scp://root@moon:22/a.hs, is /root/a.hs on remote"
"nnoremap <F6> <esc>:w<enter>:!ssh root@moon runghc /root/%:t<enter>"
"inoremap <F6> <esc>:w<enter>:!ssh root@moon runghc /root/%:t<enter>"

"vim scp://leo@moon/~/a.hs"
"could be vim scp://leo@moon/a.hs"
nnoremap <F6> <esc>:w<enter>:!ssh leo@moon runghc /home/leo/%:t<enter>
inoremap <F6> <esc>:w<enter>:!ssh leo@moon runghc /home/leo/%:t<enter>

"also you can set :let $PRO="scp://root@moon:22"
"then :tabe $PRO/a.hs"

"about the port you can do it in .ssh/config"
"Host moon"
" HostName ip"
" User root"
" IdentityFile ~/.ssh/id_rsa"
" Port port"

"write this into ~/.ssh/config"
"ServerAliveInterval 120"
"ControlPersist 2h"
"ControlMaster auto"
"ControlPath ~/.ssh/master-%r@%h:%p"
"then create the connection, with ssh -p 22 -N root@moon"
"now vim scp://root@moon:22/a.hs will be very fast"

"install supertab for auto-complete"
":vsplit, :hsplit"
"move in split windows with C-l"
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l
" when pop menu, candidate is the first, press Enter will not complete and just newline, selected == 0 is the first candidate, -1 is not choose, complete_info need vim8.2"
" pumvisible is true if there is a pop up menu"
" inoremap <expr> <CR> pumvisible() ? (complete_info().selected == -1 ? '<C-e><CR>' : '<CR>') : '<CR>'

set undofile
set undodir=$HOME/.cache/

"command mode, C-d back to shell, C-d in shell back to vim"
noremap <C-d> :sh<CR>

" C-/ to comment or uncomment, nerdcommenter plugin"
" leader key may be \, so \ c space will do the same
" in iPadOS C-/ won't be recognized, it only recognize alphabet character, so
" use C-l to instead of C-/

" use :%s/\<old\>/new/g to replace variable, g mean multiple in one line"
" c mean confirm if come with g, % mean all line, \<old\> start and end only with old"
" or on the old, press * will fully match, :%s//new/g"
" // will replace the last search by * # or /"
" or V/old:s//new/g, search old in a block then replace"
" vimrc use . to concate string"
function! Rename()
  let new = input('New name: ')
  execute '%s//'.new.'/g'
endfunction

" use * match variable, press F3 to rename them all"
nnoremap <F3> :call Rename()<CR>

" Uncomment the following to have Vim jump to the last position when reopening a file"
if has("autocmd")
   au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif
set showmatch
set hlsearch
" vim ~/.ctags, -python-kinds=-i"
" ctags -R -o ~/.vim/python-tags ~/project"
" use C-] to jump, and C-t jump back"
set tags=~/.vim/python-tags

" or in the root of source repository,
" ctags -R * 
" then
" set autochdir
" set tags=tags;

" C-v then Alt-n to insert ^[n for key mapping to tabnext"
" :tabe or :tabnew new-tab, open new file"
" vim -p file1 file2 will open multiple tabs"
"nnoremap n :tabnext<CR>
"inoremap n <esc>:tabnext<CR>
"nnoremap p :tabprevious<CR>
"inoremap p <esc>:tabprevious<CR>
"esc p equal to alt p, so don't use alt p as tabs switch
nnoremap <C-x>f :tabnext<CR>
inoremap <C-x>f <esc>:tabnext<CR>
nnoremap <C-x>b :tabprevious<CR>
inoremap <C-x>b <esc>:tabprevious<CR>

"use :e to do :tabe"
cnoreabbrev <expr> e getcmdtype() == ":" && getcmdline() == 'e' ? 'tabe' : 'e'

" ssh is slowly, ssh over kcptun is better"
" ./server_linux_amd64 -t "127.0.0.1:ssh-port" -l ":listen-port" -mode fast3 -nocomp -sockbuf 16777217 -dscp 46"
" ./client_linux_amd64 -r "server-ip:listen-port" -l ":local-listen-port" -mode fast3 -nocomp -autoexpire 900 -sockbuf 16777217 -dscp 46"
" ssh -N -p local-listen-port user@localhost"
" vim scp://user@localhost:local-listen-port/file"
" :let $a="scp://user@localhost:local-listen-port""
" :e $a/a.hs"

" execute pathogen#infect()

" ale linter
" let g:ale_linters ={'haskell': ['hlint', 'hdevtools', 'hfmt'],}

" syntastic linter
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

" git clone https://github.com/KenN7/vim-arsync.git
" vim ~/remote/project/.vim-arsync # this need to be in the root of project which need to rsync
" remote_host remote
" remote_user user
" remote_port port
" remote_path ~/project/
" local_path /home/user/remote/project/
" auto_sync_up 1
" remote_or_local remote
" sleep_before_sync 0
" then cd ~/remote/project and vim files, :w will rsync to remote
" disable vim-arsync
" vim .vim/plugin/vim-arsync.vim
" comment 146-150 lines

" set pylint as python linter
" autocmd FileType python compiler pylint

" instead of ale or syntastic
" learnvimscriptthehardway.stevelosh.com/chapters/12.html
" auto check syntax after :w, set by compiler pylint
" autocmd BufWritePost *.py execute 'make %'
" autocmd BufWritePost *.py execute '!pylint --errors-only %'

" autocmd CmdlineLeave *.py execute 'make %'

" auto run after :w
" autocmd BufWritePost *.py execute '!python3 %'

" F5 to run 
" autocmd FileType python nnoremap <F5> <esc>:w<enter>:!python %:p<enter>
" autocmd filetype python inoremap <F5> <esc>:w<enter>:!python %:p<enter>

" implement comment like nerdcommenter
" autocmd filetype javascript nnoremap <buffer> <C-o> I//<esc>

" set omnifunc=syntaxcomplete#Complete
" autocmd filetype python set omnifunc=python3complete#Complete
" set completeopt=noinsert,menuone

" autocmd filetype python let SuperTabDefaultCompletionType = "<C-X><C-O>"
" autocmd filetype python let SuperTabDefaultCompletionType = "context"

" let g:auto_omnicomplete_key= 'a b c d e f'
" vim /usr/share/vim/vim82/autoload/javascriptcomplete.vim
" vim /usr/share/vim/vim82/autoload/python3complete.vim

" use :set all, or :set! all, or :set omnifunc? to get the value
"omnifunc=javascriptcomplete#CompleteJS, this work on archlinux
"on centos 7, vim7, vim a.py use omni completion instead of keyword completion, and
"on archlinux, vim8, vim a.js use omni completion instead of keyword completion

" apt install jq "
" :%!jq . will format json file
autocmd filetype json nnoremap <buffer> <F5> :%!jq . <cr>


" F9 yank data to clipboard
function! Pastetoclip()
    silent execute "'<,'>w !xclip -selection clipboard"
endfunction

" noremap <F9> :call Pastetoclip()<CR>

function Func2X11()
    :call system('xclip -selection c', @r)
endfunction
vnoremap <F9> "ry:call Func2X11()<cr>
" vnoremap <m-c> "ry:call Func2X11()<cr>
" vnoremap <ESC-c> "ry:call Func2X11()<cr>

function! GetVisualSelection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        echom "empty"
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    echom lines[0]
    return join(lines, "\n")
endfunction

" copy yanked data to clipboard
" autocmd TextYankPost * if v:event.operator ==# 'y' | silent execute "'<,'>w !xclip -selection clipboard" | endif
"autocmd TextYankPost * if v:event.operator ==# 'y' | call  GetVisualSelection() | endif
" set clipboard=unnamedplus
autocmd TextYankPost * silent execute "\"+y"

" https://stackoverflow.com/questions/14465383
nnoremap <C-]> g<C-]>

" vim find colorscheme in ~/.vim/colors/vivify.vim
" colorscheme vivify
" colorscheme github

" vimdiff file file is alias to vim -d file file
" vimdiff with different color schema
if &diff
    syntax off
    " colorscheme vivify
    colorscheme pablo
endif

" enable status line, modebar in emacs
set statusline+=%F
set laststatus=2

set splitright
set splitbelow

" set term size, use :term to open terminal
set termwinsize=6x0

let g:ot=0

function! IsCursorAfterSpace()
    "return 1 if after space"
    let l:line = getline('.')
    let l:col = col('.')
    if l:col > 1 && l:line[l:col - 2] ==# ' '
        return 1
    else
        return 0
    endif
endfunction

function! IsCursorAfterPeriod()
    "return 1 if after period"
    let l:line = getline('.')
    let l:col = col('.')
    if l:col > 1 && l:line[l:col - 2] == '.'
        return 1
    else
        return 0
    endif
endfunction


function! InserTabWrapper(direction)
    if "backward" == a:direction
        let l:rtn1 = "\<c-n>"
        let l:rtn2 = "\<c-p>"
    else
        let l:rtn1 = "\<c-p>"
        let l:rtn2 = "\<c-n>"
    endif

    let l:col = col('.')

    if !pumvisible()
        let g:ot = 0
    endif

    if IsCursorAfterSpace() == 1
        return "\<tab>"
    elseif IsCursorAfterPeriod() == 1 && g:ot == 0
        let g:ot = 1
        " set completeopt=menu,noinsert,noselect
        return "\<c-x>\<c-o>"
    elseif col > 1 && g:ot == 0

        " set completeopt=menuone
        " return "\<c-p>"
        return rtn1
    elseif col > 1 && g:ot == 1
        " set completeopt=menuone
        " return "\<c-n>"
        return rtn2
    else
        let g:ot = 0
        return "\<tab>"
    endif

endfunction

inoremap <tab> <c-r>=InserTabWrapper("forward")<cr>
inoremap <s-tab> <c-r>=InserTabWrapper("backward")<cr>

filetype plugin on
set omnifunc=syntaxcomplete#Complete
autocmd filetype python set omnifunc=python3complete#Complete
autocmd filetype haskell set omnifunc=haskellcomplete#Complete
autocmd filetype xml set omnifunc=xmlcomplete#CompleteTags
autocmd filetype css set omnifunc=csscomplete#CompleteCSS
autocmd filetype html set omnifunc=htmlcomplete#CompleteTags
autocmd filetype php set omnifunc=phpcomplete#CompletePHP
autocmd filetype sql set omnifunc=sqlcomplete#Complete
autocmd filetype javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd filetype c set omnifunc=ccomplete#Complete
autocmd filetype ruby set omnifunc=rubycomplete#Complete
" set completeopt=menuone
" set completeopt=menu,noinsert,noselect


"s/^/-- /<CR>"
"s/^-- /<CR>"

let g:Comment = ""
let g:EndComment = ""

autocmd filetype python let g:Comment = "# " | let g:EndComment = ""
autocmd filetype haskell let g:Comment = "-- " | let g:EndComment = ""
autocmd filetype vim let g:Comment = "\" " | let g:EndComment = ""
autocmd filetype html let g:Comment = "<!-- " | let g:EndComment = " -->"
autocmd filetype javascript let g:Comment = "// " | let g:EndComment = ""
autocmd filetype css let g:Comment = "/* " | let g:EndComment = " */"

"@ is split symbol, like /"
function! SimpleComment() range
" let l:non_whitespace_position = match(getline('.'), '\S')
let l:first_line_non_whitespace_position = match(getline(a:firstline), '\S')

if strpart(getline(a:firstline),l:first_line_non_whitespace_position,len(g:Comment)) == g:Comment
silent! execute a:firstline . "," . a:lastline . "s@".g:Comment."@@"
silent! execute a:firstline . "," . a:lastline . "s@".g:EndComment."$@@"
else
" execute "normal! ".l:non_whitespace_position."| i".g:Comment
" execute ":s@^@".g:Comment."@"
silent! execute a:firstline . "," . a:lastline . "s@" . '\S' . "@".g:Comment."&@"
silent! execute a:firstline . "," . a:lastline . "s@$@".g:EndComment."@"
endif
endfunction

" the control slash C-/ is equivalent of C-_
vmap <C-/> :call SimpleComment()<CR>
vmap <C-_> :call SimpleComment()<CR>
" https://vim.fandom.com/wiki/Comment_Lines_according_to_a_given_filetype
" select lines then co will comment
vmap co :call SimpleComment()<CR>
" change cmdheight = 2 if it shows enter to continue, or to use echom to debug
set cmdheight=1

" vim variable has scope, in function it's local variable, out of function is global variable
" global variable is g:var, local variable is l:var, function parameter is a:var
" let define and change local and global variable, set change internal variable
" let g:ot = 0, if g:ot == 0, let g:ot = 2 will alter ot's value
" pumvisible() check if pop up menu is done
" help 'completeopt' check variable completeopt definition
" vmap <F3> :call func() vmap is used for visual mode like selected lines
" all the omnifunc support languages in /usr/share/vim/vim81/autoload/

set completeopt=menu,menuone,noinsert,noselect,popup
" avoid press Enter twice to get new line when popupmenu is open
" https://github.com/neoclide/coc.nvim/issues/262
inoremap <expr> <CR> pumvisible() ? "\<C-y><CR>" : "\<CR>"
" autocmd InsertCharPre * call AutoComplete()

" https://vi.stackexchange.com/questions/8900/
fun! AutoComplete()
    " '\K' is look-behind in regexp
    if v:char =~ '\K'
                \ && getline('.')[col('.') - 4] !~ '\K'
                \ && getline('.')[col('.') - 3] =~ '\K'
                \ && getline('.')[col('.') - 2] =~ '\K' " last char
                \ && getline('.')[col('.') - 1] !~ '\K'
                \ && !pumvisible()

                call feedkeys("\<C-p>", 'n')
            end
endfun

" https://stackoverflow.com/questions/35837990/
let g:complete_counter = 0
" function! SimpleComplete()
    " if (v:char >= 'a' && v:char <= 'z') || (v:char >= 'A' && v:char <= 'Z')
        " let g:complete_counter += 1
        " let g:last_char_alpha = 1
    " else
        " let g:complete_counter = 0
        " let g:last_char_alpha = 0
    " endif

    " if !pumvisible() && (v:char == '.') && has("python3") && get(g:, 'last_char_alpha', 0)
        " let g:complete_counter = 0
        " let g:ot = 1
        " silent! call feedkeys("\<C-x>\<C-o>", 'n')
    " elseif !pumvisible() && (g:complete_counter >= 2)
        " let g:complete_counter = 0
        " let g:ot = 0
        " silent! call feedkeys("\<C-p>", 'n')
    " endif
" endfunction

function! SimpleComplete()
    if (v:char >= 'a' && v:char <= 'z') || (v:char >= 'A' && v:char <= 'Z')
        let g:complete_counter += 1
    else
        let g:complete_counter = 0
    endif

    if !pumvisible() && (v:char == '.') && has("python3")
        " Get the character before the cursor (before we type the dot)
        let pre_char = getline('.')[col('.')-2]
        " Only trigger if the character before dot is alphabetical
        if pre_char >= 'a' && pre_char <= 'z' || pre_char >= 'A' && pre_char <= 'Z'
            let g:complete_counter = 0
            let g:ot = 1
            silent! call feedkeys("\<C-x>\<C-o>", 'n')
        endif
    elseif !pumvisible() && (g:complete_counter >= 2)
        let g:complete_counter = 0
        let g:ot = 0
        silent! call feedkeys("\<C-p>", 'n')
    endif
endfunction






autocmd InsertCharPre * call SimpleComplete()

" F9 to fold code, za to toggle, space to unfold, zc to close, zo to open
autocmd filetype python nnoremap <buffer> <F9> :setlocal foldmethod=indent<cr>
autocmd filetype python nnoremap <buffer> fo :setlocal foldmethod=indent<cr>
autocmd filetype haskell nnoremap <buffer> <F9> :setlocal foldmethod=indent<cr>
autocmd filetype haskell nnoremap <buffer> fo :setlocal foldmethod=indent<cr>

autocmd filetype python nnoremap <buffer> ff :w<enter>:!python3 %:p<enter>

set guifont=Cascadia\ Mono\ Regular\ 15
