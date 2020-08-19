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

PKG="vim git etckeeper tcpdump bind-utils container-selinux selinux-policy-base containerd dnf-plugins-core moby-engine dnf-automatic snapd"
touch $LOG $ERR

echo "# install rpm packages ..."
for p in $PKG
do
  echo "# .. $p"
  $DNF install $p || exit 1
done >> $LOG 2>> $ERR
echo " ... done"
etckeeper init >> $LOG 2>> $ERR
etckeeper commit init >> $LOG 2>> $ERR

timedatectl set-timezone UTC

ln -s /var/lib/snapd/snap /snap

# add helm via snap
snap install helm --classic >> $LOG 2>> $ERR



# vim config 
grep -q 'tabstop' /etc/vimrc || cat >> /etc/vimrc <<EOF
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set background=dark
EOF
etckeeper commit vim-config >> $LOG 2>> $ERR

grep -q 'alias k9s' /etc/profile.d/sh.local || cat >> /etc/profile.d/sh.local <<EOF
export LANG='en_US.UTF-8'
export LANGUAGE='en_US.UTF-8'
export LC_COLLATE='C'
export LC_CTYPE='en_US.UTF-8'
export EDITOR='vi'
export HISTTIMEFORMAT="%F %T "
export HISTSIZE='10000'
export HISTCONTROL='ignorespace:erasedups'
export HISTIGNORE='ls:ps:history'
##

## alias
alias kk='k3s kubectl'
alias k9s='k9s --kubeconfig /etc/rancher/k3s/k3s.yaml'
##

EOF
etckeeper commit bash-config >> $LOG 2>> $ERR

#dnf-automatic
sed -i \
  -e "s/^apply_updates = no/apply_updates = yes/" \
  -e "/^email_to = root/email_to = hostmaster@sauer.ms/" \
  -e '/^email_from = root@example.org/email_from = root@$HOSTNAME' \
  /etc/dnf/automatic.conf
systemctl  enable --now  dnf-automatic.timer
etckeeper commit dnf-config >> $LOG 2>> $ERR

#k3s
rpm -i https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm >> $LOG 2>> $ERR

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >> $LOG 2>> $ERR
etckeeper commit k3s-k8s-config >> $LOG 2>> $ERR

echo '8021q' > /etc/modules-load.d/8021q.conf
modeprobe 8021q


ssh-keygen -t ed25519 -P '' -f /root/.ssh/id_ed25519
cat >> /root/.ssh/authorized_keys <<KEY
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIz4T2XEElqFQKLbW5fmwo1nRSYURMP7MvfPlROVYBPkU/tQpal8X9wg99dYW6XtGLrqH/i4fVJYzt//1WQ4aiF4H00tJBpm76tROhLXV3XigVC46mnr362F+Nnmr9s3Q9tzBAGSzJnt1Efo9nhXnvFI5l4HqHXve0NcVM2CaftDelanuIQ9GYJJmRiVmfku9nD0AQ0g1lblTwg4Lx7S7gKjtUvQMHbeC6N9O1SvQDeVqJ2ldFNn0TM3OEXM1LioVTaYj5sftnC6sfp0wfKegTkdWel/u6YhmCLImquTSPHK43QxKnYY9dSROLmzLBcP6Ld3+3dUGJGmuWVoUUlzY8JiKduEz6B0Ux/lM5HOvUarKn8KX5ynJv3uvh2pNFr8pv2FsquYn2XknB92vSz3kfqA3DrbWcLcVPrj3KZ0/3e9PFz46Jjit6dp3rEmRCoLuPc6BFqp2ctUdxYgTjyciSnJrwSdUVAiQroIpnNCpQBTFRibjUojnDgNsV82EovBJBrOqgsscIKSxvtvdWhjgNT+Ikmab7uqLNq26GEOja5OzpAoCfRAZ0uDWyqc7z8O165wsn1LhESvdYQOhQIGWeSyi69JlzZjFy94TcuQOtNwldIhQHtbLSp0+XEHvpNl+47glzj7hum3/CPCxQHRzYo9/imEmTI9RvQe6p2laGBw== root@jaspis
KEY

test -d $GITDIR || mkdir $GITDIR
cd $GITDIR

git clone $GITREPO >> $LOG 2>> $ERR
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0" >> $LOG 2>> $ERR
systemctl enable --now docker >> $LOG 2>> $ERR

curl -sfL https://get.k3s.io | sh - >> $LOG 2>> $ERR

curl -sfL https://github.com/derailed/k9s/releases/download/v0.21.2/k9s_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin/ >> $LOG 2>> $ERR

true
