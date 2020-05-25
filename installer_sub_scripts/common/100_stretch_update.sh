# -----------------------------------------------------------------------------
# STRETCH_UPDATE.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="eb-stretch"
cd $MACHINES/$MACH

ROOTFS="/var/lib/lxc/$MACH/rootfs"

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$STRETCH_SKIPPED" != true ] && exit
[ "$DONT_RUN_STRETCH_UPDATE" = true ] && exit

echo
echo "---------------------- $MACH UPDATE -----------------------"

# start container
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING
lxc-attach -n $MACH -- ping -c1 deb.debian.org

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- \
    zsh -c \
    "set -e
     export DEBIAN_FRONTEND=noninteractive

     for i in 1 2 3; do
         apt -y update && sleep 3 && break
         sleep 1
     done

     apt-get $APT_PROXY_OPTION -y dist-upgrade"

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
