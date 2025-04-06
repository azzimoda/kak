# echo -debug %sh{ruby ~/.config/kak/generate-config.rb lspEnableWindowHook}

#### Plugins ####

evaluate-commands %sh{
    plugins="$kak_config/plugins"
    mkdir -p "$plugins"
    [ ! -e "$plugins/plug.kak" ] && \
        git clone -q https://github.com/andreyorst/plug.kak.git \
            "$plugins/plug.kak"
    printf "%s\n" "source '$plugins/plug.kak/rc/plug.kak'"
}
plug "andreyorst/plug.kak" noload

plug "insipx/kak-crosshairs"
plug 'jjk96/kakoune-rainbow'

try %{
    source "%val{config}/plugins/wakatime.kak/wakatime.kak"
} catch %{
    echo -debug "ERROR: Wakatime is not installed!"
}
plug "wakatime.kak" noload

plug "gustavo-hms/luar" %{ require-module luar }

plug "andreyorst/fzf.kak" config %{ map global normal <c-p> ': fzf-mode<ret>' } # defer module-name { settings }

plug "alexherbo2/auto-pairs.kak"
enable-auto-pairs

plug "h-youhei/kakoune-surround" config %{
    map global normal m ': enter-user-mode surround<ret>'
    declare-user-mode surround
    map global surround m m -docstring 'Go to matching pair'
    map global surround s ': surround<ret>' -docstring 'Surround'
    map global surround c ': change-surround<ret>' -docstring 'Change'
    map global surround d ': delete-surround<ret>' -docstring 'Delete'
    map global surround t ': select-surrounding-tag<ret>' -docstring 'Select tag'
}


plug "occivink/kakoune-phantom-selection" config %{
    map global normal \' ': phantom-selection-add-selection<ret>'
    map global normal <a-'> ': phantom-selection-select-all<ret>: phantom-selection-clear<ret>'
    map global normal <c-a-n> ': phantom-selection-iterate-next<ret>'
    map global normal <c-a-p> ': phantom-selection-iterate-prev<ret>'
}


plug "delapouite/kakoune-buffers" %{
    map global normal <c-a> ': enter-buffers-mode<ret>' -docstring 'buffers'
    map global normal <c-A> ': enter-user-mode -lock buffers<ret>' -docstring 'buffers (lock)'
}


plug "mesabloo/tex-input.kak" config %{
    tex-input-setup
}


plug "andreyorst/powerline.kak" defer powerline %{
    powerline-format global 'mode_info lsp git session client bufname line_column position'
} defer powerline_gruvbox %{
    powerline-theme gruvbox
} config %{
    powerline-start
}


plug "andreyorst/smarttab.kak" defer %{
    set-option softtabstop 4
} config %{
    hook global BufOpenFile .* expandtab
    hook global BufNewFile  .* expandtab
    hook global WinSetOption filetype=(gas|asm) noexpandtab
}


# plug "andreyorst/kaktree" config %{
#     hook global WinSetOption filetype=kaktree %{
#         remove-highlighter buffer/numbers
#         remove-highlighter buffer/matching
#         remove-highlighter buffer/wrap
#         remove-highlighter buffer/show-whitespaces
#     }
#     kaktree-enable
# }


plug "kakoune-lsp/kakoune-lsp" do %{
    cargo build --release --locked
    cargo install --force --path .
} config %{
    # uncomment to enable debugging
    eval %sh{echo ${kak_opt_lsp_cmd} >> /tmp/kak-lsp.log}
    set global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"
    # set global lsp_cmd "kak-lsp -s %val{session}"

    # this is not necessary; the `lsp-enable-window` will take care of it
    # eval %sh{${kak_opt_lsp_cmd} --kakoune -s $kak_session}

    set global lsp_diagnostic_line_error_sign '║'
    set global lsp_diagnostic_line_warning_sign '┊'

    define-command ne -docstring 'go to next error/warning from lsp' %{
        lsp-find-error --include-warnings
    }
    define-command pe -docstring 'go to previous error/warning from lsp' %{
        lsp-find-error --previous --include-warnings
    }
    define-command ee -docstring 'go to current error/warning from lsp' %{
        lsp-find-error --include-warnings
        lsp-find-error --previous --include-warnings
    }

    # source "%val{config}/generated/lspEnableWindowHook.kak"
    hook global WinSetOption filetype=(c|cpp|cc|rust|ruby|tex|latex) %{
        set-option window lsp_auto_highlight_references true
        set-option window lsp_hover_anchor false
        lsp-auto-hover-enable
        echo -debug "Enabling LSP for filtetype %opt{filetype}"
        lsp-enable-window
    }


    hook global WinSetOption filetype=rust %{
        set window lsp_server_configuration rust.clippy_preference="on"
        hook window BufWritePre .* %{
            evaluate-commands %sh{
                test -f rustfmt.toml && printf lsp-formatting-sync
            }
        }
    }

    hook global KakEnd .* lsp-exit

    map global user l ': enter-user-mode lsp<ret>' -docstring 'LSP mode'

    map global insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' \
        -docstring 'Select next snippet placeholder'
    map global object a '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
    map global object <a-a> '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
    map global object d '<a-semicolon>lsp-diagnostic-object --include-warnings<ret>' \
        -docstring 'LSP errors and warnings'
    map global object D '<a-semicolon>lsp-diagnostic-object<ret>' -docstring 'LSP errors'
    map global object f '<a-semicolon>lsp-object Function Method<ret>' -docstring 'LSP function or method'
    map global object t '<a-semicolon>lsp-object Class Interface Struct<ret>' \
        -docstring 'LSP class interface or struct'

    # Hooks

    hook global -group lsp-filetype-ruby BufSetOption filetype=ruby %{
        set-option buffer lsp_servers %exp{
            [solargraph]
            root_globs = ["Gemfile"]
            args = ["stdio"]
            settings_section = "_"
            [solargraph.settings._]

            [standardrb]
            root_globs = ["Gemfile"]
            args = ["--lsp"]

            [ruby-lsp]
            root_globs = ["Gemfile"]
            args = ["stdio"]
        }
        echo -debug 'Language servers: solargraph, standardrb, ruby-lsp'
    }
    hook global -group kak-lsp-servers BufSetOption filetype=rust %{
        set-option buffer lsp_servers %exp{
            [rust-analyzer]
            root = "%sh{eval " $kak_opt_lsp_find_root " Cargo.toml src $(: kak_buffile)}"
            settings_section = "rust-analyzer"
        }
        echo -debug 'LS `rust-analyzer` is configured.'
    }
    hook global -group kak-lsp-servers BufSetOption filetype=d %{
        set-option buffer lsp_servers %exp{
            [dls]
            root = "%sh{eval " $kak_opt_lsp_find_root " dub.sdl dub.json $(: kak_buffile)}"
            settings_section = "dls"
            [dls.settings.dls]
        }
        echo -debug 'LS `dls` is configured.'
    }
    hook global -group kak-lsp-servers BufSetOption filetype=(c|cpp) %{
        # set-option buffer lsp_servers %exp{
        #     [clangd]
        #     args = [""]
        # }
        echo -debug 'LS `clangd` is configured.'
    }
    hook global -group kak-lsp-servers BufSetOption filetype=(tex|latex) %{
        set-option buffer lsp_servers %exp{
            [texlab]
            root = "%sh{eval " $kak_opt_lsp_find_root " $(: kak_buffile)}"
            settings_section = "texlab"
            [texlab.settings.texlab]
        }
    }
}


#### Commands ####

define-command -params 1 -docstring 'Format D file' dfmt %{ echo -debug %sh{ dfmt -t tab -i $1 } }
define-command -docstring 'Format D code of current buffer' dfmt-buffer %{ dfmt %reg{%} }
define-command -params 1..2 -docstring 'translate [[<from>]:[<to>[+...]]] <it>: translate a word or a string' \
    translate %{ echo -debug %sh{ trans $1 $2 } }
define-command -params 1 -docstring 'read <filename>: open the given filename in a readonly buffer' \
    read %{
    eval edit -readonly %arg{1}
}

alias global W write-all
alias global trans translate

#### Mappings ####

# map global goto G '<esc>/\bTODO\b<ret>' -docstring 'Goto next TODO'
# map global goto <a-G> '<esc><a-/>\bTODO\b<ret>' -docstring 'Goto previous TODO'

map global user b ': enter-user-mode buffers-manipulation<ret>' -docstring 'Buffers matipulation'
map global user c ': comment-line<ret>' -docstring '(Un)comment line'
map global user C ': comment-block<ret>' -docstring 'Comment block'
map global user g ': enter-user-mode git<ret>' -docstring 'Git command'
map global user h ': enter-user-mode toggle-highlighter<ret>' -docstring 'Toggle highlighter'
map global user p '<a-!>xsel -o -b<ret>' -docstring 'Paste after selection from system clipboard'
map global user P '!xsel -o -b<ret>' -docstring 'Paste before selection from system clipboard'
map global user <a-p> ': enter-user-mode crazy-powerline-custom-separators<ret>' \
    -docstring 'Crazy Powerline custom separators'
map global user R 'd!xsel -o -b<ret>' -docstring 'Replace selection from system clipboard'
map global user t ': enter-user-mode tmux<ret>' -docstring 'tmux'
map global user T ': tex-input-toggle<ret>' -docstring 'Toggle TeX input'
map global user y '<a-|>xsel -i -b<ret>' -docstring 'Yank to system clipboard'
map global user : ':echo -debug %sh{  }<left><left>' -docstring 'Run a shell prompt and print it to debug'

declare-user-mode crazy-powerline-custom-separators
map global crazy-powerline-custom-separators <space> ': powerline-separator half-step<ret>' \
    -docstring 'Default (half-step)'
map global crazy-powerline-custom-separators 5 ': powerline-separator custom 42 5<ret>' -docstring '42 5'
map global crazy-powerline-custom-separators x ': powerline-separator custom саси хуй<ret>' -docstring 'с**и х**'

declare-user-mode buffers-manipulation
map global buffers-manipulation a ': arrange-buffers ' -docstring 'Arrange buffers'
map global buffers-manipulation d ': delete-buffer<ret>' -docstring 'Delete current buffer'
map global buffers-manipulation D ': delete-buffer ' -docstring 'Delete specified buffer'
map global buffers-manipulation <a-d> ': delete-buffer!<ret>' -docstring 'Delete current buffer (forced)'
map global buffers-manipulation <a-D> ': delete-buffer! ' -docstring 'Delete specified buffer (forced)'
map global buffers-manipulation n ': buffer-next<ret>' -docstring 'Next buffer'
map global buffers-manipulation p ': buffer-previous<ret>' -docstring 'Previous buffer'
map global buffers-manipulation r ': rename-buffer ' -docstring 'Rename current buffer'

declare-user-mode git
map global git d ': git show-diff<ret>' -docstring 'show-diff'
map global git D ': git hide-diff<ret>' -docstring 'hide-diff'
map global git u ': git update-diff<ret>' -docstring 'update-diff'
map global git <space> ': git update-diff<ret>' -docstring 'update-diff'

declare-user-mode toggle-highlighter
map global toggle-highlighter c ': cursorline<ret>' -docstring 'Toggle cursor line highlighting'
map global toggle-highlighter <a-c> ': crosshairs<ret>' -docstring 'Toggle cursor crosshairs'
map global toggle-highlighter l ': cursorcolumn<ret>' -docstring 'Toggle cursor column highlighting'
map global toggle-highlighter w ': add-highlighter buffer/ wrap<ret>' -docstring 'Add highlighter buffer/wrap'
map global toggle-highlighter W ': remove-highlighter buffer/wrap<ret>' -docstring 'Remove highlighter buffer/wrap'

map global normal <c-w> ": enter-user-mode vim-windows<ret>"
declare-user-mode vim-windows # actually it is like in Helix :)
map global vim-windows w ":echo -debug Not yet.<ret>" -docstring "Goto next window"
map global vim-windows <c-w> ":echo -debug Not yet.<ret>" -docstring "Goto next window"
map global vim-windows s ": tmux-terminal-horizontal kak -c %val{session}<ret>" -docstring "Split horizontally"
map global vim-windows <c-s> ": tmux-terminal-horizontal kak -c %val{session}<ret>" -docstring "Split horizontally"
map global vim-windows v ": tmux-terminal-vertical kak -c %val{session}<ret>" -docstring "Split vertivally"
map global vim-windows <c-v> ": tmux-terminal-vertical kak -c %val{session}<ret>" -docstring "Split vertivally"
map global vim-windows q ":q<ret>" -docstring "Quit window"
map global vim-windows <c-q> ":q<ret>" -docstring "Quit window"
# TODO: Vim-like window navigation key mappings.

declare-user-mode tmux
map global tmux h ": tmux-repl-horizontal<ret>" -docstring "repl horisontal"
map global tmux H ": tmux-terminal-horizontal " -docstring "terminal horisontal"
map global tmux k ": enter-user-mode tmux-kak<ret>" -docstring "open new client in new panel"
map global tmux v ": tmux-repl-vertical<ret>" -docstring "repl vertical"
map global tmux V ": tmux-terminal-vertical " -docstring "terminal vertical"
map global tmux w ": tmux-repl-window<ret>" -docstring "repl window"
map global tmux W ": tmux-terminal-window " -docstring "terminal window"

declare-user-mode tmux-kak
map global tmux-kak h ": tmux-terminal-horizontal kak -c %val{session}<ret>" -docstring "horisontal"
map global tmux-kak H ": tmux-terminal-horizontal kak -c %val{session} " -docstring "horisontal with options"
map global tmux-kak v ": tmux-terminal-vertical kak -c %val{session}<ret>" -docstring "vertical"
map global tmux-kak V ": tmux-terminal-vertical kak -c %val{session} " -docstring "vertical with options"
map global tmux-kak w ": tmux-terminal-window kak -c %val{session}<ret>" -docstring "window"
map global tmux-kak W ": tmux-terminal-window kak -c %val{session} " -docstring "window with options"


#### Hooks ####

hook global WinCreate .* %{
    powerline-separator triangle
    powerline-theme solarized-dark-termcolors

    rainbow-enable
}


hook global BufSetOption filetype=(ruby|eruby|html) %{
    set-option buffer indentwidth 2
}

#### Config ####

colorscheme gruvbox-dark

add-highlighter global/ number-lines -relative
add-highlighter global/ show-whitespaces

cursorline

