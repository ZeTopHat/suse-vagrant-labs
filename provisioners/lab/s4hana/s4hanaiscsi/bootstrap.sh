#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "s4hanaiscsi" ]; then
  zypper install -y tgt nfs-kernel-server nfs-client
  echo "${SUBNET}${N1IP} s4hana01.labs.suse.com s4hana01" >>/etc/hosts
  echo "${SUBNET}${N2IP} s4hana02.labs.suse.com s4hana02" >>/etc/hosts
  mkdir /var/lib/s4hanaiscsi_disks
  dd if=/dev/zero of=/var/lib/s4hanaiscsi_disks/s4hana_disk01.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/s4hanaiscsi_disks/s4hana_disk02.img count=0 bs=1 seek=10G
  dd if=/dev/zero of=/var/lib/s4hanaiscsi_disks/s4hana_disk03.img count=0 bs=1 seek=1G
  echo "<target iqn.2022-08.com.suse.labs.s4hanaiscsi:s4hana>" >/etc/tgt/conf.d/s4hana.conf
  echo "  backing-store /var/lib/s4hanaiscsi_disks/s4hana_disk01.img" >>/etc/tgt/conf.d/s4hana.conf
  echo "  backing-store /var/lib/s4hanaiscsi_disks/s4hana_disk02.img" >>/etc/tgt/conf.d/s4hana.conf
  echo "  backing-store /var/lib/s4hanaiscsi_disks/s4hana_disk03.img" >>/etc/tgt/conf.d/s4hana.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.s4hana01:initiator01" >>/etc/tgt/conf.d/s4hana.conf
  echo "  initiator-name iqn.2022-08.com.suse.labs.s4hana02:initiator02" >>/etc/tgt/conf.d/s4hana.conf
  echo "  incominguser username password" >>/etc/tgt/conf.d/s4hana.conf
  echo "</target>" >>/etc/tgt/conf.d/s4hana.conf
  systemctl start tgtd
  systemctl enable tgtd
  mkdir -p /exports/S4H/sapmnt
  mkdir -p /exports/S4H/SYS
  echo "
  /opt  *(rw,no_root_squash,sync,no_subtree_check)
  /exports/S4H/sapmnt     *(rw,no_root_squash,sync,no_subtree_check)
  /exports/S4H/SYS        *(rw,no_root_squash,sync,no_subtree_check)
  " >> /etc/exports
  systemctl enable --now nfs-server
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
