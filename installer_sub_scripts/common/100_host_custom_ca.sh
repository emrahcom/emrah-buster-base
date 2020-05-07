#!/bin/bash

# -----------------------------------------------------------------------------
# HOST_CUSTOM_CA.SH
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
[ "$DONT_RUN_HOST_CUSTOM_CA" = true ] && exit

echo
echo "---------------------- HOST CUSTOM CA ---------------------"

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive

# added packages
apt-get $APT_PROXY_OPTION -y install openssl

# -----------------------------------------------------------------------------
# CA CERTIFICATE & KEY
# -----------------------------------------------------------------------------
# the CA key and the CA certificate
[ ! -d "/root/eb_ssl" ] && mkdir /root/eb_ssl

if [ ! -f "/root/eb_ssl/eb_CA.crt" ]
then
    cd /root/eb_ssl
    rm -f eb_CA.key

    openssl req -nodes -new -x509 -days 10950 \
        -keyout eb_CA.key -out eb_CA.pem \
        -subj "/O=emrah-buster/OU=CA/CN=emrah-buster $DATE-$RANDOM"

    openssl x509 -outform der -in eb_CA.pem -out eb_CA.crt
fi
