#! /bin/bash

sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf

echo "$IPADDRESS  $FQDN $SHORT" >> /etc/hosts

rpm -e --nodeps sles-release
SUSEConnect -r $SUMAPROXYREGCODE -p SUSE-Manager-Proxy/4.2/x86_64
SUSEConnect -p sle-module-basesystem/15.3/x86_64
SUSEConnect -p sle-module-server-applications/15.3/x86_64
SUSEConnect -p sle-module-suse-manager-proxy/4.2/x86_64
zypper install -y man man-pages-posix man-pages rsyslog vim-data aaa_base-extras wget zypper-log
systemctl enable --now rsyslog
zypper in -t pattern suma_proxy documentation enhanced_base yast2_basis yast2_server
zypper patch -y
zypper patch -y
mandb -c

sh -c 'echo root:linux | chpasswd'