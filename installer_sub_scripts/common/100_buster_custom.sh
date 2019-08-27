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
    "apt-get $APT_PROXY_OPTION update
     sleep 3
     apt-get $APT_PROXY_OPTION -y dist-upgrade"

# packages
lxc-attach -n $MACH -- \
    zsh -c \
    "apt-get $APT_PROXY_OPTION -y install less tmux vim autojump
     apt-get $APT_PROXY_OPTION -y install curl dnsutils iputils-ping
     apt-get $APT_PROXY_OPTION -y install htop bmon bwm-ng
     apt-get $APT_PROXY_OPTION -y install rsync bzip2 man-db ack-grep"

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
