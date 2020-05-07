#!/bin/bash

# -----------------------------------------------------------------------------
# HOST_CUSTOM.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="eb-host"
cd $MACHINES/$MACH

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_HOST_CUSTOM" = true ] && exit

echo
echo "---------------------- HOST CUSTOM ------------------------"

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive

# upgrade
apt-get $APT_PROXY_OPTION -yd dist-upgrade
apt-get $APT_PROXY_OPTION -y upgrade

# added packages
apt-get $APT_PROXY_OPTION -y install cron
apt-get $APT_PROXY_OPTION -y install zsh tmux vim autojump
apt-get $APT_PROXY_OPTION -y install htop iotop bmon bwm-ng
apt-get $APT_PROXY_OPTION -y install iputils-ping fping whois dnsutils
apt-get $APT_PROXY_OPTION -y install wget curl rsync
apt-get $APT_PROXY_OPTION -y install bzip2 rsync ack jq
apt-get $APT_PROXY_OPTION -y install net-tools rsyslog

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
# changed/added system files
cp etc/cron.d/eb_update /etc/cron.d/

# -----------------------------------------------------------------------------
# ZSH
# -----------------------------------------------------------------------------
# zsh lxc autocomplete function
cp usr/local/share/zsh/site-functions/_lxc /usr/local/share/zsh/site-functions/

# -----------------------------------------------------------------------------
# OPENNTPD
# -----------------------------------------------------------------------------
# install openntpd if I'm not in LXC container
if [ "$AM_I_IN_LXC" != true ]
then
    apt-get $APT_PROXY_OPTION -y install openntpd
    cp etc/default/openntpd /etc/default/
    systemctl restart openntpd.service
fi

# -----------------------------------------------------------------------------
# ROOT USER
# -----------------------------------------------------------------------------
# rc files
[ ! -f "/root/.bashrc" ] && cp root/.bashrc /root/
[ ! -f "/root/.vimrc" ] && cp root/.vimrc /root/
[ ! -f "/root/.zshrc" ] && cp root/.zshrc /root/
[ ! -f "/root/.tmux.conf" ] && cp root/.tmux.conf /root/

# added directories
mkdir -p /root/eb_scripts

# changed/added files
cp root/eb_scripts/update_debian.sh /root/eb_scripts/
cp root/eb_scripts/update_container.sh /root/eb_scripts/
cp root/eb_scripts/upgrade_debian.sh /root/eb_scripts/
cp root/eb_scripts/upgrade_container.sh /root/eb_scripts/
cp root/eb_scripts/upgrade_all.sh /root/eb_scripts/

# file permissions
chmod u+x /root/eb_scripts/update_debian.sh
chmod u+x /root/eb_scripts/update_container.sh
chmod u+x /root/eb_scripts/upgrade_debian.sh
chmod u+x /root/eb_scripts/upgrade_container.sh
chmod u+x /root/eb_scripts/upgrade_all.sh
