#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "authkrb5" ]; then
  echo "192.168.0.23 authldap.labs.suse.com authldap" >>/etc/hosts
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    zypper install -y krb5 krb5-server krb5-client
    mv /var/lib/kerberos/krb5kdc/kdc.conf{,.orig}
    mv /tmp/kdc.conf /var/lib/kerberos/krb5kdc/kdc.conf
    chown root:root /var/lib/kerberos/krb5kdc/kdc.conf
    mv /etc/krb5.conf{,.orig}
    mv /tmp/kdc-krb5.conf /etc/krb5.conf
    chown root:root /etc/krb5.conf
    /usr/lib/mit/sbin/kdb5_util create -r AUTHKRB5.LABS.SUSE.COM -s -P krbvagrant
    /usr/lib/mit/sbin/kadmin.local add_principal -pw krbvagrant geeko/admin
    /usr/lib/mit/sbin/kadmin.local add_principal -pw krbvagrant geeko
    /usr/lib/mit/sbin/kadmin.local add_principal -pw krbvagrant ldapdude
    echo "*/admin@AUTHKRB5.LABS.SUSE.COM *" >>/var/lib/kerberos/krb5kdc/kadm5.acl
    systemctl enable --now krb5kdc kadmind
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin get_privs
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin add_principal -randkey ldap/authldap.labs.suse.com@AUTHKRB5.LABS.SUSE.COM
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin ktadd -k /root/ldap.keytab ldap/authldap.labs.suse.com
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin add_principal -randkey host/authldap.labs.suse.com@AUTHKRB5.LABS.SUSE.COM
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin ktadd -k /root/authldap.keytab host/authldap.labs.suse.com
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin add_principal -randkey host/authkrb5.labs.suse.com@AUTHKRB5.LABS.SUSE.COM
    /usr/lib/mit/bin/kadmin -w krbvagrant -p geeko/admin ktadd -k /etc/krb5.keytab host/authkrb5.labs.suse.com
    echo "To complete authldap as a kerberos service:" >/root/authldap.txt
    echo "# scp /root/ldap.keytab authldap:/etc/openldap/" >>/root/authldap.txt
    echo "# ssh authldap chgrp ldap /etc/openldap/ldap.keytab" >>/root/authldap.txt
    echo "# ssh authldap chmod 640 /etc/openldap/ldap.keytab" >>/root/authldap.txt
    echo "May need to add additional backslashes to below command:" >>/root/authldap.txt
    echo "# ssh authldap sed -ri 's/^OPENLDAP_KRB5_KEYTAB.*/OPENLDAP_KRB5_KEYTAB=\\/etc\\/openldap\\/ldap.keytab/' /etc/sysconfig/openldap" >>/root/authldap.txt
    echo "# ssh authldap systemctl restart slapd" >>/root/authldap.txt
    zypper install -y openldap2-client krb5-plugin-kdb-ldap libndr-krb5pac0 cyrus-sasl cyrus-sasl-gssapi sssd sssd-32bit sssd-ldap sssd-tools sssd-krb5 sssd-krb5-common
    echo "BASE dc=authldap,dc=suse,dc=com" >>/etc/openldap/ldap.conf
    echo "URI ldap://authldap.labs.suse.com" >>/etc/openldap/ldap.conf
    mv /etc/sssd/sssd.conf{,.orig}
    mv /tmp/kdc-sssd.conf /etc/sssd/sssd.conf
    chmod 600 /etc/sssd/sssd.conf
    chown root:root /etc/sssd/sssd.conf
    sed -r -i 's/^passwd.*$/passwd: compat sss/' /etc/nsswitch.conf
    sed -r -i 's/^group.*$/group: compat sss/' /etc/nsswitch.conf
    sed -r -i 's/^shadow.*$/shadow: compat sss/' /etc/nsswitch.conf
    pam-config -a --mkhomedir --sss
    systemctl enable --now sssd
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
