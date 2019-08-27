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

echo
echo "---------------------- HOST CUSTOM ------------------------"

# -----------------------------------------------------------------------------
# RUN or EXIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_HOST_CUSTOM" = true ] && echo 'Skipped...' && exit

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# upgrade
apt-get $APT_PROXY_OPTION -yd dist-upgrade
apt-get $APT_PROXY_OPTION -y upgrade

# added packages
apt-get $APT_PROXY_OPTION -y install cron
apt-get $APT_PROXY_OPTION -y install zsh tmux vim
apt-get $APT_PROXY_OPTION -y install htop iotop bmon bwm-ng
apt-get $APT_PROXY_OPTION -y install iputils-ping fping whois dnsutils
apt-get $APT_PROXY_OPTION -y install wget curl rsync
apt-get $APT_PROXY_OPTION -y install bzip2 rsync ack-grep jq
apt-get $APT_PROXY_OPTION -y install net-tools rsyslog

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
# changed/added system files
cp etc/cron.d/eb_update /etc/cron.d/

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
