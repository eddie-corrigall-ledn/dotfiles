#!/bin/bash

NAME="$0"
DIR="$(dirname "${BASH_SOURCE[0]}")"
NOW="$(date +%s)"

function usage() {
    echo "USAGE: $NAME <install|uninstall>"
    echo 'Install dotfiles for custom shell experience'
}

function symlink() {
    local SOURCE="$1"
    local DESTINATION="$2"
    if [[ -f "$DESTINATION" ]]; then
        mv "$DESTINATION" "$DESTINATION.$NOW.backup"
    fi
    ln -s "$SOURCE" "$DESTINATION"
}

function do_install() {
    symlink "$PWD/$DIR/.bashrc" "$HOME/.bashrc"
    symlink "$PWD/$DIR/.psqlrc" "$HOME/.psqlrc"
    symlink "$PWD/$DIR/.tmux.config" "$HOME/.tmux.config"
    symlink "$PWD/$DIR/.vimrc" "$HOME/.vimrc"
    if [ "$(uname)" == "Darwin" ]; then
        echo 'Set default shell to bash'
        chsh -s /bin/bash
        echo 'Setup bash profile'
        touch "$HOME/.bash_profile"
        echo '[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"' >> "$HOME/.bash_profile"
    fi
}

function do_uninstall() {
    echo 'Not yet implemented!'
}

case "$1" in
    install)
        do_install
        exit 0
        ;;
    uninstall)
        do_uninstall
        exit 0
        ;;
    *)
        usage
        exit 1
esac
