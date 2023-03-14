#! /bin/bash

sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf

echo "$IPADDRESS  $FQDN $SHORT" >> /etc/hosts

#ip addr add $STATIC dev eth2
ip route replace default via $GATEWAY dev eth2

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

    # Run SUMA Setup
    cp /tmp/setup_env.sh /root/setup_env.sh
    /usr/lib/susemanager/bin/mgr-setup -s

    # Configure First User in webUI
    curl -s -k -X POST https://localhost/rhn/newlogin/CreateFirstUser.do\
>   -d "submitted=true" \
>   -d "orgName=SUMALABS" \
>   -d "login=admin" \
>   -d "desiredpassword=sumapass" \
>   -d "desiredpasswordConfirm=sumapass" \
>   -d "email=lab-noise@labs.suse.com" \
>   -d "firstNames=Administrator" \
>   -d "lastName=Administrator" \
>   -o /dev/null

    # First SCC Sync
    mgr-sync refresh

    # Mirror Products 15 SP3 and 15 SP4
    mgr-sync add channels\
    sle-product-sles15-sp3-pool-x86_64 sle-product-sles15-sp3-updates-x86_64\
    sle-module-basesystem15-sp3-pool-x86_64 sle-module-basesystem15-sp3-updates-x86_64\
    sle-manager-tools15-pool-x86_64-sp3 sle-manager-tools15-updates-x86_64-sp3\
    sle-module-server-applications15-sp3-pool-x86_64 sle-module-server-applications15-sp3-updates-x86_64\
    sle-product-sles15-sp4-pool-x86_64 sle-product-sles15-sp4-updates-x86_64\
    sle-module-basesystem15-sp4-pool-x86_64 sle-module-basesystem15-sp4-updates-x86_64\
    sle-manager-tools15-pool-x86_64-sp4 sle-manager-tools15-updates-x86_64-sp4\
    sle-module-server-applications15-sp4-pool-x86_64 sle-module-server-applications15-sp4-updates-x86_64

else
  echo "Deployment not recognized."
fi

sed -i "s/\$SUBNET/${SUBNET}/g" /tmp/hosts
cp /tmp/hosts /etc/hosts
sh -c 'echo root:sumapass | chpasswd'
echo "Finished deploying suma_server ${DEPLOYMENT} configurations."