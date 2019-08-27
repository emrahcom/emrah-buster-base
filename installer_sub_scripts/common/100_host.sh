#!/bin/bash

# -----------------------------------------------------------------------------
# HOST.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="eb-host"
cd $MACHINES/$MACH

echo
echo "-------------------------- HOST ---------------------------"

# -----------------------------------------------------------------------------
# RUN or EXIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_HOST" = true ] && echo 'Skipped...' && exit

# -----------------------------------------------------------------------------
# BACKUP & STATUS
# -----------------------------------------------------------------------------
OLD_FILES="/root/eb_old_files/$DATE"
mkdir -p $OLD_FILES

# process status
echo "# ----- ps auxfw -----" >> $OLD_FILES/ps.status
ps auxfw >> $OLD_FILES/ps.status

# deb status
echo "# ----- dpkg -l -----" >> $OLD_FILES/dpkg.status
dpkg -l >> $OLD_FILES/dpkg.status

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# load the bridge module before the possible kernel update
[ -n "$(command -v modprobe)" ] && [ -z "$(lsmod | grep bridge)" ] && \
    modprobe bridge
# load the veth module before the possible kernel update
[ -n "$(command -v modprobe)" ] && [ -z "$(lsmod | grep veth)" ] && \
    modprobe veth

# upgrade
apt-get $APT_PROXY_OPTION -yd dist-upgrade
apt-get $APT_PROXY_OPTION -y upgrade
apt-get $APT_PROXY_OPTION -y install apt-utils

# added packages
apt-get $APT_PROXY_OPTION -y install lxc debootstrap bridge-utils
apt-get $APT_PROXY_OPTION -y install dnsmasq
apt-get $APT_PROXY_OPTION -y install xz-utils gnupg
apt-get $APT_PROXY_OPTION -y install wget ca-certificates
