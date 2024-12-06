GENERATED_CONFIG_DIR = 'generated'
EASY_LANGS = 'c cpp cc ruby'.split' '
HARD_LANGS = 'rust ruby tex latex'.split' '

all_langs = (EASY_LANGS + HARD_LANGS).join'|'

system("mkdir -p ~/.config/kak/#{GENERATED_CONFIG_DIR}")

text = case ARGV[0]
when 'lspEnableWindowHook'
  if `whoami` == 'azzimoda'
    puts "echo -debug 'Language servers of some languages will be ignored due to you weak laptop.'
hook global WinSetOption filetype=(#{EASY_LANGS}) %{
    set-option window lsp_auto_highlight_references true
    set-option window lsp_hover_anchor false
    lsp-auto-hover-enable
    echo -debug \"Enabling LSP for filtetype %opt{filetype}\"
    lsp-enable-window
}"
  else
    puts "hook global WinSetOption filetype=(#{all_langs}) %{
        set-option window lsp_auto_highlight_references true
    set-option window lsp_hover_anchor false
    lsp-auto-hover-enable
    echo -debug \"Enabling LSP for filtetype %opt{filetype}\"
    lsp-enable-window
}"
  end
end
File.write "#{GENERATED_CONFIG_DIR}/lspEnableWindowHook.kak", text

