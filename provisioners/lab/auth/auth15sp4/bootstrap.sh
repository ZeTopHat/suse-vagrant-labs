#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "auth15sp4" ]; then
  if [ "$DEPLOY" == "training" ]; then
    groupadd labcoat >/dev/null 2>&1
    useradd -G labcoat -s /bin/bash -m -d /home/scientist scientist >/dev/null 2>&1
    sed -r -i 's/^group.*$/group:          sss/' /etc/nsswitch.conf
    useradd bob >/dev/null 2>&1
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    zypper install -y krb5-client adcli sssd sssd-ldap sssd-ad sssd-tools openldap2-client cyrus-sasl-gssapi samba-client samba-libs samba-winbind
    echo "maxdistance 16.0" >>/etc/chrony.conf
    echo "server ${SUBNET}.26" >>/etc/chrony.conf
    systemctl start chronyd && systemctl enable chronyd && chronyc makestep
    mv /etc/krb5.conf{,.orig}
    mv /tmp/krb5.conf /etc/krb5.conf
    chown root:root /etc/krb5.conf
    mv /etc/sssd/sssd.conf{,.orig}
    mv /tmp/sssd.conf /etc/sssd/sssd.conf
    chmod 600 /etc/sssd/sssd.conf
    chown root:root /etc/sssd/sssd.conf
    sed -r -i 's/^passwd.*$/passwd: compat sss/' /etc/nsswitch.conf
    sed -r -i 's/^group.*$/group: compat sss/' /etc/nsswitch.conf
    sed -r -i 's/^shadow.*$/shadow: compat sss/' /etc/nsswitch.conf
    echo "BASE dc=labs,dc=suse,dc=com" >>/etc/openldap/ldap.conf
    echo "URI ldap://labs.suse.com" >>/etc/openldap/ldap.conf
    sed -r -i 's/^search.*$//' /etc/resolv.conf
    sed -r -i 's/^nameserver.*$//' /etc/resolv.conf
    echo "search labs.suse.com" >>/etc/resolv.conf
    echo "nameserver ${SUBNET}.26" >>/etc/resolv.conf
    # need to add net-config changes
    echo "vagrant" | adcli join -D labs.suse.com -U Administrator --stdin-password
    pam-config -a --mkhomedir --sss
    systemctl start sssd && systemctl enable sssd
    echo "To change to Winbind from SSSD:" >/root/change.txt
    echo "# mv /etc/samba/smb.conf{,.orig}" >>/root/change.txt
    echo "# mv /tmp/smb.conf /etc/samba/smb.conf" >>/root/change.txt
    echo "# chown root:root /etc/samba/smb.conf" >>/root/change.txt
    echo "# systemctl start winbind && systemctl enable winbind" >>/root/change.txt
    echo "# sed -r -i 's/^passwd.*$/passwd: compat winbind/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^group.*$/group: compat winbind/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^shadow.*$/shadow: compat winbind/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# pam-config -d --sss && pam-config -a --winbind" >>/root/change.txt
    echo "# systemctl stop sssd && systemctl disable sssd" >>/root/change.txt
    echo "" >>/root/change.txt
    echo "To change back to SSSD from Winbind:" >>/root/change.txt
    echo "# systemctl start sssd && systemctl enable sssd" >>/root/change.txt
    echo "# sed -r -i 's/^passwd.*$/passwd: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^group.*$/group: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^shadow.*$/shadow: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# pam-config -d --winbind && pam-config -a --sss" >>/root/change.txt
    echo "# systemctl stop winbind && systemctl disable winbind" >>/root/change.txt
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
