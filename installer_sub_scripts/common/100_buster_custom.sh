# -----------------------------------------------------------------------------
# BUSTER_CUSTOM.SH
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
[ "$BUSTER_SKIPPED" = true ] && exit
[ "$DONT_RUN_BUSTER_CUSTOM" = true ] && exit

echo
echo "---------------------- $MACH CUSTOM -----------------------"

# start container
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING

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

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    "set -e
     export DEBIAN_FRONTEND=noninteractive
     apt-get $APT_PROXY_OPTION -y install less tmux vim autojump
     apt-get $APT_PROXY_OPTION -y install curl dnsutils iputils-ping
     apt-get $APT_PROXY_OPTION -y install htop bmon bwm-ng
     apt-get $APT_PROXY_OPTION -y install rsync bzip2 man-db ack"

# -----------------------------------------------------------------------------
# ROOT USER
# -----------------------------------------------------------------------------
# shell
lxc-attach -n $MACH -- chsh -s /bin/zsh root
cp root/.bashrc $ROOTFS/root/
cp root/.vimrc $ROOTFS/root/
cp root/.zshrc $ROOTFS/root/
cp root/.tmux.conf $ROOTFS/root/

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
