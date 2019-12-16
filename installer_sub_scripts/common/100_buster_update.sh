# -----------------------------------------------------------------------------
# BUSTER_UPDATE.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="eb-buster"
cd $MACHINES/$MACH

ROOTFS="/var/lib/lxc/$MACH/rootfs"

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$BUSTER_SKIPPED" != true ] && exit
[ "$DONT_RUN_BUSTER_UPDATE" = true ] && exit

echo
echo "---------------------- $MACH UPDATE -----------------------"

# start container
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING
lxc-attach -n $MACH -- ping -c1 debian.org

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- \
    zsh -c \
    "export DEBIAN_FRONTEND=noninteractive
     apt-get $APT_PROXY_OPTION update
     apt-get $APT_PROXY_OPTION -y dist-upgrade"

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
