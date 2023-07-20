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
lvcreate -n var_cache -L 100G sumadata
lvcreate -n var_lib_pgsql -L 150G sumadata
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

echo ""

version=$(grep -Po '(?<=VERSION_ID=")[^"]*' /etc/os-release)

if [[ "$version" == "15.4" ]]; then
  echo "Performing actions for VERSION_ID 15.4"
  rpm -e --nodeps sles-release
  SUSEConnect -r $SUMAREGCODE -p SUSE-Manager-Server/4.3/x86_64
  SUSEConnect -p sle-module-basesystem/15.4/x86_64
  SUSEConnect -p sle-module-server-applications/15.4/x86_64
  SUSEConnect -p sle-module-web-scripting/15.4/x86_64
  SUSEConnect -p sle-module-suse-manager-server/4.3/x86_64
  SUSEConnect -p sle-module-desktop-applications/15.4/x86_64
  SUSEConnect -p sle-module-development-tools/15.4/x86_64
  SUSEConnect -p sle-module-python2/15.4/x86_64

elif [[ "$version" == "15.3" ]]; then
  # Do something when VERSION_ID is 15.3
  echo "Performing actions for VERSION_ID 15.3"
  rpm -e --nodeps sles-release
  SUSEConnect -r $SUMAREGCODE -p SUSE-Manager-Server/4.2/x86_64
  SUSEConnect -p sle-module-basesystem/15.3/x86_64
  SUSEConnect -p sle-module-server-applications/15.3/x86_64
  SUSEConnect -p sle-module-web-scripting/15.3/x86_64
  SUSEConnect -p sle-module-suse-manager-server/4.2/x86_64
  SUSEConnect -p sle-module-desktop-applications/15.3/x86_64
  SUSEConnect -p sle-module-development-tools/15.3/x86_64
  SUSEConnect -p sle-module-python2/15.3/x86_64
else
  # Do something when VERSION_ID is neither 15.4 nor 15.3
  echo "Unknown VERSION_ID: $version"
fi

zypper install -y man man-pages-posix man-pages rsyslog vim-data aaa_base-extras wget zypper-log
systemctl enable --now rsyslog
zypper install -y spacecmd spacewalk-utils* salt-bash-completion expect python3-devel
zypper install -y -t pattern documentation enhanced_base suma_server yast2_basis yast2_server
zypper patch -y
zypper patch -y
mandb -c
timedatectl set-timezone America/Denver

if [ $DEPLOYMENT == "training" ]; then
  echo "training"
  #mv /tmp/sumalabs /usr/bin/sumalabs
  #chmod 755 /usr/bin/sumalabs
  mv /tmp/sumalabs_completion.sh /etc/bash_completion.d/
  mkdir -p /usr/share/rhn/sumalabs/
  echo "sccorguser: '$SCCORGUSER'" >> /usr/share/rhn/sumalabs/conf.yaml
  echo "sccorgpass: '$SCCORGPASS'" >> /usr/share/rhn/sumalabs/conf.yaml
  echo "sccemptyuser: '$SCCEMPTYUSER'" >> /usr/share/rhn/sumalabs/conf.yaml
  echo "sccemptypass: '$SCCEMPTYPASS'" >> /usr/share/rhn/sumalabs/conf.yaml
  chmod 755 /usr/share/rhn/sumalabs/conf.yaml
  cp /tmp/*.py /usr/share/rhn/sumalabs/
  cp /tmp/zzz-sumalabs.sh /etc/profile.d/
  zypper in -y python3-pip
  pip install about-time alive-progress bcrypt cffi cryptography grapheme importlib-metadata Nuitka orderedset paramiko ptyprocess pycparser PyNaCl PyYAML typing_extensions zipp zstandard 

elif [ $DEPLOYMENT == "fulldeploy" ]; then
  echo "fulldeploy"

  # Run SUMA Setup
  cp /tmp/setup_env.sh /root/setup_env.sh
  /usr/lib/susemanager/bin/mgr-setup -s

  # Configure First User in webUI
  curl -s -k -X POST https://localhost/rhn/newlogin/CreateFirstUser.do -d "submitted=true" -d "orgName=SUMALABS" -d "login=admin" -d "desiredpassword=sumapass" -d "desiredpasswordConfirm=sumapass" -d "email=lab-noise@labs.suse.com" -d "firstNames=Administrator" -d "lastName=Administrator" -o /dev/null
  
  while [[ $(systemctl is-active spacewalk.target) != "active" ]]; do
    sleep 5
  done

  sleep 5

  # May already be running from the SUMA setup, but is useful for verification, caching the password, and an example of expect working (hopefully).
  /usr/bin/expect -c "set timeout -1; set username \"admin\"; set password \"sumapass\"; spawn mgr-sync refresh; expect -re \"Login:\" { send \"\$username\r\"; exp_continue } -re \"Password:\" { send \"\$password\r\"; exp_continue } eof"

  # Mirror channels for SLES 15 SP5 
  mgr-sync add channels\
  sle-product-sles15-sp5-pool-x86_64 sle-product-sles15-sp5-updates-x86_64\
  sle-module-basesystem15-sp5-pool-x86_64 sle-module-basesystem15-sp5-updates-x86_64\
  sle-module-server-applications15-sp5-pool-x86_64 sle-module-server-applications15-sp5-updates-x86_64\
  sle-manager-tools15-pool-x86_64-sp5 sle-manager-tools15-updates-x86_64-sp5

  # Mirror channels for Proxy 4.3
  mgr-sync add channels\
  sle-product-suse-manager-proxy-4.3-pool-x86_64 sle-product-suse-manager-proxy-4.3-updates-x86_64\
  sle-module-basesystem15-sp4-pool-x86_64-proxy-4.3 sle-module-basesystem15-sp4-updates-x86_64-proxy-4.3\
  sle-module-server-applications15-sp4-pool-x86_64-proxy-4.3 sle-module-server-applications15-sp4-updates-x86_64-proxy-4.3\
  sle-module-suse-manager-proxy-4.3-pool-x86_64 sle-module-suse-manager-proxy-4.3-updates-x86_64\

  # Mirror channels for SLES 12 SP5
  mgr-sync add channels\
  sles12-sp5-pool-x86_64 sles12-sp5-updates-x86_64\
  sle-manager-tools12-pool-x86_64-sp5 sle-manager-tools12-updates-x86_64-sp5

  ### TODO, Add autobootstrapping ###
  
  ## Create the first activation key, and bootstrap script
  # spacecmd -u admin -p sumapass -- activationkey_create -n sles15sp5 -d sles15sp5 -b sle-product-sles15-sp5-pool-x86_64
  # mgr-bootstrap --activation-keys=1-sles15sp5 --script=bootstrap-sles15sp5-bundle.sh --force-bundle
  
  ## Some Vagrant boxes are missing the logrotate package, trick to add it here.
  # mgr-create-bootstrap-repo -c SLE-15-SP5-x86_64 logrotate
  
  # Probably best to provision salt conf files on client, then you just have to accept, or autoaccept can be configured.
  # Altenatievly, can use spacecmd to bootstrap, but tricky because you'd have to wait until reposync is done. 
  # spacecmd -u admin -p sumapass -- system_bootstrap -H "" -u "root" -P "linux" -a "1-sles15sp5"


elif [ $DEPLOYMENT == "fulldeploy-insane" ]; then
  echo "fulldeploy"

  # Run SUMA Setup
  cp /tmp/setup_env.sh /root/setup_env.sh
  /usr/lib/susemanager/bin/mgr-setup -s

  # Configure First User in webUI
  curl -s -k -X POST https://localhost/rhn/newlogin/CreateFirstUser.do -d "submitted=true" -d "orgName=SUMALABS" -d "login=admin" -d "desiredpassword=sumapass" -d "desiredpasswordConfirm=sumapass" -d "email=lab-noise@labs.suse.com" -d "firstNames=Administrator" -d "lastName=Administrator" -o /dev/null
  
  while [[ $(systemctl is-active spacewalk.target) != "active" ]]; do
    sleep 5
  done

  sleep 5

  # May already be running from the SUMA setup, but is useful for verification, caching the password, and an example of expect working (hopefully).
  /usr/bin/expect -c "set timeout -1; set username \"admin\"; set password \"sumapass\"; spawn mgr-sync refresh; expect -re \"Login:\" { send \"\$username\r\"; exp_continue } -re \"Password:\" { send \"\$password\r\"; exp_continue } eof"

  # Mirror channels for Proxy 4.3
  mgr-sync add channels\
  sle-product-suse-manager-proxy-4.3-pool-x86_64 sle-product-suse-manager-proxy-4.3-updates-x86_64\
  sle-module-basesystem15-sp4-pool-x86_64-proxy-4.3 sle-module-basesystem15-sp4-updates-x86_64-proxy-4.3\
  sle-module-server-applications15-sp4-pool-x86_64-proxy-4.3 sle-module-server-applications15-sp4-updates-x86_64-proxy-4.3\
  sle-module-suse-manager-proxy-4.3-pool-x86_64 sle-module-suse-manager-proxy-4.3-updates-x86_64\

  # Mirror channels for SLES 15 SP4 
  mgr-sync add channels\
  sle-product-sles15-sp4-pool-x86_64 sle-product-sles15-sp4-updates-x86_64\
  sle-module-basesystem15-sp4-pool-x86_64 sle-module-basesystem15-sp4-updates-x86_64\
  sle-module-server-applications15-sp4-pool-x86_64 sle-module-server-applications15-sp4-updates-x86_64\
  sle-manager-tools15-pool-x86_64-sp4 sle-manager-tools15-updates-x86_64-sp4

  # Mirror channels for SLES 15 SP5 
  mgr-sync add channels\
  sle-product-sles15-sp5-pool-x86_64 sle-product-sles15-sp5-updates-x86_64\
  sle-module-basesystem15-sp5-pool-x86_64 sle-module-basesystem15-sp5-updates-x86_64\
  sle-module-server-applications15-sp5-pool-x86_64 sle-module-server-applications15-sp5-updates-x86_64\
  sle-manager-tools15-pool-x86_64-sp5 sle-manager-tools15-updates-x86_64-sp5

  # Mirror channels for SLES 12 SP5
  mgr-sync add channels\
  sles12-sp5-pool-x86_64 sles12-sp5-updates-x86_64\
  sle-manager-tools12-pool-x86_64-sp5 sle-manager-tools12-updates-x86_64-sp5

  # Mirror channels for SLES for SAP 12 SP5
  mgr-sync add channels\
  sle12-sp5-sap-pool-x86_64 sle-12-sp5-sap-updates-x86_64\
  sles12-sp5-pool-x86_64-sap sles12-sp5-updates-x86_64-sap\
  sle-ha12-sp5-pool-x86_64-sap sle-ha12-sp5-updates-x86_64-sap\
  sle-manager-tools12-pool-x86_64-sap-sp5 sle-manager-tools12-updates-x86_64-sap-sp5\

  # Mirror channels for SLES for SAP 15 SP5
  mgr-sync add channels\
  sle-product-sles_sap15-sp5-pool-x86_64 sle-product-sles_sap15-sp5-updates-x86_64\
  sle-module-basesystem15-sp5-pool-x86_64-sap sle-module-basesystem15-sp5-updates-x86_64-sap\
  sle-module-desktop-applications15-sp5-pool-x86_64-sap sle-module-desktop-applications15-sp5-updates-x86_64-sap\
  sle-module-server-applications15-sp5-pool-x86_64-sap sle-module-server-applications15-sp5-updates-x86_64-sap\
  sle-product-ha15-sp5-pool-x86_64-sap sle-product-ha15-sp5-updates-x86_64-sap\
  sle-module-sap-applications15-sp5-pool-x86_64 sle-module-sap-applications15-sp5-updates-x86_64\
  sle-manager-tools15-pool-x86_64-sap-sp5 sle-manager-tools15-updates-x86_64-sap-sp5

  # mirror Channels for Alma8
  mgr-sync add channels\
  almalinux8-x86_64 almalinux8-appstream-x86_64\
  res8-manager-tools-pool-x86_64-alma res8-manager-tools-updates-x86_64-alma

  # mirror Channels for Alma9
  mgr-sync add channels\
  almalinux9-x86_64 almalinux9-appstream-x86_64\
  el9-manager-tools-pool-x86_64-alma el9-manager-tools-updates-x86_64-alma

  # mirror Channels for Amazon2
  mgr-sync add channels\
  amazonlinux2-core-x86_64\
  res-7-suse-manager-tools-x86_64-amazon

  # mirror Channels for centos7
  mgr-sync add channels\
  centos7-x86_64 centos7-updates-x86_64\
  res-7-suse-manager-tools-x86_64-centos7

  # mirror Channels for centos8
  mgr-sync add channels\
  centos8-x86_64 centos8-appstream-x86_64\
  res8-manager-tools-pool-x86_64-centos8 res8-manager-tools-updates-x86_64-centos8
  
  # mirror Channels for debian10
  mgr-sync add channels\
  debian-10-pool-amd64\
  debian-10-main-updates-amd64\
  debian-10-main-security-amd64\
  debian-10-suse-manager-tools-amd64

  # mirror Channels for debian11
  mgr-sync add channels\
  debian-11-pool-amd64\
  debian-11-main-updates-amd64\
  debian-11-main-security-amd64\
  debian-11-suse-manager-tools-amd64
  
  # mirror Channels for oracle7
  mgr-sync add channels\
  oraclelinux7-x86_64\
  res-7-suse-manager-tools-x86_64-ol7

  # mirror Channels for oracle8
  mgr-sync add channels\
  oraclelinux8-x86_64 oraclelinux8-appstream-x86_64\
  res8-manager-tools-pool-x86_64-ol8 res8-manager-tools-updates-x86_64-ol8

  # mirror Channels for oracle9
  mgr-sync add channels\
  oraclelinux9-x86_64 oraclelinux9-appstream-x86_64\
  el9-manager-tools-pool-x86_64-ol9 el9-manager-tools-updates-x86_64-ol9

  # mirror Channels for rhel7
  mgr-sync add channels\
  res7-x86_64 rhel-x86_64-server-7\
  res7-suse-manager-tools-x86_64

  # mirror Channels for rhel8
  mgr-sync add channels\
  rhel8-pool-x86_64\
  res-8-updates-x86_64 res-as-8-updates-x86_64 res-cb-8-updates-x86_64\
  res8-manager-tools-pool-x86_64 res8-manager-tools-updates-x86_64

  # mirror Channels for rhel9
  mgr-sync add channels\
  el9-pool-x86_64\
  sll-9-updates-x86_64 sll-as-9-updates-x86_64 sll-cb-9-updates-x86_64\
  el9-manager-tools-pool-x86_64 el9-manager-tools-updates-x86_64

  # mirror Channels for rocky8
  mgr-sync add channels\
  rockylinux-8-x86_64 rockylinux-8-appstream-x86_64\
  res8-manager-tools-pool-x86_64-rocky res8-manager-tools-updates-x86_64-rocky

  # mirror Channels for rocky9
  mgr-sync add channels\
  rockylinux-9-x86_64 rockylinux-9-appstream-x86_64\
  el9-manager-tools-pool-x86_64-rocky el9-manager-tools-updates-x86_64-rocky
  
  # mirror Channels for ubuntu1804
  mgr-sync add channels\
  ubuntu-18.04-pool-amd64\
  ubuntu-18.04-suse-manager-tools-amd64

  # mirror Channels for ubuntu2004
  mgr-sync add channels\
  ubuntu-2004-amd64-main-amd64\
  ubuntu-2004-amd64-main-security-amd64\
  ubuntu-2004-amd64-main-updates-amd64\
  ubuntu-20.04-suse-manager-tools-amd64

  # mirror Channels for ubuntu2204
  mgr-sync add channels\
  ubuntu-2204-amd64-main-amd64\
  ubuntu-2204-amd64-main-security-amd64\
  ubuntu-2204-amd64-main-updates-amd64\
  ubuntu-22.04-suse-manager-tools-amd64

elif [ $DEPLOYMENT == "pre-setup43" ]; then  
  echo "Deployment: pre-setup43"

else
  echo "Deployment not recognized."
fi

sh -c 'echo root:sumapass | chpasswd'
echo "Finished deploying suma_server ${DEPLOYMENT} configurations."