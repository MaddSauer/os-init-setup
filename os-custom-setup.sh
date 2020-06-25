#!/usr/bin/env bash
#
# 2020-06-25	madd	init
#
# vi:set bg=dark

## US English ##
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_COLLATE=C
export LC_CTYPE=en_US.UTF-8

source /etc/os-release
export DNF=dnf
export LOG="$HOME/${0}_$(date +%FT%T|tr : -).log"
export ERR="$HOME/${0}_$(date +%FT%T|tr : -).err"
export LOGS=" > $LOG 2> $ERR"

[[ $ID = "fedora" ]] && VALID_OS="LGTM"
[[ $ID = "centos" ]] \
	&& VALID_OS="LGTM" \
	&& DNF=yum

[[ $VALID_OS = "LGTM" ]] || exit 1

PKG="vim git epel-release"
PKG_epel="etckeeper"
PKG_elrepo="drbd-kmod"

touch $LOG $ERR
echo "# install packages ..."

for p in $PKG
do
	$DNF -y install $p || exit 1
done >> $LOG 2>> $ERR

echo " ... $PKG"
echo " ... done"

echo " install elrepo .."
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org  >> $LOG 2>> $ERR
echo " ... done"

grep -q tabstop /etc/vimrc || cat >> /etc/vimrc <<EOF
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set background=dark
EOF

#git
# yum install -y https://centos7.iuscommunity.org/ius-release.rpm
# yum install -y yum-plugin-replace
# yum replace -y git --replace-with git2u-all
