#! /bin/bash

sed -i "s/\$SUBNET/${SUBNET}/g" /tmp/hosts
cp /tmp/hosts /etc/hosts

if [ -f /etc/zypp/zypp.conf ]; then
    sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
fi

if hostname | grep sap15sp5; then
    rpm -e --nodeps sles-release
    SUSEConnect -p SLES_SAP/15.5/x86_64 -r $SAPREGCODE
    SUSEConnect -p sle-module-basesystem/15.5/x86_64
    SUSEConnect -p sle-module-desktop-applications/15.5/x86_64
    SUSEConnect -p sle-module-server-applications/15.5/x86_64
    SUSEConnect -p sle-ha/15.5/x86_64 -r $SAPREGCODE
    SUSEConnect -p sle-module-sap-applications/15.5/x86_64
    SUSEConnect --de-register
    SUSEConnect --cleanup
    rm -rf /etc/zypp/{credentials,services,repos}.d/*
fi

if hostname | grep sap12sp5; then
    rpm -e --nodeps sles-release
    SUSEConnect -p SLES_SAP/12.5/x86_64 -r $SAPREGCODE
    SUSEConnect --de-register
    SUSEConnect --cleanup
    rm -rf /etc/zypp/{credentials,services,repos}.d/*
fi

if grep -q 'ID=ubuntu' /etc/os-release; then
    cat > /etc/sudoers.d/zz-sumaclient.conf << EOF
# https://documentation.suse.com/suma/4.3/en/suse-manager/client-configuration/clients-ubuntu.html
<user>  ALL=NOPASSWD: /usr/bin/python, /usr/bin/python2, /usr/bin/python3, /var/tmp/venv-salt-minion/bin/python
EOF
    chmod 0440 /etc/sudoers.d/zz-sumaclient.conf
else
    echo "This is not an Ubuntu system. Exiting."
fi

echo "StrictHostKeyChecking no" >>/etc/ssh/ssh_config

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl reload sshd

systemctl disable --now firewalld
sh -c 'echo root:linux | chpasswd'

echo -e "\nClient $(hostname) Provisioning Complete"