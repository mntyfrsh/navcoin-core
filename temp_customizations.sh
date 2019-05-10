#!/bin/sh
#
###
## Configure Ubuntu 18.04 and build navdroid packages
###
#
#



DIR=`pwd`
PARENTDIR="$(dirname "$dir")"
export DEBIAN_FRONTEND=noninteractive

## VERSION determines the deb package build version identifier and should be updated to match the desired release
VERSION="4.6.0"
## DEBUG set to yes|no. yes configures bootstrap to download from specified URL
DEBUG="yes"
## Bootstrap URL
if [ $DEBUG = "yes" ]; then
	# local boostrap
	BOOTSTRAP='--no-check-certificate https://192.168.0.10/bootstrap-navcoin_mainnet.tar'
else
	# remote bootstrap
	BOOTSTRAP='https://s3.amazonaws.com/navcoin-bootstrap/bootstrap-navcoin_mainnet.tar'
fi



# set timezone to UTC
timedatectl set-timezone UTC

# add odroid user
useradd -m -G sudo,ssh,users -u 6021 -p Om16ojfOaLNA6 -s /bin/bash odroid

# sudoers
echo "Cmnd_Alias NAV_CMDS = /sbin/reboot -f, /sbin/shutdown now, /bin/systemctl start navcoin, /bin/systemctl stop navcoin, /bin/systemctl restart navcoin, /bin/systemctl start navcoin-core, /bin/systemctl stop navcoin-core, /bin/systemctl restart navcoin-core, /bin/systemctl start navcoin-repair, /bin/systemctl stop navcoin-repair, /bin/systemctl start navcoin-angular, /bin/systemctl stop navcoin-angular, /bin/systemctl restart navcoin-angular, /bin/systemctl start navcoin-express, /bin/systemctl stop navcoin-express, /bin/systemctl restart navcoin-express, /bin/systemctl start navdroid, /bin/systemctl stop navdroid, /bin/systemctl restart navdroid" >> /etc/sudoers
echo "odroid ALL=NOPASSWD: NAV_CMDS" >> /etc/sudoers

# add repo
add-apt-repository -y ppa:bitcoin/bitcoin

# update apt
apt -y update
DEBIAN_FRONTEND=noninteractive apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
DEBIAN_FRONTEND=noninteractive apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" dist-upgrade
apt -y autoremove

PKGLIST="build-essential\
        libcurl3-dev\
        libssl-dev\
        libtool\
        autotools-dev\
        automake\
        pkg-config\
        libevent-dev\
        bsdmainutils\
        libqrencode-dev\
        libboost-all-dev\
        libminiupnpc-dev\
        synaptic\
        htop\
        libunbound-dev\
        libzmq3-dev\
        zram-config\
        git\
        libdb4.8-dev\
        libdb4.8++-dev\
        ntp\
        ntpdate\
        sysstat\
        screen\
        checkinstall\
        vim\
        openssh-server\
        ufw\
        curl\
        dh-make\
        pkg-config\
	nodejs\
	net-tools\
        bzr-builddeb"

# install packages
apt -y install $PKGLIST
apt -y --fix-broken install
apt -y autoremove

# install npm manually because current package has broken dependencies
curl -L https://www.npmjs.com/install.sh | sudo sh

# set vim as default editor
update-alternatives --set editor /usr/bin/vim.basic

# fix date/time with ntpdate
service ntp stop && sleep 5 && ntpdate -u time.google.com
service ntp start

# enable ssh
systemctl enable ssh

# configure ufw firewall
ufw allow ssh
ufw allow http
ufw allow https
ufw allow from any proto tcp port 4200
ufw enable

# disable services
systemctl disable alsa-restore
systemctl disable cups
systemctl disable cups-browsed
systemctl disable openvpn
systemctl disable wpa_supplicant

# clear bash history
#history -c
cat /dev/null > ~/.bash_history

# clear root password and thus disable ssh login
passwd -d root




##############################
# build navcoin-core package #
##############################
cd /home/odroid
git clone https://github.com/navcoin/navcoin-core.git
cd navcoin-core
./autogen.sh
./configure CFLAGS="-O2 -mtune=cortex-a15.cortex-a7 -mfpu=neon" CXXFLAGS="-O2 -mtune=cortex-a15.cortex-a7 -mfpu=neon" --enable-hardening --without-gui
make -j3

# checkinstall to generate dpkg
checkinstall -D -y --maintainer "info@navcoin.org" --pkgname navcoin-core --pkgversion $VERSION --requires ntp --include=navdroid/navdroid_files --install=no --backup=no --pakdir=$PARENTDIR


# bootstrap
cd /tmp
wget $BOOTSTRAP
mkdir /home/odroid/.navcoin4 && chown odroid:odroid /home/odroid/.navcoin4
tar -C /home/odroid/.navcoin4/ -xf bootstrap-navcoin_mainnet.tar && rm -f /tmp/bootstrap-navcoin_mainnet.tar
chown -R odroid:odroid /home/odroid/.navcoin4
rm -f /tmp/bootstrap_navcoin_mainnet.tar


#################################
# build navcoin-angular package #
#################################
cd /home/odroid
git clone https://github.com/Encrypt-S/navcoin-angular.git
cd /home/odroid/navcoin-angular
./create_package.sh


#################################
# build navcoin-express package #
#################################
cd /home/odroid
git clone https://github.com/Encrypt-S/navcoin-express.git
cd /home/odroid/navcoin-express
./create_package.sh



### EOF ###
