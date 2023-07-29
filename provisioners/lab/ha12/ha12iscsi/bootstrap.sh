#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha12iscsi" ]; then
  zypper install -y tgt
  echo "${SUBNET}${N1IP} ha12n1.labs.suse.com ha12n1" >>/etc/hosts
  echo "${SUBNET}${N2IP} ha12n2.labs.suse.com ha12n2" >>/etc/hosts
  mkdir /var/lib/ha12iscsi_disks
  dd if=/dev/zero of=/var/lib/ha12iscsi_disks/ha12_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/ha12iscsi_disks/ha12_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/ha12iscsi_disks/ha12_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2019-12.com.suse.labs.ha12iscsi:ha12>" >/etc/tgt/conf.d/ha12.conf
  echo "  backing-store /var/lib/ha12iscsi_disks/ha12_disk01.img" >>/etc/tgt/conf.d/ha12.conf
  echo "  backing-store /var/lib/ha12iscsi_disks/ha12_disk02.img" >>/etc/tgt/conf.d/ha12.conf
  echo "  backing-store /var/lib/ha12iscsi_disks/ha12_disk03.img" >>/etc/tgt/conf.d/ha12.conf
  echo "  initiator-name iqn.2019-20.com.suse.labs.ha12n1:ha12n1" >>/etc/tgt/conf.d/ha12.conf
  echo "  initiator-name iqn.2019-20.com.suse.labs.ha12n2:ha12n2" >>/etc/tgt/conf.d/ha12.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/ha12.conf
  echo "</target>" >>/etc/tgt/conf.d/ha12.conf
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
