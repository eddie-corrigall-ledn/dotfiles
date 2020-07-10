#!/bin/bash

##########
# Homebrew
##########

if ! command -v brew > /dev/null; then
    echo 'Installing: Homebrew'
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

###########
# Coreutils
###########

if [ ! -d /usr/local/opt/coreutils/bin ]; then
    echo 'Installing: coreutils'
    brew install coreutils
fi

export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

##########
# Postgres
##########

if ! command -v psql > /dev/null; then
    echo 'Installing: Postgres client'
    brew install libpq
fi

export PATH="/usr/local/opt/libpq/bin:$PATH"

function pg() {
    # Usage: pg <service> <environment>
    # Define environment variables and connect to service and environment easily, example:
    #   LOCAL_MYAPP_PG_USER
    #   LOCAL_MYAPP_PG_PASSWORD
    #   ...
    #   <environment>_<service>_PG_USER
    #   <environment>_<service>_PG_PASSWORD
    #   ...
    local service="$1"
    service="$(echo ${service:=MYAPP} | uppercase)"

    local environment="$2"
    environment="$(echo ${environment:=LOCAL} | uppercase)"

    local     user=$(eval "echo $(printf "$%s_%s_PG_USER"     "$environment" "$service")")
    local password=$(eval "echo $(printf "$%s_%s_PG_PASSWORD" "$environment" "$service")")
    local     host=$(eval "echo $(printf "$%s_%s_PG_HOST"     "$environment" "$service")")
    local     port=$(eval "echo $(printf "$%s_%s_PG_PORT"     "$environment" "$service")")
    local   dbname=$(eval "echo $(printf "$%s_%s_PG_DBNAME"   "$environment" "$service")")

    if [[ -z "$user" ]]; then
        echo "Usage: pg [service] [environment]"
        return 1
    fi

    echo "USER: $user"
    echo "HOST: $host"
    echo "PORT: $port"
    echo "DBNAME: $dbname"
    echo

    PGPASSWORD=${password} psql \
        --user="${user}" \
        --host="${host}" \
        --port="${port}" \
        --dbname="${dbname}"
}

function pg_dump_table() {
    local host="$1"
    local username="$2"
    local table="$3"
    local backup="$table.$(date +%Y-%m-%d).backup"
    pg_dump --ignore-version --verbose --blobs --format=c --compress=9 --host=$host --username=$username --table=$table --file $backup
    echo $backup
}

function pg_restore_table() {
    local host="$1"
    local username="$2"
    local backup="$3"
    prompt_yes_or_no "Restore $backup into $username@$host? (y/n)"
    pg_restore --ignore-version --verbose --host=$host --username=$username --dbname=$username $backup
}

#########
# EXPORTS
#########

# Set timezone context
# Useful for some utilities like pytest
export TZ='US/Eastern'

# Tell the pager program less to interpret "raw" control sequences appropriately
# ie. IPython uses raw control sequences to make colored text in its displays
export PAGER=/usr/bin/less
export LESS="-R"

# Set the editor to VIM
export EDITOR=/usr/bin/vim

#######
# ALIAS
#######

alias ls="ls -lha --color=auto"
alias du="du --human-readable --max-depth=1"

# Python unittest
alias unittest="python -m unittest"

######
# MISC
######

function bashrc() {
    $EDITOR ~/.bashrc && . ~/.bashrc
}

function uppercase() {
    cat /dev/stdin | tr '[a-z]' '[A-Z]'
}

function lowercase() {
    cat /dev/stdin | tr '[A-Z]' '[a-z]'
}

function weather() {
    # Usage: weather [city]
    if [[ $# -eq 0 ]]; then
        curl http://wttr.in/
    else
        curl "http://wttr.in/$1"
    fi
}

function line_count() {
    wc -l | tr -d '[[:space:]]'
}

function job_count() {
    jobs | line_count
}

function space() {
    # Usage: space [dir]
    # Example:
    #     space
    #     space /
    local dir="$1"
    if [ -z "$dir" ]; then
        dir="$PWD"
    fi
    du --human-readable --max-depth=1 "$dir" \
        | grep --extended-regexp 'K|M|G' \
        | sort --human-numeric-sort --reverse
}

function prompt_yes_no() {
    local message="$1"
    read -p "$message " -n 1 choice
    echo
    case "$choice" in
        y|Y)
            echo '=> Yes'
            return 0
            ;;
        n|N)
            echo '=> No'
            ;;
        *)
            echo '=> Invalid'
            ;;
    esac
    return 1
}

function gitbranch() {
    BRANCH=$(git symbolic-ref --short HEAD 2> /dev/null)
    if [[ -n $BRANCH ]]; then
        echo $BRANCH
    else
        echo '?'
    fi
}

#####
# SSH
#####

function ssh_hosts() {
    grep '^Host' ~/.ssh/config | grep -v '[?*]' | cut -d ' ' -f 2-
}

# SSH auto-complete

function complete_ssh() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(ssh_hosts)
    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
    return 0
}

complete -F complete_ssh ssh

#######
# CSSHX
#######

if ! command -v csshx > /dev/null; then
    echo 'Installing: CSSHX'
    brew install csshx
fi

function ss() {
    # Usage: ss [hosts]
    # Connect to multiple hosts via ssh
    # Example:
    # ss uat-web-01 uat-web-02
    HOSTS="$@"
    HOSTS_COUNT="$#"
    if [[ -z "${HOSTS_COUNT}" ]]; then
        HOSTS_COUNT=0
    fi
    echo "(${HOSTS_COUNT}): $HOSTS"
    case ${HOSTS_COUNT} in
        0)
            echo "No such host(s)"
            ;;
        1)
            ssh $HOSTS
            ;;
        *)
            prompt_yes_no "Connect to hosts? (y/n)"
            if [[ "$?" == 0 ]]; then
                csshx --hosts <(for x in $HOSTS; do echo $x; done)
            fi
            ;;
    esac
}

########
# PROMPT
########

export BLACK='\[\033[0;30m\]'
export DARK_GREY='\[\033[1;30m\]'
export LIGHT_GREY='\[\033[0;37m\]'
export BLUE='\[\033[0;34m\]'
export LIGHT_BLUE='\[\033[1;34m\]'
export GREEN='\[\033[0;32m\]'
export LIGHT_GREEN='\[\033[1;32m\]'
export CYAN='\[\033[0;36m\]'
export LIGHT_CYAN='\[\033[1;36m\]'
export RED='\[\033[0;31m\]'
export LIGHT_RED='\[\033[1;31m\]'
export PURPLE='\[\033[0;35m\]'
export LIGHT_PURPLE='\[\033[1;35m\]'
export BROWN='\[\033[0;33m\]'
export YELLOW='\[\033[1;33m\]'
export WHITE='\[\033[1;37m\]'
export COLOUR_OFF='\[\033[0m\]'

function title() {
    # Usage: title [window title]
    # Set the window title
    echo -ne "\033]0;$*\007"
}

function prompt_command() {
    # Set window title
    if [[ -n $SSH_CONNECTION ]]; then
        title "$HOSTNAME"
    else
        title 'localhost'
    fi
    # On pwd change, ls the directory up to N lines
    if [[ $CWD != $PWD ]]; then
        local CWD_FILES=(*)
        if [[ $CWD_FILES != '*' ]]; then
            ls -d "${CWD_FILES[@]:0:24}"
        fi
        export CWD=$PWD
    fi
    # Adjust prompt based on screen width
    local P=()
    if [[ $COLUMNS -le 80 ]]; then
        P+="[\$?] \u@\h:\w\n$ "
    else
        P+="${GREEN}[\$?]$COLOUR_OFF"
        P+="${DARK_GREY}[\$(gitbranch)]$COLOUR_OFF"
        P+=' '
        P+="$WHITE\u$LIGHT_GREY@$PURPLE\h$DARK_GREY:$GREEN\w$COLOUR_OFF"
        P+="\n\$ "
    fi
    export PS1=${P[@]}
}

export PROMPT_COMMAND='prompt_command'
