GENERATED_CONFIG_DIR = "#{`echo $HOME`.chomp}/.config/kak/generated"
EASY_LANGS = 'c cpp cc ruby'.split' '
HARD_LANGS = 'rust ruby tex latex'.split' '
ALL_LANGS_RE = (EASY_LANGS + HARD_LANGS).join'|'


puts "[Azzy's Generated Config] Ensure the directory for generated config files is created."
system("mkdir -p #{GENERATED_CONFIG_DIR}")

OPTION = 'lspEnableWindowHook'
print "[Azzy's Generated Config] Generating config by option `#{OPTION}`... "
text = case ARGV[0]
when OPTION
  if `whoami` == 'azzimoda'
    "echo -debug 'Language some language servers will be ignored because of your weak laptop.'
hook global WinSetOption filetype=(#{EASY_LANGS}) %{
    set-option window lsp_auto_highlight_references true
    set-option window lsp_hover_anchor false
    lsp-auto-hover-enable
    echo -debug \"Enabling LSP for filtetype %opt{filetype}\"
    lsp-enable-window
}"
  else
    "hook global WinSetOption filetype=(#{ALL_LANGS_RE}) %{
    set-option window lsp_auto_highlight_references true
    set-option window lsp_hover_anchor false
    lsp-auto-hover-enable
    echo -debug \"Enabling LSP for filtetype %opt{filetype}\"
    lsp-enable-window
}"
  end
end
File.write "#{GENERATED_CONFIG_DIR}/#{OPTION}.kak", text
puts "[Done]"

