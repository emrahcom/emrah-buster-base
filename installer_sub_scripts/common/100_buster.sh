# -----------------------------------------------------------------------------
# BUSTER.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="eb-buster"
cd $MACHINES/$MACH

ROOTFS="/var/lib/lxc/$MACH/rootfs"
DNS_RECORD=$(grep "address=/$MACH/" /etc/dnsmasq.d/eb_hosts | head -n1)
IP=${DNS_RECORD##*/}
SSH_PORT="30$(printf %03d ${IP##*.})"
echo BUSTER="$IP" >> $INSTALLER/000_source

# -----------------------------------------------------------------------------
# NFTABLES RULES
# -----------------------------------------------------------------------------
# public ssh
nft delete element eb-nat tcp2ip { $SSH_PORT } 2>/dev/null || true
nft add element eb-nat tcp2ip { $SSH_PORT : $IP }
nft delete element eb-nat tcp2port { $SSH_PORT } 2>/dev/null || true
nft add element eb-nat tcp2port { $SSH_PORT : 22 }

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_BUSTER" = true ] && exit

echo
echo "-------------------------- $MACH --------------------------"

# -----------------------------------------------------------------------------
# REINSTALL_IF_EXISTS
# -----------------------------------------------------------------------------
EXISTS=$(lxc-info -n $MACH | egrep '^State' || true)
if [ -n "$EXISTS" -a "$REINSTALL_BUSTER_IF_EXISTS" != true ]
then
    echo "Already installed. Skipped..."
    echo
    echo "Please set REINSTALL_BUSTER_IF_EXISTS in $APP_CONFIG"
    echo "if you want to reinstall this container"

    echo DONT_RUN_BUSTER_CUSTOM=true >> $INSTALLER/000_source
    exit
fi

# -----------------------------------------------------------------------------
# CONTAINER SETUP
# -----------------------------------------------------------------------------
# remove the old container if exists
set +e
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
lxc-destroy -n $MACH
rm -rf /var/lib/lxc/$MACH
sleep 1
set -e

# create the new one
lxc-create -n $MACH -t download -P /var/lib/lxc/ -- \
    -d debian -r buster -a $ARCH

# shared directories
mkdir -p $SHARED/cache
cp -arp $MACHINE_HOST/usr/local/eb/cache/buster_apt_archives $SHARED/cache/

# container config
rm -rf $ROOTFS/var/cache/apt/archives
mkdir -p $ROOTFS/var/cache/apt/archives
sed -i '/^lxc\.net\./d' /var/lib/lxc/$MACH/config
sed -i '/^# Network configuration/d' /var/lib/lxc/$MACH/config
sed -i 's/^lxc.apparmor.profile.*$/lxc.apparmor.profile = unconfined/' \
    /var/lib/lxc/$MACH/config

cat >> /var/lib/lxc/$MACH/config <<EOF
lxc.mount.entry = $SHARED/cache/buster_apt_archives \
var/cache/apt/archives none bind 0 0

# Network configuration
lxc.net.0.type = veth
lxc.net.0.link = $BRIDGE
lxc.net.0.name = eth0
lxc.net.0.flags = up
lxc.net.0.ipv4.address = $IP/24
lxc.net.0.ipv4.gateway = auto
EOF

# changed/added system files
echo nameserver $HOST > $ROOTFS/etc/resolv.conf
cp etc/network/interfaces $ROOTFS/etc/network/
cp etc/apt/sources.list $ROOTFS/etc/apt/
cp etc/apt/apt.conf.d/80disable-recommends $ROOTFS/etc/apt/apt.conf.d/

# start container
lxc-start -n $MACH -d
lxc-wait -n $MACH -s RUNNING
sleep 3

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
# update
lxc-attach -n $MACH -- apt-get $APT_PROXY_OPTION update; sleep 3
lxc-attach -n $MACH -- apt-get $APT_PROXY_OPTION -y dist-upgrade
lxc-attach -n $MACH -- apt-get $APT_PROXY_OPTION -y install apt-utils

# packages
lxc-attach -n $MACH -- apt-get $APT_PROXY_OPTION -y install zsh
lxc-attach -n $MACH -- \
    zsh -c \
    "apt-get $APT_PROXY_OPTION -y install openssh-server openssh-client
     apt-get $APT_PROXY_OPTION -y install cron logrotate
     apt-get $APT_PROXY_OPTION -y install dbus libpam-systemd
     apt-get $APT_PROXY_OPTION -y install wget ca-certificates"

# -----------------------------------------------------------------------------
# SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
# tzdata
lxc-attach -n $MACH -- \
    zsh -c \
    "echo $TIMEZONE > /etc/timezone
     rm -f /etc/localtime
     ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime"

# ssh
cp etc/ssh/sshd_config $ROOTFS/etc/ssh/

# -----------------------------------------------------------------------------
# ROOT USER
# -----------------------------------------------------------------------------
# ssh
if [ -f /root/.ssh/authorized_keys ]
then
    mkdir $ROOTFS/root/.ssh
    cp /root/.ssh/authorized_keys $ROOTFS/root/.ssh/
    chmod 700 $ROOTFS/root/.ssh
    chmod 600 $ROOTFS/root/.ssh/authorized_keys
fi

# eb_scripts
mkdir $ROOTFS/root/eb_scripts
cp root/eb_scripts/update_debian.sh $ROOTFS/root/eb_scripts/
cp root/eb_scripts/upgrade_debian.sh $ROOTFS/root/eb_scripts/
chmod 744 $ROOTFS/root/eb_scripts/update_debian.sh
chmod 744 $ROOTFS/root/eb_scripts/upgrade_debian.sh

# -----------------------------------------------------------------------------
# CONTAINER SERVICES
# -----------------------------------------------------------------------------
lxc-stop -n $MACH
lxc-wait -n $MACH -s STOPPED
