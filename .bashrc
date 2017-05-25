# Source global definitions
if [[ -f /etc/bashrc ]]; then
    source /etc/bashrc
fi

###########
##### ALIAS
###########

alias ls='ls -l -G'

#############
##### EXPORTS
#############

# Tell the pager program less to interpret "raw" control sequences appropriately
# ie. IPython uses raw control sequences to make colored text in its displays
export PAGER=/usr/bin/less
export LESS="-R"

# Set the editor to VIM
export EDITOR=/usr/bin/vim

# brew install coreutils
export PATH="$PATH:/usr/local/opt/coreutils/libexec/gnubin"
export MANPATH="$MANPATH:/usr/local/opt/coreutils/libexec/gnuman"

##########
##### PSQL
##########

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

#########
##### SSH
#########

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

###########
##### UNATA
###########

if [[ -n $SSH_CONNECTION ]]; then
    export PYTHONPATH=$(
        x=''
        for repo in /data/shared*; do
            if [[ -d $repo ]]; then
                if [[ -z $x ]]; then
                    x="$repo"
                else
                    x="$x:$repo"
                fi
            fi
        done
        echo $x
    )
fi

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
