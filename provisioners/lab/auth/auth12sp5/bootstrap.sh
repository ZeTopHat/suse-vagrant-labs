#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "auth12sp5" ]; then
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    zypper install -y krb5-client samba-client samba-libs samba-winbind openldap2-client cyrus-sasl-gssapi adcli sssd sssd-ldap sssd-ad sssd-tools
    echo "server ${SUBNET}.26 iburst" >>/etc/ntp.conf
    sed -r -i 's/^NTPD_FORCE_SYNC_ON_STARTUP.*$/NTPD_FORCE_SYNC_ON_STARTUP="yes"/' /etc/sysconfig/ntp
    sed -r -i 's/^NTPD_FORCE_SYNC_HWCLOCK_ON_STARTUP.*$/NTPD_FORCE_SYNC_HWCLOCK_ON_STARTUP="yes"/' /etc/sysconfig/ntp
    systemctl stop ntpd; ntpdate ${SUBNET}.26; systemctl start ntpd; systemctl enable ntpd
    mv /etc/krb5.conf{,.orig}
    mv /tmp/krb5.conf /etc/krb5.conf
    chown root:root /etc/krb5.conf
    mv /etc/samba/smb.conf{,.orig}
    mv /tmp/smb.conf /etc/samba/smb.conf
    chown root:root /etc/samba/smb.conf
    sed -r -i 's/^passwd.*$/passwd: compat winbind/' /etc/nsswitch.conf
    sed -r -i 's/^group.*$/group: compat winbind/' /etc/nsswitch.conf
    sed -r -i 's/^shadow.*$/shadow: compat winbind/' /etc/nsswitch.conf
    echo "krb5_auth = yes" >> /etc/security/pam_winbind.conf
    echo "krb5_ccache_type = FILE" >> /etc/security/pam_winbind.conf
    echo "BASE dc=labs,dc=suse,dc=com" >>/etc/openldap/ldap.conf
    echo "URI ldap://labs.suse.com" >>/etc/openldap/ldap.conf
    sed -r -i 's/^search.*$//' /etc/resolv.conf
    sed -r -i 's/^nameserver.*$//' /etc/resolv.conf
    echo "search labs.suse.com" >>/etc/resolv.conf
    echo "nameserver ${SUBNET}.26" >>/etc/resolv.conf
    # need to add net-config steps here
    net ads join -U Administrator%vagrant
    pam-config -a --mkhomedir --winbind
    systemctl start winbind && systemctl enable winbind
    echo "To change to SSSD from winbind:" >/root/change.txt
    echo "# cp /etc/sssd/sssd.conf{,.orig}" >>/root/change.txt
    echo "# mv /tmp/sssd.conf /etc/sssd/sssd.conf" >>/root/change.txt
    echo "# chmod 600 /etc/sssd/sssd.conf" >>/root/change.txt
    echo "# chown root:root /etc/sssd/sssd.conf" >>/root/change.txt
    echo "# systemctl start sssd && systemctl enable sssd" >>/root/change.txt
    echo "# sed -r -i 's/^passwd.*$/passwd: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^group.*$/group: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^shadow.*$/shadow: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# pam-config -d --winbind && pam-config -a --sss" >>/root/change.txt
    echo "# systemctl stop winbind && systemctl disable winbind" >>/root/change.txt
    echo "" >>/root/change.txt
    echo "To change back to Winbind from SSSD:" >>/root/change.txt
    echo "# systemctl start winbind && systemctl enable winbind" >>/root/change.txt
    echo "# sed -r -i 's/^passwd.*$/passwd: compat winbind/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^group.*$/group: compat winbind/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^shadow.*$/shadow: compat winbind/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# pam-config -d --sss && pam-config -a --winbind" >>/root/change.txt
    echo "# systemctl stop sssd && systemctl disable sssd" >>/root/change.txt
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
