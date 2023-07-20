#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha15iscsi" ]; then
  zypper install -y tgt
  echo "${SUBNET}.151 ha15n1.labs.suse.com ha15n1" >>/etc/hosts
  echo "${SUBNET}.152 ha15n2.labs.suse.com ha15n2" >>/etc/hosts
  mkdir /var/lib/ha15iscsi_disks
  dd if=/dev/zero of=/var/lib/ha15iscsi_disks/ha15_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/ha15iscsi_disks/ha15_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/ha15iscsi_disks/ha15_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2022-08.com.suse.labs.ha15iscsi:ha15>" >/etc/tgt/conf.d/ha15.conf
  echo "  backing-store /var/lib/ha15iscsi_disks/ha15_disk01.img" >>/etc/tgt/conf.d/ha15.conf
  echo "  backing-store /var/lib/ha15iscsi_disks/ha15_disk02.img" >>/etc/tgt/conf.d/ha15.conf
  echo "  backing-store /var/lib/ha15iscsi_disks/ha15_disk03.img" >>/etc/tgt/conf.d/ha15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.ha15n1:initiator01" >>/etc/tgt/conf.d/ha15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.ha15n2:initiator02" >>/etc/tgt/conf.d/ha15.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/ha15.conf
  echo "</target>" >>/etc/tgt/conf.d/ha15.conf
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
