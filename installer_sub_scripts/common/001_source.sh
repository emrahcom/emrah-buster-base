#!/bin/bash

# -----------------------------------------------------------------------------
# SOURCE.SH
# -----------------------------------------------------------------------------
set -e
SOURCE=$INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
echo
echo "-------------------------- SOURCE -------------------------"

# -----------------------------------------------------------------------------
# PRE-SOURCE PACKAGES
# -----------------------------------------------------------------------------
apt-get $APT_PROXY_OPTION -y install procps

# -----------------------------------------------------------------------------
# SET GLOBAL VARIABLES
# -----------------------------------------------------------------------------
# Version
VERSION=$(git log --date=format:'%Y%m%d-%H%M' | egrep -i '^date:' | \
          head -n1 | awk '{print $2}')
echo "export VERSION=$VERSION" >> $SOURCE

# Architecture
ARCH=$(dpkg --print-architecture)
echo "export ARCH=$ARCH" >> $SOURCE

# RAM capacity
RAM=$(free -m | grep Mem: | awk '{ print $2 }')
echo "export RAM=$RAM" >> $SOURCE

# Am I in LXC container?
[ -n "$(env | grep 'container=lxc')" ] && \
    echo "export AM_I_IN_LXC=true" >> $SOURCE

[ -z "$TIMEZONE" ] && \
    echo "export TIMEZONE=$(cat /etc/timezone)" >> $SOURCE

# always return true
true
