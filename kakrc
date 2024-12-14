echo -debug %sh{ruby ~/.config/kak/generate-config.rb lspEnableWindowHook}

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


plug "occivink/kakoune-phantom-selection" config %{
    map global normal \' ': phantom-selection-add-selection<ret>'
    map global normal <a-'> ': phantom-selection-select-all<ret>: phantom-selection-clear<ret>'
    map global normal <c-n> ': phantom-selection-iterate-next<ret>'
    map global normal <c-p> ': phantom-selection-iterate-prev<ret>'
}


plug "insipx/kak-crosshairs"


plug 'jjk96/kakoune-rainbow'


plug "gustavo-hms/luar" %{
    require-module luar
}

plug "gustavo-hms/peneira" %{
    require-module peneira
} config %{
    define-command peneira-buffers %{
        peneira 'buffers: ' %{ printf '%s\n' $kak_quoted_buflist } %{
            buffer %arg{1}
        }
    }
}

# plug "andreyorst/fzf.kak" config %{
#     map global normal <c-p> ': fzf-mode<ret>'
# } defer <module-name> %{
#     <settings of module>
# }

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


# plug "andreyorst/kaktree" config %{
#     hook global WinSetOption filetype=kaktree %{
#         remove-highlighter buffer/numbers
#         remove-highlighter buffer/matching
#         remove-highlighter buffer/wrap
#         remove-highlighter buffer/show-whitespaces
#     }
#     kaktree-enable
# }

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

    source "%val{config}/generated/lspEnableWindowHook.kak"
    # hook global WinSetOption filetype=(c|cpp|cc|rust|ruby|tex|latex) %{
    #     set-option window lsp_auto_highlight_references true
    #     set-option window lsp_hover_anchor false
    #     lsp-auto-hover-enable
    #     echo -debug "Enabling LSP for filtetype %opt{filetype}"
    #     lsp-enable-window
    # }

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

# Mappings ######################################################################

# kak-lsp
map -docstring 'Select next snippet placeholder' \
    global insert <tab> \
    '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>'
map -docstring 'LSP any symbol' \
    global object a '<a-semicolon>lsp-object<ret>'
map -docstring 'LSP any symbol' \
    global object <a-a> '<a-semicolon>lsp-object<ret>'
map -docstring 'LSP errors and warnings' \
    global object d '<a-semicolon>lsp-diagnostic-object --include-warnings<ret>'
map -docstring 'LSP errors' \
    global object D '<a-semicolon>lsp-diagnostic-object<ret>'
map -docstring 'LSP function or method' \
    global object f '<a-semicolon>lsp-object Function Method<ret>'
map -docstring 'LSP class interface or struct' \
    global object t '<a-semicolon>lsp-object Class Interface Struct<ret>'

# My mappings
map global normal <ret> ': enter-user-mode peneira-shotcuts<ret>'

map -docstring 'Goto next TODO' \
    global goto G '<esc>/\bTODO\b<ret>'
map -docstring 'Goto previous TODO' \
    global goto <a-G> '<esc><a-/>\bTODO\b<ret>'

map -docstring 'Buffers matipulation' \
    global user b ': enter-user-mode buffers-manipulation<ret>'
map -docstring 'Git command' \
    global user g ': enter-user-mode git<ret>'
map -docstring 'Toggle highlighter' \
    global user h ': enter-user-mode toggle-highlighter<ret>'
map -docstring 'LSP mode' \
    global user l ': enter-user-mode lsp<ret>'
map -docstring 'Paste after selection from system clipboard' \
    global user p '<a-!>xsel -o -b<ret>'
map -docstring 'Paste before selection from system clipboard' \
    global user P '!xsel -o -b<ret>'
map -docstring 'Crazy Powerline custom separators' \
    global user <a-p> ': enter-user-mode crazy-powerline-custom-separators<ret>'
map -docstring 'Replace selection from system clipboard' \
    global user R 'd!xsel -o -b<ret>'
map -docstring 'tmux' \
    global user t ': enter-user-mode tmux<ret>'
map -docstring 'Toggle TeX input' \
    global user T ': tex-input-toggle<ret>'
map -docstring 'Yank to system clipboard' \
    global user y '<a-|>xsel -i -b<ret>'
map -docstring 'Run a shell prompt' \
    global user : ':echo -debug %sh{  }<left><left>'
map -docstring '(Un)comment line' \
    global user / ':comment-line<ret>'
map -docstring 'Chose a bracket to wrap the selection' \
    global user [ ': enter-user-mode wrap-selections<ret>'

declare-user-mode peneira-shotcuts
map global peneira-shotcuts -docstring 'buffers'     b ':peneira-buffers<ret>'
map global peneira-shotcuts -docstring 'files'       f ':peneira-files<ret>'
map global peneira-shotcuts -docstring 'local files' F ':peneira-local-files<ret>'
map global peneira-shotcuts -docstring 'lines'       l ':peneira-lines<ret>'
map global peneira-shotcuts -docstring 'symbols'     s ':peneira-symbols<ret>'

declare-user-mode crazy-powerline-custom-separators
map -docstring 'Default (half-step)' \
    global crazy-powerline-custom-separators <space> ': powerline-separator half-step<ret>'
map -docstring '42 5' \
    global crazy-powerline-custom-separators 5 ': powerline-separator custom 42 5<ret>'
map -docstring 'с**и х**' \
    global crazy-powerline-custom-separators x ': powerline-separator custom саси хуй<ret>'

declare-user-mode buffers-manipulation
map -docstring 'Arrange buffers' \
    global buffers-manipulation a ': arrange-buffers '
map -docstring 'Delete current buffer' \
    global buffers-manipulation d ': delete-buffer<ret>'
map -docstring 'Delete specified buffer' \
    global buffers-manipulation D ': delete-buffer '
map -docstring 'Delete current buffer (forced)' \
    global buffers-manipulation <a-d> ': delete-buffer!<ret>'
map -docstring 'Delete specified buffer (forced)' \
    global buffers-manipulation <a-D> ': delete-buffer! '
map -docstring 'Next buffer' \
    global buffers-manipulation n ': buffer-next<ret>'
map -docstring 'Previous buffer' \
    global buffers-manipulation p ': buffer-previous<ret>'
map -docstring 'Rename current buffer' \
    global buffers-manipulation r ': rename-buffer '

declare-user-mode wrap-selections
map -docstring '(selection)' global wrap-selections (  '\i(<esc>\a)<esc>H'
map -docstring '[selection]' global wrap-selections [  '\i[<esc>\a]<esc>H'
map -docstring '{selection}' global wrap-selections {  '\i{<esc>\a}<esc>H'
map -docstring '<selection>' global wrap-selections <  '\i<lt><esc>\a<gt><esc>H'
map -docstring "'selection'" global wrap-selections \' "\i'<esc>\a'<esc>H"
map -docstring '"selection"' global wrap-selections \" '\i"<esc>\a"<esc>H'

declare-user-mode git
map -docstring 'show-diff' global git d ': git show-diff<ret>'
map -docstring 'hide-diff' global git D ': git hide-diff<ret>'
map -docstring 'update-diff' global git u ': git update-diff<ret>'
map -docstring 'update-diff' global git <space> ': git update-diff<ret>'

declare-user-mode toggle-highlighter
map -docstring 'Add highlighter buffer/wrap' \
    global toggle-highlighter w ': add-highlighter buffer/ wrap<ret>'
map -docstring 'Remove highlighter buffer/wrap' \
    global toggle-highlighter W ': remove-highlighter buffer/wrap<ret>'

declare-user-mode tmux
map -docstring "repl horisontal" global tmux h ": tmux-repl-horizontal<ret>"
map -docstring "terminal horisontal" global tmux H ": tmux-terminal-horizontal "
map -docstring "open new client in new panel" global tmux k ": enter-user-mode tmux-kak<ret>"
map -docstring "repl vertical" global tmux v ": tmux-repl-vertical<ret>"
map -docstring "terminal vertical" global tmux V ": tmux-terminal-vertical "
map -docstring "repl window" global tmux w ": tmux-repl-window<ret>"
map -docstring "terminal window" global tmux W ": tmux-terminal-window "

declare-user-mode tmux-kak
map -docstring "horisontal" \
    global tmux-kak h ": tmux-terminal-horizontal kak -c %val{session}<ret>"
map -docstring "horisontal with options" \
    global tmux-kak H ": tmux-terminal-horizontal kak -c %val{session} "
map -docstring "vertical" \
    global tmux-kak v ": tmux-terminal-vertical kak -c %val{session}<ret>"
map -docstring "vertical with options" \
    global tmux-kak V ": tmux-terminal-vertical kak -c %val{session} "
map -docstring "window" \
    global tmux-kak w ": tmux-terminal-window kak -c %val{session}<ret>"
map -docstring "window with options" \
    global tmux-kak W ": tmux-terminal-window kak -c %val{session} "


# Hooks ########################################################################

hook global WinCreate .* %{
    powerline-separator half-step
    powerline-theme solarized-dark-termcolors

    rainbow-enable

}

hook global -group kak-lsp-servers BufSetOption filetype=ruby %{
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
    set-option buffer lsp_servers %exp{
        [clangd]
        root = "%sh{eval " $kak_opt_lsp_find_root " .clangd $(: kak_buffile)}"
        settings_section = "clangd"
        [clangd.settings.clangd]
    }
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

hook global BufSetOption filetype=(ruby|html) %{
    set-option buffer indentwidth 2
}

# Config #######################################################################

colorscheme solarized-dark

add-highlighter global/ number-lines -relative
add-highlighter global/ show-whitespaces

crosshairs

