#!/bin/bash

# -----------------------------------------------------------------------------
# NETWORK.SH
# -----------------------------------------------------------------------------
set -e
source $INSTALLER/000_source

# -----------------------------------------------------------------------------
# ENVIRONMENT
# -----------------------------------------------------------------------------
MACH="eb-host"
cd $MACHINES/$MACH

# public interface
DEFAULT_ROUTE=$(ip route | egrep '^default ' | head -n1)
PUBLIC_INTERFACE=${DEFAULT_ROUTE##*dev }
PUBLIC_INTERFACE=${PUBLIC_INTERFACE/% */}
echo PUBLIC_INTERFACE="$PUBLIC_INTERFACE" >> $INSTALLER/000_source

# IP address
DNS_RECORD=$(grep 'address=/host/' etc/dnsmasq.d/eb_hosts | \
    head -n1)
IP=${DNS_RECORD##*/}
echo HOST="$IP" >> $INSTALLER/000_source

# remote IP address
REMOTE_IP=$(ip addr show $PUBLIC_INTERFACE | ack "$PUBLIC_INTERFACE$" | \
            xargs | cut -d " " -f 2 | cut -d "/" -f1)
echo REMOTE_IP="$REMOTE_IP" >> $INSTALLER/000_source

# -----------------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------------
[ "$DONT_RUN_NETWORK_INIT" = true ] && exit

echo
echo "------------------------ NETWORK --------------------------"

# -----------------------------------------------------------------------------
# BACKUP & STATUS
# -----------------------------------------------------------------------------
OLD_FILES="/root/eb_old_files/$DATE"
mkdir -p $OLD_FILES

# backup the files which will be changed
[ -f /etc/nftables.conf ] && cp /etc/nftables.conf $OLD_FILES/
[ -f /etc/network/interfaces ] && cp /etc/network/interfaces $OLD_FILES/
[ -f /etc/resolv.conf ] && cp /etc/resolv.conf $OLD_FILES/
[ -f /etc/issue ] && cp /etc/issue $OLD_FILES/
[ -f /etc/dnsmasq.d/eb_hosts ] && \
    cp /etc/dnsmasq.d/eb_hosts $OLD_FILES/

# network status
echo "# ----- ip addr -----" >> $OLD_FILES/network.status
ip addr >> $OLD_FILES/network.status
echo >> $OLD_FILES/network.status
echo "# ----- ip route -----" >> $OLD_FILES/network.status
ip route >> $OLD_FILES/network.status

# nftables status
if [ "$(systemctl is-active nftables.service)" = "active" ]
then
    echo "# ----- nft list ruleset -----" >> $OLD_FILES/nftables.status
    nft list ruleset >> $OLD_FILES/nftables.status
fi

# -----------------------------------------------------------------------------
# PACKAGES
# -----------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive

# removed packages
apt-get -y remove iptables

# added packages
apt-get $APT_PROXY_OPTION -y install nftables

# -----------------------------------------------------------------------------
# NETWORK CONFIG
# -----------------------------------------------------------------------------
# changed/added system files
cp etc/dnsmasq.d/eb_hosts /etc/dnsmasq.d/

# /etc/network/interfaces
[ -z "$(egrep '^source-directory\s*interfaces.d' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source-directory\s*/etc/network/interfaces.d' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/\*$' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/\*$' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/\*\.cfg' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/\*\.cfg' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*interfaces.d/eb_bridge.cfg' /etc/network/interfaces || true)" ] && \
[ -z "$(egrep '^source\s*/etc/network/interfaces.d/eb_bridge.cfg' /etc/network/interfaces || true)" ] && \
echo -e "\nsource /etc/network/interfaces.d/eb_bridge.cfg" >> /etc/network/interfaces

# IP forwarding
cp etc/sysctl.d/eb_ip_forward.conf /etc/sysctl.d/
sysctl -p /etc/sysctl.d/eb_ip_forward.conf

# -----------------------------------------------------------------------------
# BRIDGE CONFIG
# -----------------------------------------------------------------------------
# private bridge interface for the containers
BR_EXISTS=$(brctl show | egrep "^$BRIDGE\s" || true)
[ -z "$BR_EXISTS" ] && brctl addbr $BRIDGE
ip link set $BRIDGE up
IP_EXISTS=$(ip a show dev $BRIDGE | egrep "inet $IP/24" || true)
[ -z "$IP_EXISTS" ] && ip addr add dev $BRIDGE $IP/24 brd 172.22.22.255

rm -f /etc/network/interfaces.d/eb_bridge
cp etc/network/interfaces.d/eb_bridge.cfg /etc/network/interfaces.d/
sed -i "s/#BRIDGE#/${BRIDGE}/g" /etc/network/interfaces.d/eb_bridge.cfg
cp etc/dnsmasq.d/eb_interface /etc/dnsmasq.d/
sed -i "s/#BRIDGE#/${BRIDGE}/g" /etc/dnsmasq.d/eb_interface

# -----------------------------------------------------------------------------
# NFTABLES
# -----------------------------------------------------------------------------
# recreate the custom tables
if [[ "$RECREATE_CUSTOM_NFTABLES" = true ]]
then
    nft delete table inet eb-filter 2>/dev/null || true
    nft delete table ip eb-nat 2>/dev/null || true
fi

# table: eb-filter
# chains: input, forward, output
# rules: drop from the public interface to the private internal network
nft add table inet eb-filter
nft add chain inet eb-filter \
    input { type filter hook input priority 0 \; }
nft add chain inet eb-filter \
    forward { type filter hook forward priority 0 \; }
nft add chain inet eb-filter \
    output { type filter hook output priority 0 \; }
[[ -z "$(nft list chain inet eb-filter output | \
ack 'ip daddr 172.22.22.0/24 drop')" ]] && \
    nft add rule inet eb-filter output \
    iif $PUBLIC_INTERFACE ip daddr 172.22.22.0/24 drop

# table: eb-nat
# chains: prerouting, postrouting, output, input
# rules: masquerade
nft add table ip eb-nat
nft add chain ip eb-nat prerouting \
    { type nat hook prerouting priority 0 \; }
nft add chain ip eb-nat postrouting \
    { type nat hook postrouting priority 100 \; }
nft add chain ip eb-nat output \
    { type nat hook output priority 0 \; }
nft add chain ip eb-nat input \
    { type nat hook input priority 0 \; }
[[ -z "$(nft list chain ip eb-nat postrouting | \
ack 'ip saddr 172.22.22.0/24 masquerade')" ]] && \
    nft add rule ip eb-nat postrouting \
    ip saddr 172.22.22.0/24 masquerade

# table: eb-nat
# chains: prerouting
# maps: tcp2ip, tcp2port
# rules: tcp dnat
nft add map ip eb-nat tcp2ip \
    { type inet_service : ipv4_addr \; }
nft add map ip eb-nat tcp2port \
    { type inet_service : inet_service \; }
[[ -z "$(nft list chain ip eb-nat prerouting | \
ack 'tcp dport map @tcp2ip:tcp dport map @tcp2port')" ]] && \
    nft add rule ip eb-nat prerouting \
    iif $PUBLIC_INTERFACE dnat \
    tcp dport map @tcp2ip:tcp dport map @tcp2port

# table: eb-nat
# chains: prerouting
# maps: udp2ip, udp2port
# rules: udp dnat
nft add map ip eb-nat udp2ip \
    { type inet_service : ipv4_addr \; }
nft add map ip eb-nat udp2port \
    { type inet_service : inet_service \; }
[[ -z "$(nft list chain ip eb-nat prerouting | \
ack 'udp dport map @udp2ip:udp dport map @udp2port')" ]] && \
    nft add rule ip eb-nat prerouting \
    iif $PUBLIC_INTERFACE dnat \
    udp dport map @udp2ip:udp dport map @udp2port

# -----------------------------------------------------------------------------
# NETWORK RELATED SERVICES
# -----------------------------------------------------------------------------
# dnsmasq
systemctl stop dnsmasq.service
systemctl start dnsmasq.service

# nftables
systemctl enable nftables.service

# -----------------------------------------------------------------------------
# STATUS
# -----------------------------------------------------------------------------
ip addr
