#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "authldap" ]; then
    echo "${SUBNET}.21 authkrb5.labs.suse.com authkrb5" >>/etc/hosts
    # ssl/tls section
    mkdir /root/certs/
    mv /tmp/{config-ca,config-authldap} /root/certs/
    openssl genrsa -out /root/certs/ca.key 2048
    openssl genrsa -out /root/certs/authldap.key 2048
    openssl req -x509 -new -nodes -key /root/certs/ca.key -sha256 -days 36500 -out /root/certs/ca.pem -config /root/certs/config-ca
    openssl req -new -key /root/certs/authldap.key -out /root/certs/authldap.csr -config /root/certs/config-authldap
    openssl x509 -req -in /root/certs/authldap.csr -CA /root/certs/ca.pem -CAkey /root/certs/ca.key -CAcreateserial -out /root/certs/authldap.pem -days 36499 -sha256
    mkdir /etc/openldap/certs && sudo cp /root/certs/ca.pem /etc/openldap/certs/ca.pem && c_rehash /etc/openldap/certs/
    cp /root/certs/ca.pem /etc/pki/trust/anchors/ca-SUSE_LABS.pem && update-ca-certificates
    cp /root/certs/authldap.{key,pem} /etc/openldap/certs/
    groupadd ldap -g 70 </dev/null 2>&1
    useradd -s /bin/bash -d /var/lib/ldap -c "User for OpenLDAP" -u 76 -g 70 ldap >/dev/null 2>&1
    chmod 750 /etc/openldap/certs && chmod 640 /etc/openldap/certs/{ca.pem,authldap.*} && chgrp -R ldap /etc/openldap/certs
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    zypper install -y openldap2 openldap2-client
    sed -r -i 's/^OPENLDAP_START_LDAPS.*$/OPENLDAP_START_LDAPS="yes"/' /etc/sysconfig/openldap
    sed -r -i 's/^OPENLDAP_START_LDAPI.*$/OPENLDAP_START_LDAPI="yes"/' /etc/sysconfig/openldap
    sed -r -i 's/^OPENLDAP_CONFIG_BACKEND.*$/OPENLDAP_CONFIG_BACKEND="ldap"/' /etc/sysconfig/openldap
    mv /etc/openldap/slapd.conf{,.bak} && touch /etc/openldap/slapd.conf
    slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
    sed -r -i 's/# CRC32.*$//' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif
    sed -r -i '/^$/d' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif
    sed -r -i 's/^olcAccess.*$/olcAccess: \{0\}to \* by dn\.exact\=gidNumber\=0\+uidNumber\=0\,cn\=peercred\,cn\=external\,cn\=auth manage by \* break/' /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif
    chown -R ldap:ldap /etc/openldap/slapd.d
    chmod 700 /etc/openldap/slapd.d
    systemctl restart slapd && systemctl enable slapd
    mkdir /root/ldifs/
    mv /tmp/*.ldif /root/ldifs/
    # Needed to use MD5 because it doesn't use the forward slash character which caused issues with future sed commands
    slappasswd -h "{MD5}" -s vagrant >/root/.passwordhash
    chmod 600 /root/.passwordhash
    sed -r -i "s/^olcRootPW.*$/olcRootPW\: $(cat \/root\/.passwordhash)/" /root/ldifs/rootpw.ldif
    sed -r -i "s/^olcRootPW.*$/olcRootPW\: $(cat \/root\/.passwordhash)/" /root/ldifs/hdb.ldif
    ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/ldifs/rootpw.ldif
    for i in {core,cosine,nis,inetorgperson}; do ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/$i.ldif; done
    ldapadd -Y EXTERNAL -H ldapi:/// -f /root/ldifs/hdb.ldif
    ldapadd -x -D cn=admin,dc=authldap,dc=suse,dc=com -w vagrant -f /root/ldifs/authldap-admin-users-groups.ldif
    ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/ldifs/tls.ldif
    # Client section
    zypper install -y openldap2-client nss_ldap pam_ldap pam_ldap-32bit
    mv /etc/ldap.conf{,.orig}
    mv /tmp/direct-ldap.conf /etc/ldap.conf
    chown root:root /etc/ldap.conf
    echo "vagrant" > /etc/ldap.secret && chmod 600 /etc/ldap.secret
    echo "BASE dc=authldap,dc=suse,dc=com" >>/etc/openldap/ldap.conf
    echo "URI ldaps://authldap.labs.suse.com" >>/etc/openldap/ldap.conf
    echo "TLS_CERT /etc/openldap/certs/authldap.pem" >>/etc/openldap/ldap.conf
    echo "TLSCACERT /etc/openldap/certs/ca.pem" >>/etc/openldap/ldap.conf
    pam-config -a --mkhomedir --ldap && sed -ri 's/:.*compat/: compat ldap/' /etc/nsswitch.conf
    ldapadd -x -w vagrant -D "cn=admin,dc=authldap,dc=suse,dc=com" -f /root/ldifs/ldapdude.ldif
    echo "To change to SSSD from direct ldap:" >/root/change.txt
    echo "# zypper install krb5-client sssd sssd-32bit sssd-ldap sssd-tools" >>/root/change.txt
    echo "# cp /etc/sssd/sssd.conf{,.orig}" >>/root/change.txt
    echo "# rsync -ahP rabble.suse.cloud::rabble/Team_Files/training/labs/auth/fulldeploy/ldap-sssd.conf /etc/sssd/sssd.conf" >>/root/change.txt
    echo "# chmod 600 /etc/sssd/sssd.conf" >>/root/change.txt
    echo "# systemctl start sssd && systemctl enable sssd" >>/root/change.txt
    echo "# sed -r -i 's/^passwd.*$/passwd: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^group.*$/group: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# sed -r -i 's/^shadow.*$/shadow: compat sss/' /etc/nsswitch.conf" >>/root/change.txt
    echo "# pam-config -d --ldap && pam-config -a --sss" >>/root/change.txt
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
