#! /bin/bash

if [ -f /etc/zypp/zypp.conf ]; then
    sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
fi


sed -i "s/\$SUBNET/${SUBNET}/g" /tmp/hosts
cp /tmp/hosts /etc/hosts

sh -c 'echo root:linux | chpasswd'