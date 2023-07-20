#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "hana15iscsi" ]; then
  zypper install -y tgt
  echo "${SUBNET}.161 hana15n1.labs.suse.com hana15n1" >>/etc/hosts
  echo "${SUBNET}.162 hana15n2.labs.suse.com hana15n2" >>/etc/hosts
  mkdir /var/lib/hana15iscsi_disks
  dd if=/dev/zero of=/var/lib/hana15iscsi_disks/hana15_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/hana15iscsi_disks/hana15_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/hana15iscsi_disks/hana15_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2022-08.com.suse.labs.hana15iscsi:hana15>" >/etc/tgt/conf.d/hana15.conf
  echo "  backing-store /var/lib/hana15iscsi_disks/hana15_disk01.img" >>/etc/tgt/conf.d/hana15.conf
  echo "  backing-store /var/lib/hana15iscsi_disks/hana15_disk02.img" >>/etc/tgt/conf.d/hana15.conf
  echo "  backing-store /var/lib/hana15iscsi_disks/hana15_disk03.img" >>/etc/tgt/conf.d/hana15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.hana15n1:initiator01" >>/etc/tgt/conf.d/hana15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.hana15n2:initiator02" >>/etc/tgt/conf.d/hana15.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/hana15.conf
  echo "</target>" >>/etc/tgt/conf.d/hana15.conf
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
