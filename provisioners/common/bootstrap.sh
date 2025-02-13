#! /bin/bash

ENVIRONMENT=$1

if [ "$ENVIRONMENT" == "SLE12" ]; then
  echo "Deploying common SLE 12 configurations..."
  SUSEConnect -r $SLEREGCODE
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y --force ntp man man-pages-posix man-pages rsyslog aaa_base-extras wget zypper-log bash-doc logrotate $(for i in $(rpm -qa); do rpm -q -s $i | grep "not installed" | grep -E "man" >/dev/null; if [[ "$?" == "0" ]]; then echo $i; fi;  done)
  mandb >/dev/null 2>&1
  mandb -c >/dev/null 2>&1 &
  echo "server $NTPSERVER iburst" >>/etc/ntp.conf
  systemctl restart ntpd
  systemctl enable ntpd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "SLE15" ]; then
  echo "Deploying common SLE 15 configurations..."
  SUSEConnect -r $SLEREGCODE
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  # Images since 15 SP6 only have kernel-default-base installed by default. This is problematic when the usual expected kernel modules are suddenly missing. e.g. tcp_iscsi
  if ! rpm -q kernel-default > /dev/null 2>&1; then
    zypper --non-interactive install --force-resolution -y kernel-default-$(uname -r | sed 's/-default/.1/' )
    zypper rm -y kernel-default-base
  fi
  zypper install -y --force chrony man man-pages-posix man-pages wget zypper-log bash-doc $(for i in $(rpm -qa); do rpm -q -s $i | grep "not installed" | grep -E "man" >/dev/null; if [[ "$?" == "0" ]]; then echo $i; fi;  done)
  mandb -c >/dev/null 2>&1 &
  echo "maxdistance 16.0" >>/etc/chrony.conf
  echo "server $NTPSERVER" >>/etc/chrony.conf
  systemctl restart chronyd
  systemctl enable chronyd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "LEAP42" ]; then
  echo "Deploying common LEAP 42 configurations..."
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y --force ntp man man-pages-posix man-pages rsyslog aaa_base-extras wget zypper-log bash-doc logrotate $(for i in $(rpm -qa); do rpm -q -s $i | grep "not installed" | grep -E "man" >/dev/null; if [[ "$?" == "0" ]]; then echo $i; fi;  done)
  mandb >/dev/null 2>&1
  mandb -c >/dev/null 2>&1 &
  echo "server $NTPSERVER iburst" >>/etc/ntp.conf
  systemctl restart ntpd
  systemctl enable ntpd
  echo "$IPADDRESS $FQDN $SHORT" >>/etc/hosts
elif [ "$ENVIRONMENT" == "LEAP15" ]; then
  echo "Deploying common LEAP 15 configurations..."
  sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf
  zypper install -y --force chrony man man-pages-posix man-pages rsyslog aaa_base-extras wget zypper-log bash-doc logrotate $(for i in $(rpm -qa); do rpm -q -s $i | grep "not installed" | grep -E "man" >/dev/null; if [[ "$?" == "0" ]]; then echo $i; fi;  done)
  mandb >/dev/null 2>&1
  mandb -c >/dev/null 2>&1 &
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
  # curl -Sks https://<SUMASERVER>/pub/bootstrap/bootstrap-rhel88.sh | /bin/bash
  # After accepting key in suma we want a "dnf install screen" and then a "dnf update"
elif [ "$ENVIRONMENT" == "OE8" ]; then
  hostnamectl set-hostname $FQDN
  # curl -Sks https://<SUMASERVER>/pub/bootstrap/bootstrap-oel8.sh | /bin/bash
  # After accepting key in suma we want a "dnf install screen" and then a "dnf update"
elif [ "$ENVIRONMENT" == "OE6" ]; then
  hostname $FQDN
  # curl -Sks https://<SUMASERVER>/pub/bootstrap/bootstrap-oel6.sh | /bin/bash
  # After accepting key in suma we want a "yum install screen" and then a "yum update"
else
  echo "Environment not recognized."
fi

echo "Finished deploying common configurations."
