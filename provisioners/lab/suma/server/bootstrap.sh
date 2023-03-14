#! /bin/bash

sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf

echo "$IPADDRESS  $FQDN $SHORT" >> /etc/hosts

#ip addr add $STATIC dev eth2
#ip route replace default via $GATEWAY dev eth2

mkdir -p /tmp/data-backup/var/cache/
mkdir -p /var/lib/pgsql/
mkdir -p /var/spacewalk/
rsync -avzh /var/cache/ /tmp/data-backup/var/cache/
rm -rf /var/cache/*
pvcreate /dev/vdb
vgcreate sumadata /dev/vdb
lvcreate -n var_cache -L 15G sumadata
lvcreate -n var_lib_pgsql -L 55G sumadata
lvcreate -n var_spacewalk -l 100%FREE sumadata
mkfs.ext4 /dev/sumadata/var_cache
mkfs.ext4 /dev/sumadata/var_lib_pgsql
mkfs.ext4 /dev/sumadata/var_spacewalk
echo "/dev/sumadata/var_cache /var/cache ext4 defaults 0 0" >> /etc/fstab
echo "/dev/sumadata/var_lib_pgsql /var/lib/pgsql ext4 defaults 0 0" >> /etc/fstab
echo "/dev/sumadata/var_spacewalk /var/spacewalk ext4 defaults 0 0" >> /etc/fstab
mount -a
rsync -avzh /tmp/data-backup/var/cache/ /var/cache/
rm -rf /tmp/data-backup
rpm -e --nodeps sles-release
SUSEConnect -r $SUMAREGCODE -p SUSE-Manager-Server/4.2/x86_64
SUSEConnect -p sle-module-basesystem/15.3/x86_64
SUSEConnect -p sle-module-server-applications/15.3/x86_64
SUSEConnect -p sle-module-web-scripting/15.3/x86_64
SUSEConnect -p sle-module-suse-manager-server/4.2/x86_64
SUSEConnect -p sle-module-desktop-applications/15.3/x86_64
SUSEConnect -p sle-module-development-tools/15.3/x86_64
SUSEConnect -p sle-module-python2/15.3/x86_64
zypper install -y man man-pages-posix man-pages rsyslog vim-data aaa_base-extras wget zypper-log
systemctl enable --now rsyslog
zypper install -y spacecmd spacewalk-utils* salt-bash-completion
zypper install -y -t pattern documentation enhanced_base suma_server yast2_basis yast2_server
zypper patch -y
zypper patch -y
mandb -c


if [ $DEPLOYMENT == "training" ]; then
  echo "training"
elif [ $DEPLOYMENT == "fulldeploy" ]; then
    echo "fulldeploy"
    export MANAGER_FORCE_INSTALL='0'
    export ACTIVATE_SLP='n'
    export MANAGER_ADMIN_EMAIL='susemanager@labs.suse.com'
    export MANAGER_ENABLE_TFTP='y'
    export MANAGER_IP="$(ip address show eth2 | grep 'inet ' | awk '{print $2}'| cut -d'/' -f1))"
    export MANAGER_DB_PORT='5432'
    export DB_BACKEND='postgresql'
    export MANAGER_DB_HOST='localhost'
    export MANAGER_DB_NAME='susemanager'
    export MANAGER_DB_PROTOCOL='TCP'
    export MANAGER_PASS='sumapass'
    export MANAGER_PASS2='sumapass'
    export MANAGER_USER='susemanager'
    export LOCAL_DB='1'
    export CERT_CITY='Pleasant Grove'
    export CERT_COUNTRY='US'
    export CERT_EMAIL='susemanager@labs.suse.com'
    export CERT_O='SUSE'
    export CERT_OU='SUSE Support'
    export CERT_PASS='sumapass'
    export CERT_PASS2='sumapass'
    export CERT_STATE='UT'
    export RHN_USER='admin'
    export RHN_PASS='sumapass'
    export SCC_USER="$SCCORGUSER"
    export SCC_PASS="$SCCORGPASS"
    /usr/lib/susemanager/bin/mgr-setup -s

    # Mirror Products Needed 15 SP3 (basic stuff)
    # Mirror Products Needed 12 SP5 (basic stuff)
    # Mirror Products Needed 15 SP4 (basic stuff)
    # Mirror Products Needed SUMA Proxy 4.3 (basic stuff)

else
  echo "Deployment not recognized."
fi

sh -c 'echo root:sumapass | chpasswd'
echo "Finished deploying suma_server ${DEPLOYMENT} configurations."