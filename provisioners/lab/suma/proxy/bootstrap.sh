#! /bin/bash

sed -i 's/rpm.install.excludedocs = yes/rpm.install.excludedocs = no/' /etc/zypp/zypp.conf

sed -i "s/\$SUBNET/${SUBNET}/g" /tmp/hosts
cp /tmp/hosts /etc/hosts

version=$(grep -Po '(?<=VERSION_ID=")[^"]*' /etc/os-release)

if [[ "$version" == "15.4" ]]; then
  echo "Performing actions for VERSION_ID 15.4"
  SUSEConnect -r $SLEREGCODE
  zypper install -y --oldpackage suseconnect-ng-1.1.0~git2.f42b4b2a060e-150400.3.13.1
  SUSEConnect --de-register
  SUSEConnect --cleanup
  rpm -e --nodeps sles-release
  SUSEConnect -r $SUMAPROXYREGCODE -p SUSE-Manager-Proxy/4.3/x86_64
  SUSEConnect -p sle-module-basesystem/15.4/x86_64
  SUSEConnect -p sle-module-server-applications/15.4/x86_64
  SUSEConnect -p sle-module-suse-manager-proxy/4.3/x86_64

elif [[ "$version" == "15.3" ]]; then
  # Do something when VERSION_ID is 15.3
  echo "Performing actions for VERSION_ID 15.3"
  rpm -e --nodeps sles-release
  SUSEConnect -r $SUMAPROXYREGCODE -p SUSE-Manager-Proxy/4.2/x86_64
  SUSEConnect -p sle-module-basesystem/15.3/x86_64
  SUSEConnect -p sle-module-server-applications/15.3/x86_64
  SUSEConnect -p sle-module-suse-manager-proxy/4.2/x86_64
else
  # Do something when VERSION_ID is neither 15.4 nor 15.3
  echo "Unknown VERSION_ID: $version"
fi

## Depency issue with python-base and python-xml (temporary I think)
# Technically could wait to patch until bootstrapped to SUMA, so not the worst thing.

zypper install -y man man-pages-posix man-pages rsyslog vim-data aaa_base-extras wget zypper-log
systemctl enable --now rsyslog
zypper in -y -t pattern suma_proxy documentation enhanced_base yast2_basis yast2_server
zypper patch -y
zypper patch -y
mandb -c

sh -c 'echo root:proxypass | chpasswd'
