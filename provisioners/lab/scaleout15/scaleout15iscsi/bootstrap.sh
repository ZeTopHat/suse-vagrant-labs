#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "scaleout15iscsi" ]; then
  zypper install -y tgt xfsprogs nfs-kernel-server nfs-client
  echo "${SUBNET}${N1IP} scaleout15n1.labs.suse.com scaleout15n1" >>/etc/hosts
  echo "${SUBNET}${N2IP} scaleout15n2.labs.suse.com scaleout15n2" >>/etc/hosts
  echo "${SUBNET}${N3IP} scaleout15n3.labs.suse.com scaleout15n3" >>/etc/hosts
  echo "${SUBNET}${N4IP} scaleout15n4.labs.suse.com scaleout15n4" >>/etc/hosts
  echo "${SUBNET}${N5IP} scaleout15n5.labs.suse.com scaleout15n5" >>/etc/hosts
  echo "${SUBNET}${N6IP} scaleout15n6.labs.suse.com scaleout15n6" >>/etc/hosts
  mkdir /var/lib/scaleout15iscsi_disks
  dd if=/dev/zero of=/var/lib/scaleout15iscsi_disks/scaleout15_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/scaleout15iscsi_disks/scaleout15_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/scaleout15iscsi_disks/scaleout15_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2022-08.com.suse.labs.scaleout15iscsi:scaleout15>" >/etc/tgt/conf.d/scaleout15.conf
  echo "  backing-store /var/lib/scaleout15iscsi_disks/scaleout15_disk01.img" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  backing-store /var/lib/scaleout15iscsi_disks/scaleout15_disk02.img" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  backing-store /var/lib/scaleout15iscsi_disks/scaleout15_disk03.img" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.scaleout15n1:initiator01" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.scaleout15n2:initiator02" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.scaleout15n3:initiator03" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.scaleout15n4:initiator04" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.scaleout15n5:initiator05" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.scaleout15n6:initiator06" >>/etc/tgt/conf.d/scaleout15.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/scaleout15.conf
  echo "</target>" >>/etc/tgt/conf.d/scaleout15.conf
  systemctl start tgtd
  systemctl enable tgtd
  parted /dev/vdb mklabel gpt
  parted /dev/vdb mkpart primary xfs 1MiB 204799MiB
  mkdir /var/lib/exports
  mkfs -t xfs /dev/vdb1
  echo "$(blkid | grep vdb1 | awk '{print $2}' | sed -e 's/\"//g') /var/lib/exports xfs defaults 0 0" >>/etc/fstab
  mount -a
  mkdir /var/lib/exports/hanaexport1
  mkdir /var/lib/exports/hanaexport2
  echo "/var/lib/exports/hanaexport1 *(rw,no_root_squash,sync)" >> /etc/exports
  echo "/var/lib/exports/hanaexport2 *(rw,no_root_squash,sync)" >> /etc/exports
  systemctl enable --now nfsserver
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
