#! /bin/bash

sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf

echo "$IPADDRESS  $FQDN $SHORT" >> /etc/hosts

sh -c 'echo root:linux | chpasswd'