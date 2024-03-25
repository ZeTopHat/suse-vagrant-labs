#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "hana12iscsi" ]; then
  zypper install -y tgt
  echo "${SUBNET}${N1IP} hana12n1.labs.suse.com hana12n1" >>/etc/hosts
  echo "${SUBNET}${N2IP} hana12n2.labs.suse.com hana12n2" >>/etc/hosts
  mkdir /var/lib/hana12iscsi_disks
  dd if=/dev/zero of=/var/lib/hana12iscsi_disks/hana12_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/hana12iscsi_disks/hana12_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/hana12iscsi_disks/hana12_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2022-08.com.suse.labs.hana12iscsi:hana12>" >/etc/tgt/conf.d/hana12.conf
  echo "  backing-store /var/lib/hana12iscsi_disks/hana12_disk01.img" >>/etc/tgt/conf.d/hana12.conf
  echo "  backing-store /var/lib/hana12iscsi_disks/hana12_disk02.img" >>/etc/tgt/conf.d/hana12.conf
  echo "  backing-store /var/lib/hana12iscsi_disks/hana12_disk03.img" >>/etc/tgt/conf.d/hana12.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.hana12n1:initiator01" >>/etc/tgt/conf.d/hana12.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.hana12n2:initiator02" >>/etc/tgt/conf.d/hana12.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/hana12.conf
  echo "</target>" >>/etc/tgt/conf.d/hana12.conf
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
