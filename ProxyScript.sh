function setaptproxy(){
    #args http_proxy
    http_proxy=$1
sudo sh <<SCRIPT
    # aptitude proxy settings
    if [ -e "/etc/apt/apt.conf" ]; then
       rm -rf /etc/apt/apt.conf
    fi
    
    echo 'Acquire::http::proxy "$http_proxy";' >> /etc/apt/apt.conf
    echo 'Acquire::ftp::proxy "$http_proxy";'>> /etc/apt/apt.conf
    echo 'Acquire::https:proxy "$http_proxy";' >> /etc/apt/apt.conf
    echo 'Acquire::socks::proxy "$http_proxy";' >> /etc/apt/apt.conf


SCRIPT
}

function setsshproxy(){
    # ssh proxy settings
    # args : host port
    ssh_config=$HOME/.ssh/config
    authfile=$HOME/.proxyauthfile
    if [ -e "$ssh_config" ]; then
        proxy_command="ProxyCommand corkscrew $1 $2 %h %p\n"
        if [ -e "$authfile" ]; then
            proxy_command="$proxy_command $authfile"
        fi

        # backup ssh config
        tmp=$(mktemp) || (echo "Failed to make temp file" && return)

        cat $ssh_config > $tmp

        # add proxycommand to head of file because that's how it works with 
        # all host configs
        echo -e $proxy_command > $ssh_config

        cat $tmp >> $ssh_config

        # clean up
        rm -f $tmp
    fi
}

function setenvproxy(){
    #args http_proxy no_proxy
    PROXY_ENV="http_proxy ftp_proxy https_proxy socks_proxy all_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY SOCKS_PROXY ALL_PROXY"
    for env in $PROXY_ENV
    do
        export $env=$1
    done

    # add default no proxy
    NO_PROXY_ENV="no_proxy NO_PROXY"
    for env in $NO_PROXY_ENV
    do
        export $env=$2
    done
}

function setauthfile(){
    #args username password
    authfile=$HOME/.proxyauthfile
    data="$1:$2"
    if [ -n $data ]; then
        cat "$1:$2" > $authfile
    fi
}

function unsetauthfile(){
    authfile=$HOME/.proxyauthfile
    if [ -e "$authfile" ]; then
        rm "$authfile"
    fi
}

function proxyon(){
    #args: user pwd host port ????
    proxy_value=http://$1:$2@$3:$4
    setauthfile $1 $2
    setenvproxy $proxy_value $5
    setaptproxy $proxy_value
    setsshproxy $3 $4
}

function unsetenvproxy(){
  setenvproxy
}

function unsetaptproxy(){
sudo sh <<SCRIPT
    # remove aptitude proxy settings
    if [ -e "/etc/apt/apt.conf" ]; then
       rm -rf /etc/apt/apt.conf
    fi
SCRIPT
}

function unsetsshproxy(){
    # remove ssh proxy settings
    if [ -e "$HOME/.ssh/config" ]; then
        # using tmp file since tail cannot redirect output to the same
        # file it's 'tailing'
        tmp=$(mktemp) || (echo "Failed to make temp file" && return)
        tail -n +3 $HOME/.ssh/config > $tmp
        cat $tmp > $HOME/.ssh/config
        rm -f $tmp
    fi
}

function proxyoff(){
    unsetenvproxy
    unsetaptproxy
    unsetsshproxy
}

function proxystatus(){
  if [ -n "$http_proxy" ]; then
     echo "ON"
  else
     echo "OFF"
  fi
}
