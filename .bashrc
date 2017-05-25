# Source global definitions
if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
fi

# Source deep definitions
if [[ -f ~/.deeprc ]]; then
    source ~/.deeprc
fi

#########
# EXPORTS
#########

# Tell the pager program less to interpret "raw" control sequences appropriately
# ie. IPython uses raw control sequences to make colored text in its displays
export PAGER=/usr/bin/less
export LESS="-R"

# Set the editor to VIM
export EDITOR=/usr/bin/vim

# Coreutils
# brew install coreutils
export PATH="$PATH:/usr/local/opt/coreutils/libexec/gnubin"
export MANPATH="$MANPATH:/usr/local/opt/coreutils/libexec/gnuman"

#######
# ALIAS
#######

# Coreutils
alias ls='gls -l --color=auto'
alias du='gdu --human-readable --max-depth=1'
alias sort='gsort'

# Sublime
alias subl="/usr/local/Caskroom/sublime-*/*/*.app/Contents/SharedSupport/bin/subl"

######
# MISC
######

function edit_bashrc {
    $EDITOR ~/.bashrc && . ~/.bashrc
}

function weather {
    # Usage: weather [city]
    if [[ $# -eq 0 ]]; then
        curl http://wttr.in/
    else
        curl "http://wttr.in/$1"
    fi
}

function line_count {
    wc -l | tr -d [[:space:]]
}

function job_count {
    jobs | line_count
}

function space {
    # Usage: space [dir]
    # Example:
    #     space
    #     space /
    DIR="$1"
    if [ -z "$DIR" ]; then
        DIR="$PWD"
    fi
    du --human-readable --max-depth=1 "$DIR" 2> /dev/null \
        | grep --extended-regexp 'M|G' \
        | sort --human-numeric-sort --reverse
}

function prompt_yes_no {
    message="$1"
    read -p "$message " -n 1 choice
    echo
    case "$choice" in
        y|Y)
            echo 'yes'
            return 0
            ;;
        n|N)
            echo 'no'
            ;;
        *)
            echo 'invalid'
            ;;
    esac
    return 1
}

######
# PSQL
######

export PATH="$PATH:/usr/pgsql-9.3/bin:/usr/pgsql-9.2/bin"

function pg_dump_table {
    host="$1"
    username="$2"
    table="$3"
    backup="$table.$(date +%Y-%m-%d).backup"
    pg_dump --ignore-version --verbose --blobs --format=c --compress=9 --host=$host --username=$username --table=$table --file $backup
    echo $backup
}

function pg_restore_table {
    host="$1"
    username="$2"
    backup="$3"
    pg_restore --ignore-version --verbose --host=$host --username=$username --dbname=$username $backup
}

#####
# SSH
#####

function all_hosts {
    grep '^Host' ~/.ssh/config | grep -v '[?*]' | cut -d ' ' -f 2-
}

# SSH auto-complete

function complete_ssh {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(all_hosts)
    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
    return 0
}

complete -F complete_ssh ssh

# Python remote virtualenv

if [[ -n $SSH_CONNECTION ]]; then
    source ~/virtualenv/bin/activate
fi

# CSSHX

function ss {
    # Usage: ss [hosts]
    # brew install csshx
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

##########
# SESSIONS
##########

# Creating sessions

function cookie_session {
    # Usage: cookie_session [session_name] [host] [identifier] [password]
    # Requires: httpie
    # Example:
    # > cookie_session
    # > http --session=dashboard GET dashboard.dev/products
    # > http --session=dashboard GET dashboard.dev/product_collections | jq '.items[0].name'

    session_name="$1"
    if [[ -z $session_name ]]; then
        session_name="dashboard"
    fi

    host="$2"
    if [[ -z $host ]]; then
        host="dashboard.dev"
    fi

    identifier="$3"
    if [[ -z $identifier ]]; then
        identifier="USER@SERVER.COM"
    fi

    password="$4"
    if [[ -z $password ]]; then
        password="password"
    fi

    echo "save session as $session_name..."
    http --session=$session_name POST $host/auth email=$identifier password=$password
}

function jwt_session {
    # Usage: jwt_session [session_name] [host] [identifier] [password]
    # Requires: httpie, jq
    # Example:
    # > jwt_session
    # > http --session=api get api.dev/v2/stores
    # > http --session=api get api.dev/v2/user

    session_name="$1"
    if [[ -z $session_name ]]; then
        session_name="api"
    fi

    host="$2"
    if [[ -z $host ]]; then
        host="api.dev"
    fi

    identifier="$3"
    if [[ -z $identifier ]]; then
        identifier="USER@SERVER.COM"
    fi

    password="$4"
    if [[ -z $password ]]; then
        password="password"
    fi

    echo "get $host session token..."
    session_token=$(
        cat <<USER_AGENT
{
    "binary": "web",
    "binary_version": "1.0",
    "is_retina": false,
    "os_version": "Mac OSX",
    "pixel_density": 1.0,
    "screen_height": 300,
    "screen_width": 160
}
USER_AGENT |
        http POST $host/v2/user_sessions |
        jq --raw-output '.session_token'
    )

    echo "authorize $identifier..."
    session_token=$(
        http POST $host/v2/auth/jwt identifier=$identifier password=$password "Authorization:Bearer $session_token" |
        jq --raw-output '.session_token'
    )

    echo "save session as $session_name..."
    http --session=$session_name $host/v2/user "Authorization:Bearer $session_token"
}
