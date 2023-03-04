#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "auth389" ]; then
  # tls/ssl parameters
  mkdir /root/certs/
  mv /tmp/{config-ca,config-auth389} /root/certs/
  openssl genrsa -out /root/certs/ca.key 2048
  openssl genrsa -out /root/certs/auth389.key 2048
  openssl req -x509 -new -nodes -key /root/certs/ca.key -sha256 -days 36500 -out /root/certs/ca.pem -config /root/certs/config-ca
  openssl req -new -key /root/certs/auth389.key -out /root/certs/auth389.csr -config /root/certs/config-auth389
  openssl x509 -req -in /root/certs/auth389.csr -CA /root/certs/ca.pem -CAkey /root/certs/ca.key -CAcreateserial -out /root/certs/auth389.pem -days 36499 -sha256
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    zypper install -y 389-ds lib389
    mv /tmp/template.inf /root/template.inf
    dscreate from-file /root/template.inf
    mv /tmp/.dsrc* /root/
    ln -s /root/.dsrc.local /root/.dsrc
    dsidm auth389 user create --uid geeko --cn geeko --displayName "ldap geeko" --uidNumber 4321 --gidNumber 100 --homeDirectory /home/geeko
    dsidm auth389 account reset_password uid=geeko,ou=people,dc=auth389,dc=suse,dc=com vagrant389
    dsidm auth389 group create --cn 389admins
    dsidm auth389 group add_member 389admins uid=geeko,ou=people,dc=auth389,dc=suse,dc=com
    dsconf auth389 config replace nsslapd-security=on && dsconf auth389 config replace nsslapd-dynamic-plugins=on
    dsconf auth389 plugin memberof enable && dsconf auth389 plugin memberof set --scope dc=auth389,dc=suse,dc=com
    dsconf auth389 plugin memberof fixup -f '(objectClass=*)' dc=auth389,dc=suse,dc=com
    dsconf auth389 security ca-certificate add --file /root/certs/ca.pem --name 'SUSE_LABS'
    dsctl auth389 tls import-server-key-cert /root/certs/auth389.pem /root/certs/auth389.key
    cp /root/certs/ca.pem /etc/pki/trust/anchors/ca.pem && update-ca-certificates && dsctl auth389 restart
    mkdir /etc/ssl/auth389 && cp /root/certs/ca.pem /etc/ssl/auth389/ && c_rehash /etc/ssl/auth389/
    # client configuration to self
    zypper install -y sssd sssd-ldap sssd-tools
    mv /etc/sssd/sssd.conf{,.orig} && dsidm auth389 client_config sssd.conf >/etc/sssd/sssd.conf && chmod 600 /etc/sssd/sssd.conf
    # Within the Vagrantfile SHELL "\\" are needed for each "/". In the bootstrap.sh only "\" is needed for "/"
    sed -r -i 's/^ldap_uri.*/ldap_uri = ldaps:\/\/auth389.labs.suse.com/' /etc/sssd/sssd.conf
    sed -r -i 's/^ldap_tls_cacertdir.*/ldap_tls_cacertdir = \/etc\/ssl\/auth389/' /etc/sssd/sssd.conf
    sed -r -i 's/^ldap_access_order.*/ldap_access_order = expire/' /etc/sssd/sssd.conf
    pam-config -a --mkhomedir --sss && sed -ri 's/:.*compat/: compat sss/' /etc/nsswitch.conf && systemctl start sssd;
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
