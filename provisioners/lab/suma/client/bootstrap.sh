#! /bin/bash

if [ -f /etc/zypp/zypp.conf ]; then
    sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
fi

systemctl disable --now firewalld

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

if hostname | grep sap12sp5; then
    rpm -e --nodeps sles-release
    SUSEConnect -p SLES_SAP/12.5/x86_64 -r $SAPREGCODE
    SUSEConnect --de-register
    SUSEConnect --cleanup
    rm -rf /etc/zypp/{credentials,services,repos}.d/*

echo "StrictHostKeyChecking no" >>/etc/ssh/ssh_config

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl reload sshd