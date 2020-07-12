#!/usr/bin/env bash
#
# 2020-06-25	madd	init
#
# vi:set bg=dark

## locales US English ##
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_COLLATE=C
export LC_CTYPE=en_US.UTF-8

source /etc/os-release
export LOG="$HOME/${0}_$(date +%FT%T|tr : -).log"
export ERR="$HOME/${0}_$(date +%FT%T|tr : -).err"
export LOGS=" > $LOG 2> $ERR"
export GITDIR="/opt/git"
export GITREPO="https://github.com/MaddSauer/os-init-setup.git"

export DNF="dnf -y "

[[ $ID = "fedora" ]] && VALID_OS="LGTM"
[[ $VALID_OS = "LGTM" ]] || exit 1

PKG="vim git etckeeper tcpdump bind-utils ontainer-selinux selinux-policy-base containerd dnf-plugins-core "
touch $LOG $ERR

echo "# install rpm packages ..."
for p in $PKG
do
  echo "# .. $p"
  $DNF install $p || exit 1
done >> $LOG 2>> $ERR
echo " ... done"
rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm >> $LOG 2>> $ERR

# vim config 
grep -q 'tabstop' /etc/vimrc || cat >> /etc/vimrc <<EOF
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set background=dark
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >> $LOG 2>> $ERR

grep -q 'locales US English' /etc/profile.d/sh.local || cat >> /etc/profile.d/sh.local <<EOF
## locales US English ##
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_COLLATE=C
export LC_CTYPE=en_US.UTF-8
export EDITOR=vi
##

EOF

test -d $GITDIR || mkdir $GITDIR
cd $GITDIR

git clone $GITREPO >> $LOG 2>> $ERR
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0" >> $LOG 2>> $ERR
systemctl enable --now docker >> $LOG 2>> $ERR
etcdkeeper init >> $LOG 2>> $ERR
etcdkeeper commit >> $LOG 2>> $ERR

curl -sfL https://get.k3s.io | sh -
