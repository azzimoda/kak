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
    hook global WinSetOption filetype=asm noexpandtab
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
    echo "kak-lsp have been configured"
    nop %sh{ echo "kak-lsp have been configured" }

    # uncomment to enable debugging
    eval %sh{echo ${kak_opt_lsp_cmd} >> /tmp/kak-lsp.log}
    set global lsp_cmd "kak-lsp -s %val{session} -vvv --log /tmp/kak-lsp.log"

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

    define-command lsp-restart -docstring 'restart lsp server' %{
        lsp-stop
        lsp-start
    }
    hook global WinSetOption filetype=(c|cpp|cc|rust|javascript|typescript) %{
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

    # LSP configs
    hook global BufSetOption filetype=rust %{
        set-option buffer lsp_servers %exp{
            [rust-analyzer]
            root = "%sh{eval " $kak_opt_lsp_find_root " Cargo.toml src $(: kak_buffile)}"
            settings_section = "rust-analyzer"
            [rust-analyzer.settings.rust-analyzer]
        }
    }
    hook global BufSetOption filetype=(c|cpp) %{
        set-option buffer lsp_servers %exp{
            [clangd]
            root = "%sh{eval " $kak_opt_lsp_find_root " .clangd $(: kak_buffile)}"
            settings_section = "clangd"
            [clangd.settings.clangd]
        }
        # set-option buffer lsp_servers %exp{
        #     [ccls]
        #     root = "%sh{eval " $kak_opt_lsp_find_root " .ccls $(: kak_buffile)}"
        #     settings_section = "ccls"
        #     [ccls.settings.ccls]
        # }
    }
}

# plug "tom-huntington/simple-git-gutter.kak"

# Commands #####################################################################

define-command -hidden -params 1 _dfmt %{ nop %sh{ dfmt -t tab -i $1 } }
define-command dfmt %{ _dfmt %reg{%} }

alias global W write-all

# Mapping ######################################################################

declare-user-mode bracket-wrapping
declare-user-mode git

map global user l %{:enter-user-mode lsp<ret>} -docstring "LSP mode"
map global insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' \
    -docstring 'Select next snippet placeholder'
map global object a '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
map global object <a-a> '<a-semicolon>lsp-object<ret>' \
    -docstring 'LSP any symbol'
map global object f '<a-semicolon>lsp-object Function Method<ret>' \
    -docstring 'LSP function or method'
map global object t '<a-semicolon>lsp-object Class Interface Struct<ret>' \
    -docstring 'LSP class interface or struct'
map global object d '<a-semicolon>lsp-diagnostic-object --include-warnings<ret>' \
    -docstring 'LSP errors and warnings'
map global object D '<a-semicolon>lsp-diagnostic-object<ret>' \
    -docstring 'LSP errors'

map global user y '<a-|>xsel -i -b<ret>' -docstring "Yank to system clipboard"
map global user p '<a-!>xsel -o -b<ret>' -docstring "Paste after selection from system clipboard"
map global user P '!xsel -o -b<ret>' -docstring "Paste before selection from system clipboard"
map global user c ':comment-line<ret>' -docstring "(Un)comment line"
map global user t ':set buffer indentwidth ' -docstring "`:set buffer indentwidth `"
map global user / ':debug %sh{  }<left><left>' -docstring "`:debug %sh{  }<left><left>`"
map global user [ ':enter-user-mode bracket-wrapping<ret>' -docstring "Chose a bracket to wrap the selection."
map global user g ': enter-user-mode git' -docstring "Run git command…"

map global bracket-wrapping [ 'i[<esc>a]<esc>' # i[<esc>"pP
map global bracket-wrapping { 'i{<esc>a}<esc>' # i{<esc>"pP
map global bracket-wrapping ( 'i(<esc>a)<esc>' # i(<esc>"pP
map global bracket-wrapping <space> '"pP' -docstring "Cancel"

map global git d ': git show-diff' -docstring "show-diff"
map global git D ': git hide-diff' -docstring "hide-diff"
map global git u ':git update-diff' -docstring "update-diff"

# Hooks ########################################################################

# Config #######################################################################

colorscheme default
add-highlighter global/ number-lines -relative

