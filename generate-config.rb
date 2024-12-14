GENERATED_CONFIG_DIR = "#{`echo $HOME`.chomp}/.config/kak/generated"
EASY_LANGS = 'ruby'.split' '
HARD_LANGS = 'c cpp cc rust tex latex'.split' '
EASY_LANGS_RE = EASY_LANGS.join'|'
ALL_LANGS_RE = (EASY_LANGS + HARD_LANGS).join'|'


puts "[Azzy's Generated Config] Ensure the directory for generated config files is created."
system("mkdir -p #{GENERATED_CONFIG_DIR}")

OPTION = 'lspEnableWindowHook'
puts "[Azzy's Generated Config] Generating config by option `#{OPTION}`... "
text = case ARGV[0]
when OPTION
  if `whoami`.strip == 'azzimoda'
    print "[Azzy's Generated Config] Using easy language servers: (#{EASY_LANGS_RE})"
    "echo -debug 'Language some language servers will be ignored because of your weak laptop.'
hook global WinSetOption filetype=(#{EASY_LANGS_RE}) %{
    set-option window lsp_auto_highlight_references true
    set-option window lsp_hover_anchor false
    lsp-auto-hover-enable
    echo -debug \"Enabling LSP for filtetype %opt{filetype}\"
    lsp-enable-window
}"
  else
    print "[Azzy's Generated Config] Using all language servers: (#{ALL_LANGS_RE})"
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

