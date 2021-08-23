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

    if ! command -v brew > /dev/null; then
        echo 'Installing: Homebrew'
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    if [ ! -d /usr/local/opt/coreutils/bin ]; then
        echo 'Installing: coreutils'
        brew install coreutils
    fi

    if ! command -v psql > /dev/null; then
        echo 'Installing: Postgres client'
        brew install libpq
    fi

    if ! command -v mysql > /dev/null; then
        echo 'Installing: MySQL client'
        brew install mysql-client
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
