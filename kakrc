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

plug "andreyorst/fzf.kak" config %{ map global normal <ret> ': fzf-mode<ret>' } # defer module-name { settings }

plug "alexherbo2/auto-pairs.kak" %{ hook global WinCreate .* %{ enable-auto-pairs } }

# plug "lePerdu/kakboard" %{ hook global WinCreate .* %{ kakboard-enable } }

plug "mesabloo/tex-input.kak" config %{ tex-input-setup }


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
    map global normal <c-space> ': enter-buffers-mode<ret>' -docstring 'buffers'
    map global normal <c-a-space> ': enter-user-mode -lock buffers<ret>' -docstring 'buffers (lock)'
    map global user <space> ': enter-buffers-mode<ret>' -docstring 'buffers'
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

            # [ruby-lsp]
            # root_globs = ["Gemfile"]
            # args = ["stdio"]
        }
        echo -debug 'Language servers: standardrb, ruby-lsp'
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

map global user c ': comment-line<ret>' -docstring '(Un)comment line'
map global user C ': comment-block<ret>' -docstring 'Comment block'
map global user g ': enter-user-mode git<ret>' -docstring 'Git command'
map global user h ': enter-user-mode toggle-highlighter<ret>' -docstring 'Toggle highlighter'
map global user p '<a-!>xsel -o -b<ret>' -docstring 'Paste after from system'
map global user P '!xsel -o -b<ret>' -docstring 'Paste before from system'
map global user R 'd!xsel -o -b<ret>' -docstring 'Replace selection from system clipboard'
map global user t ': enter-user-mode tmux<ret>' -docstring 'tmux'
map global user T ': tex-input-toggle<ret>' -docstring 'Toggle TeX input'
map global user y '<a-|>xsel -i -b<ret>' -docstring 'Yank to system clipboard'
map global user : ':echo -debug %sh{  }<left><left>' -docstring 'Run a shell prompt and print it to debug'

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

evaluate-commands %sh{
    if [ -n "$ZELLIJ" ]; then
        echo 'map global normal <c-w> ": enter-user-mode zellij-windows<ret>"'
    elif [ -n "$TMUX" ]; then
        echo 'map global normal <c-w> ": enter-user-mode tmux-windows<ret>"'
    fi
}

# map global normal <c-w> ": enter-user-mode windows<ret>"
# declare-user-mode windows
# map global windows t ": enter-user-mode tmux-windows<ret>" -docstring 'tmux'
# map global windows z ": enter-user-mode zellij-windows<ret>" -docstring 'zellij'

declare-user-mode tmux-windows
map global tmux-windows s ": tmux-terminal-horizontal kak -c %val{session}<ret>" -docstring "Split horizontally"
map global tmux-windows <c-s> ": tmux-terminal-horizontal kak -c %val{session}<ret>" -docstring "Split horizontally"
map global tmux-windows v ": tmux-terminal-vertical kak -c %val{session}<ret>" -docstring "Split vertivally"
map global tmux-windows <c-v> ": tmux-terminal-vertical kak -c %val{session}<ret>" -docstring "Split vertivally"

declare-user-mode zellij-windows
map global zellij-windows s ": zellij-terminal-horizontal kak -c %val{session}<ret>" -docstring "Split horizontal"
map global zellij-windows <c-s> ": zellij-terminal-horizontal kak -c %val{session}<ret>" -docstring "Split horizontal"
map global zellij-windows v ": zellij-terminal-vertical kak -c %val{session}<ret>" -docstring "Split vertical"
map global zellij-windows <c-v> ": zellij-terminal-vertical kak -c %val{session}<ret>" -docstring "Split vertical"

#### Hooks ####

hook global WinCreate .* %{
    powerline-separator half-step
    powerline-theme solarized-dark-termcolors

    rainbow-enable
}


hook global BufSetOption filetype=(ruby|eruby|html|yaml) %{
    set-option buffer indentwidth 2
}

#### Config ####

colorscheme gruvbox-dark

add-highlighter global/ number-lines -relative
add-highlighter global/ show-whitespaces

cursorline

