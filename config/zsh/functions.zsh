# fvim -> find and open a file in vim
function fvim() {
    if [[ $# -eq 0 ]]; then
        fd -t f | fzf --header "Open File in Vim" --preview "cat {}" | xargs nvim
    else
        fd -t f | fzf --header "Open File in Vim" --preview "cat {}" -q "$@" | xargs nvim
    fi
}

# vim -> open vim in the current directory or open the target file
function vim() {
    if [[ $# -eq 0 ]]; then
        nvim .
    else
        nvim "$@"
    fi
}

function git_log_n() {
    if test (count $argv) -eq 0
      git log \
      --color=always \
      --graph \
      --decorate \ 
      --abbrev-commit \
      --date=relative \
      --format=format:'%C(auto)%h %C(bold blue)%an %C(bold green)%ad %C(magenta)%d%n%C(reset)  │  %C(white)%s%C(reset)' --all \
      sed 's/\(\(origin\/\)\?[a-zA-Z0-9-]*\/[a-zA-Z]*-[0-9]*\)-[a-zA-Z0-9-]*/\1/g'
    else
      git log \
      --color=always \
      --graph \
      --decorate \ 
      --abbrev-commit \
      --date=relative \
      --format=format:'%C(auto)%h %C(bold blue)%an %C(bold green)%ad %C(magenta)%d%n%C(reset)  │  %C(white)%s%C(reset)' --all -n $argv[1]\
      sed 's/\(\(origin\/\)\?[a-zA-Z0-9-]*\/[a-zA-Z]*-[0-9]*\)-[a-zA-Z0-9-]*/\1/g'
    end
}
