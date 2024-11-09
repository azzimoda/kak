# Plugins ######################################################################

evaluate-commands %sh{
    plugins="$kak_config/plugins"
    mkdir -p "$plugins"
    [ ! -e "$plugins/plug.kak" ] && \
        git clone -q https://github.com/andreyorst/plug.kak.git \
            "$plugins/plug.kak"
    printf "%s\n" "source '$plugins/plug.kak/rc/plug.kak'"
}
plug "andreyorst/plug.kak" noload


source "%val{config}/plugins/wakatime.kak/wakatime.kak"
plug "wakatime.kak" noload


plug "alexherbo2/auto-pairs.kak"
enable-auto-pairs


plug "mesabloo/tex-input.kak" config %{
    tex-input-setup
}

plug "andreyorst/powerline.kak" defer powerline_gruvbox %{
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


plug "andreyorst/kaktree" config %{
    hook global WinSetOption filetype=kaktree %{
        remove-highlighter buffer/numbers
        remove-highlighter buffer/matching
        remove-highlighter buffer/wrap
        remove-highlighter buffer/show-whitespaces
    }
    kaktree-enable
}

plug "kak-lsp/kak-lsp" do %{
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

    hook global WinSetOption filetype=(c|cpp|cc|rust|ruby|tex|latex) %{
        set-option window lsp_auto_highlight_references true
        set-option window lsp_hover_anchor false
        lsp-auto-hover-enable
        echo -debug "Enabling LSP for filtetype %opt{filetype}"
        lsp-enable-window
    }

    hook global WinSetOption filetype=(rust) %{
        set window lsp_server_configuration rust.clippy_preference="on"
    }

    hook global WinSetOption filetype=rust %{
        hook window BufWritePre .* %{
            evaluate-commands %sh{
                test -f rustfmt.toml && printf lsp-formatting-sync
            }
        }
    }

    hook global KakEnd .* lsp-exit
}

# Commands #####################################################################

define-command -params 1 dfmt %{ echo -debug %sh{ dfmt -t tab -i $1 } } -docstring 'Format D file'
define-command dfmt-buffer %{ dfmt %reg{%} }                            -docstring 'Format D code of current buffer'

alias global W write-all

# Mappings ######################################################################

# kak-lsp
map global insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' -docstring 'Select next snippet placeholder'
map global object a '<a-semicolon>lsp-object<ret>'                               -docstring 'LSP any symbol'
map global object <a-a> '<a-semicolon>lsp-object<ret>'                           -docstring 'LSP any symbol'
map global object d '<a-semicolon>lsp-diagnostic-object --include-warnings<ret>' -docstring 'LSP errors and warnings'
map global object D '<a-semicolon>lsp-diagnostic-object<ret>'                    -docstring 'LSP errors'
map global object f '<a-semicolon>lsp-object Function Method<ret>'               -docstring 'LSP function or method'
map global object t '<a-semicolon>lsp-object Class Interface Struct<ret>'        -docstring 'LSP class interface or struct'

# My mappings
map global user c ':comment-line<ret>'                        -docstring '(Un)comment line'
map global user g ': enter-user-mode git<ret>'                -docstring 'Git command'
map global user h ': enter-user-mode toggle-highlighter<ret>' -docstring 'Toggle highlighter'
map global user l ': enter-user-mode lsp<ret>'                -docstring 'LSP mode'
map global user p '<a-!>xsel -o -b<ret>'                      -docstring 'Paste after selection from system clipboard'
map global user P '!xsel -o -b<ret>'                          -docstring 'Paste before selection from system clipboard'
map global user R 'd!xsel -o -b<ret>'                         -docstring 'Replace selection from system clipboard'
map global user t ': enter-user-mode tmux<ret>'               -docstring 'tmux'
map global user T ': tex-input-toggle<ret>'                   -docstring 'Toggle TeX input'
map global user y '<a-|>xsel -i -b<ret>'                      -docstring 'Yank to system clipboard'
map global user : ':echo -debug %sh{  }<left><left>'          -docstring 'Run a shell prompt'
map global user [ ': enter-user-mode wrap-selections<ret>'    -docstring 'Chose a bracket to wrap the selection'

declare-user-mode wrap-selections
map global wrap-selections ( '\i(<esc>\a)<esc>H'
map global wrap-selections [ '\i[<esc>\a]<esc>H'
map global wrap-selections { '\i{<esc>\a}<esc>H'
map global wrap-selections < '\i<lt><esc>\a<gt><esc>H'
map global wrap-selections \' '\i''<esc>\a''<esc>H'
map global wrap-selections \" '\i"<esc>\a"<esc>H'

declare-user-mode git
map global git d ': git show-diff<ret>'   -docstring "show-diff"
map global git D ': git hide-diff<ret>'   -docstring "hide-diff"
map global git u ': git update-diff<ret>' -docstring "update-diff"

declare-user-mode toggle-highlighter
map global toggle-highlighter w ': add-highlighter buffer/ wrap<ret>'   -docstring 'Add highlighter buffer/wrap'
map global toggle-highlighter W ': remove-highlighter buffer/wrap<ret>' -docstring 'Remove highlighter buffer/wrap'

declare-user-mode tmux
map global tmux l ": tmux-repl-horizontal<ret>" -docstring "tmux-repl-horisontal"
map global tmux j ": tmux-repl-vertical<ret>"   -docstring "tmux-repl-vertical"
map global tmux w ": tmux-repl-window<ret>"     -docstring "tmux-repl-window"
map global tmux L ": tmux-terminal-horizontal " -docstring "tmux-terminal-horisontal"
map global tmux J ": tmux-terminal-vertical "   -docstring "tmux-terminal-vertical"
map global tmux W ": tmux-terminal-window "     -docstring "tmux-terminal-window"

# Hooks ########################################################################

hook global BufSetOption filetype=ruby %{
    set-option buffer lsp_servers %exp{
        [solargraph]
        root = "%sh{eval " $kak_opt_lsp_find_root " Gemfile Gemfile.lock $(: kak_buffile)}"
        command = "solargraph"
        args = [ "stdio" ]
        settings_section = "solargraph"
        [solargraph.settings.solargraph]
    }
    echo -debug 'LS `solargraph` is configured.'
}


hook global BufSetOption filetype=rust %{
    set-option buffer lsp_servers %exp{
        [rust-analyzer]
        root = "%sh{eval " $kak_opt_lsp_find_root " Cargo.toml src $(: kak_buffile)}"
        settings_section = "rust-analyzer"
    }
    echo -debug 'LS `rust-analyzer` is configured.'
}


hook global BufSetOption filetype=d %{
    set-option buffer lsp_servers %exp{
        [dls]
        root = "%sh{eval " $kak_opt_lsp_find_root " dub.sdl dub.json $(: kak_buffile)}"
        settings_section = "dls"
        [dls.settings.dls]
    }
    echo -debug 'LS `dls` is configured.'
}


hook global BufSetOption filetype=(c|cpp) %{
    set-option buffer lsp_servers %exp{
        [clangd]
        root = "%sh{eval " $kak_opt_lsp_find_root " .clangd $(: kak_buffile)}"
        settings_section = "clangd"
        [clangd.settings.clangd]
    }
    echo -debug 'LS `clangd` is configured.'
}

hook global BufSetOption filetype=(tex|latex) %{
    set-option buffer lsp_servers %exp{
        [texlab]
        root = "%sh{eval " $kak_opt_lsp_find_root " $(: kak_buffile)}"
        settings_section = "texlab"
        [texlab.settings.texlab]
    }
}

hook global BufSetOption filetype=(ruby|html) %{
    set-option buffer indentwidth 2
}

# Config #######################################################################

colorscheme solarized-dark
add-highlighter global/ number-lines -relative

