# Detect shell
if [ -n "${ZSH_VERSION:-}" ]; then shell="zsh"; else shell="bash"; fi
# Detect whether zsh 'shwordsplit' option is on by default.
if [[ $shell == "zsh" ]]; then zsh_shwordsplit=$((setopt | grep -q shwordsplit) && echo "true"); fi
# Switch on/off shwordsplit for functions that require it.
zsh_compat(){ if [[ $shell == "zsh" && -z $zsh_shwordsplit ]]; then setopt shwordsplit; fi; }
zsh_reset(){  if [[ $shell == "zsh" && -z $zsh_shwordsplit ]]; then unsetopt shwordsplit; fi; }


# Update SCM Breeze from GitHub
update_scm_breeze() { $(cd "$scmbreezeDir"; git pull origin master); }

