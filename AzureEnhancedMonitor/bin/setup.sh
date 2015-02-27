#!/bin/bash

install_log=`pwd`/install.log
root=$(dirname $0)
cd $root
root=`pwd`

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR]This script must be run as root" 1>&2
    exit 1
fi

function install_nodejs_suse()
{
    suse_version="SLE_11_SP3"
    if [ "$(grep 'openSUSE 13.1' /etc/*release*)" != "" ] ; then
        suse_version="openSUSE_13.1"
    elif [ "$(grep 'openSUSE 13.2' /etc/*release*)" != "" ] ; then
        suse_version="openSUSE_13.2"
    elif [ "$(grep 'SUSE Linux Enterprise Server 11' /etc/*release*)" != "" ] ; then
        if [ "$(grep 'PATCHLEVEL = 3' /etc/*release*)" != "" ] ; then
            suse_version="SLE_11_SP3"
        elif [ "$(grep 'PATCHLEVEL = 2' /etc/*release*)" != "" ] ; then
            suse_version="SLE_11_SP2"
        elif [ "$(grep 'PATCHLEVEL = 1' /etc/*release*)" != "" ] ; then
            suse_version="SLE_11_SP1"
        else
            suse_version="SLE_11"
        fi
    elif [ "$(grep 'SUSE Linux Enterprise Server 12' /etc/*release*)" != "" ] ; then
        suse_version="SLE_12"
    fi
    
    set -e
    if [ "$(zypper repos | grep devel_languages_nodejs)" != "" ] ; then 
        zypper removerepo devel_languages_nodejs 1>>$install_log 2>&1
    fi

    zypper addrepo http://download.opensuse.org/repositories/devel:languages:nodejs/$suse_version/devel:languages:nodejs.repo 1>>$install_log 2>&1
    zypper --gpg-auto-import-keys refresh 1>>$install_log 2>&1

    #Install nodejs
    zypper install -yl nodejs 1>>$install_log 2>&1

    #Install npm
    curl -sL https://www.npmjs.org/install.sh | sh 1>>$install_log 2>&1
    set +e
}

function install_nodejs()
{
    echo "[INFO]Installing nodejs and npm"
    if [ "$(type apt-get 2>/dev/null)" != "" ] ; then
        curl -sL https://deb.nodesource.com/setup | bash - 1>>$install_log 2>&1
        apt-get -y install nodejs 1>>$install_log 2>&1
    elif [ "$(type yum 2>/dev/null)" != "" ] ; then
        curl -sL https://rpm.nodesource.com/setup | bash - 1>>$install_log 2>&1
        yum -y install nodejs 1>>$install_log 2>&1
    elif [ "$(type zypper 2>/dev/null)" != "" ] ; then
        install_nodejs_suse
    else
        echo "[ERROR]Neither apt-get, yum or zypper is found, you need to install nodejs manually."
        echo ""
        echo "    You could refer to https://github.com/joyent/node/wiki/installing-node.js-via-package-manager."
        echo ""
        echo "[ERROR]Install nodejs and npm failed. See $install_log."
        exit 1
    fi
    if [ ! $? ]; then
        echo "[ERROR]Install nodejs and npm failed. See $install_log."
        exit 1
    fi
}

echo "[INFO]Checking dependency..."
echo "" > $install_log
if [ "$(type node 2>/dev/null)" == "" ]; then
    install_nodejs
fi
echo "[INFO]  nodejs version: $(node --version)"

if [ "$(type npm 2>/dev/null)" == "" ]; then
    install_nodejs
fi
echo "[INFO]  npm version: $(npm -version)"

if [ "$(type azure 2> /dev/null)" == "" ]; then
    echo "[INFO]Installing azure-cli"
    npm install -g azure-cli 1>>$install_log 2>&1
    if [ ! $? ]; then
        echo "[ERROR]Install azure-cli failed. See $install_log."
        exit 1
    fi
fi
echo "[INFO]  azure-cli version: $(azure --version)"

npm_pkg="azure-linux-tools-1.0.0.tgz"
echo "[INFO]Installing Azure Enhanced Monitor tools..."
if [ -f ./$npm_pkg ]; then
    npm install -g ./$npm_pkg 1>>$install_log 2>&1
    if [ ! $? ]; then
        echo "[ERROR]Install Azure Enhanced Monitor tools failed. See $install_log."
        exit 1
    fi
else
    echo "[ERROR] Couldn't find npm package $npm_pkg"
    exit 1
fi

echo "[INFO]Finished."