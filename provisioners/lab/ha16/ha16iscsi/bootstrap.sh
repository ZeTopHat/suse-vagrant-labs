#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha16iscsi" ]; then
  zypper install -y tgt
  echo "${SUBNET}${N1IP} ha16n1.labs.suse.com ha16n1" >>/etc/hosts
  echo "${SUBNET}${N2IP} ha16n2.labs.suse.com ha16n2" >>/etc/hosts
  firewall-cmd --add-port 3260/tcp
  firewall-cmd --add-port 3260/tcp --permanent
  sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
  setenforce Permissive
  mkdir /var/lib/ha16iscsi_disks
  dd if=/dev/zero of=/var/lib/ha16iscsi_disks/ha16_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/ha16iscsi_disks/ha16_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/ha16iscsi_disks/ha16_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2022-08.com.suse.labs.ha16iscsi:ha16>" >/etc/tgt/conf.d/ha16.conf
  echo "  backing-store /var/lib/ha16iscsi_disks/ha16_disk01.img" >>/etc/tgt/conf.d/ha16.conf
  echo "  backing-store /var/lib/ha16iscsi_disks/ha16_disk02.img" >>/etc/tgt/conf.d/ha16.conf
  echo "  backing-store /var/lib/ha16iscsi_disks/ha16_disk03.img" >>/etc/tgt/conf.d/ha16.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.ha16n1:initiator01" >>/etc/tgt/conf.d/ha16.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.ha16n2:initiator02" >>/etc/tgt/conf.d/ha16.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/ha16.conf
  echo "</target>" >>/etc/tgt/conf.d/ha16.conf
  systemctl start tgtd
  systemctl enable tgtd
  reboot
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
