#!/bin/bash

# -----------------------------------------------------------------------------
# SOURCE.SH
# -----------------------------------------------------------------------------
set -e
SOURCE=$INSTALLER/000_source

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
echo
echo "-------------------------- SOURCE -------------------------"

# -----------------------------------------------------------------------------
# PRE-SOURCE PACKAGES
# -----------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
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

# The host is in LXC container?
[ "$(stat -c '%i' /)" -gt 1000 ] && \
    echo "export IS_IN_LXC=true" >> $SOURCE

[ -z "$TIMEZONE" ] && \
    echo "export TIMEZONE=$(cat /etc/timezone)" >> $SOURCE

# always return true
true
