#! /bin/bash

ENVIRONMENT=$1

if [ "$ENVIRONMENT" == "SLE12" ]; then
  echo "Deploying common SLE 12 configurations..."
  SUSEConnect -r $SLEREGCODE
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y ntp man
  echo "server $NTPSERVER iburst" >>/etc/ntp.conf
  systemctl restart ntpd
  systemctl enable ntpd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "SLE15" ]; then
  echo "Deploying common SLE 15 configurations..."
  SUSEConnect -r $SLEREGCODE
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y vim-data chrony man
  echo "maxdistance 16.0" >>/etc/chrony.conf
  echo "server $NTPSERVER" >>/etc/chrony.conf
  systemctl restart chronyd
  systemctl enable chronyd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "LEAP42" ]; then
  echo "Deploying common LEAP 42 configurations..."
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y ntp man
  echo "server $NTPSERVER iburst" >>/etc/ntp.conf
  systemctl restart ntpd
  systemctl enable ntpd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "LEAP15" ]; then
  echo "Deploying common LEAP 15 configurations..."
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y vim-data chrony man
  echo "maxdistance 16.0" >>/etc/chrony.conf
  echo "server $NTPSERVER" >>/etc/chrony.conf
  systemctl restart chronyd
  systemctl enable chronyd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "RHE8" ]; then
  hostnamectl set-hostname $FQDN
  sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel.repo
  dnf clean all
  mv /etc/dnf/protected.d/redhat-release.conf /root/
  # curl -Sks https://suma-mainlab-1.gtslab.prv.suse.com/pub/bootstrap/bootstrap-res8.sh | /bin/bash
  # After accepting key in suma we want a "dnf install screen" and then a "dnf update"
elif [ "$ENVIRONMENT" == "OE8" ]; then
  hostnamectl set-hostname $FQDN
  # curl -Sks https://suma-mainlab-1.gtslab.prv.suse.com/pub/bootstrap/bootstrap-res8.sh | /bin/bash
  # After accepting key in suma we want a "dnf install screen" and then a "dnf update"
else
  echo "Environment not recognized."
fi

echo "Finished deploying common configurations."
