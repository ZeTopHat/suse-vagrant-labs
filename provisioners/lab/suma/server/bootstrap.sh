#! /bin/bash

sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf

#ip addr add $STATIC dev eth2
ip route replace default via $GATEWAY dev eth2
sed -i "s/\$SUBNET/${SUBNET}/g" /tmp/hosts
cp /tmp/hosts /etc/hosts

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
zypper install -y spacecmd spacewalk-utils* salt-bash-completion expect
zypper install -y -t pattern documentation enhanced_base suma_server yast2_basis yast2_server
zypper patch -y
zypper patch -y
mandb -c
timedatectl set-timezone America/Denver

if [ $DEPLOYMENT == "training" ]; then
  echo "training"
elif [ $DEPLOYMENT == "fulldeploy" ]; then
  echo "fulldeploy"

  # Run SUMA Setup
  cp /tmp/setup_env.sh /root/setup_env.sh
  /usr/lib/susemanager/bin/mgr-setup -s

  # Configure First User in webUI
  curl -s -k -X POST https://localhost/rhn/newlogin/CreateFirstUser.do -d "submitted=true" -d "orgName=SUMALABS" -d "login=admin" -d "desiredpassword=sumapass" -d "desiredpasswordConfirm=sumapass" -d "email=lab-noise@labs.suse.com" -d "firstNames=Administrator" -d "lastName=Administrator" -o /dev/null
  
  sleep 80
  # May already be running from the SUMA setup, but is useful for verification, caching the password, and an example of expect working (hopefully).
  /usr/bin/expect -c "set timeout -1; set username \"admin\"; set password \"sumapass\"; spawn mgr-sync refresh; expect -re \"Login:\" { send \"\$username\r\"; exp_continue } -re \"Password:\" { send \"\$password\r\"; exp_continue } eof"

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

  ## Automatic Bootstrapping (Not a priority yet, but some steps below)
  ## Is a bit tricky because you have to wait for the packages to sync, at least for sle-manager tools. 
  ## It might be better to do that if there is an external database to load. That could be useful for some dev environments and testing, not necessarily for training.

  #sleep 15
  ## Create the first activation key, and bootstrap script
  # spacecmd -u admin -p sumapass -- activationkey_create -n sles15sp3 -d sles15sp3 -b sle-product-sles15-sp3-pool-x86_64
  # mgr-bootstrap --activation-keys=1-sles15sp3 --script=bootstrap-sles15sp3.sh --force-bundle
  
  ## Better to manually copy sshkeys, but will do later.
  # expect -c "set timeout 1; set host client1; spawn ssh \$host; expect -re \"Are you sure you want to continue connecting\" { send \"yes\r\"; exp_continue } -re \".*password:\" { send \"\x003\"; exp_continue } eof"
  
  ## Some Vagrant boxes are missing the logrotate package, trick to add it here.
  # mgr-create-bootstrap-repo -c SLE-15-SP3-x86_64 logrotate

  ## Bootstrap (make sure the /etc/hosts is set correctly on the client)
  # spacecmd -u admin -p sumapass -- system_bootstrap -H "client1" -u "root" -P "linux" -a "1-sles15sp3"

else
  echo "Deployment not recognized."
fi

sh -c 'echo root:sumapass | chpasswd'
echo "Finished deploying suma_server ${DEPLOYMENT} configurations."