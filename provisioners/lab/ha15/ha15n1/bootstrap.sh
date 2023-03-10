#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha15n1" ]; then
  SUSEConnect -r $HAREGCODE -p $HAPRODUCT
  echo "StrictHostKeyChecking no" >>/etc/ssh/ssh_config
  mkdir /root/.ssh
  chmod 700 /root/.ssh
  mv /tmp/id_rsa /root/.ssh/id_rsa
  mv /tmp/id_rsa.pub /root/.ssh/id_rsa.pub
  mv /tmp/authorized_keys /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/id_rsa
  chmod 600 /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys
  chown root:root /root/.ssh/id_rsa
  chown root:root /root/.ssh/id_rsa.pub
  zypper install -y open-iscsi lsscsi cron xfsprogs nfs-kernel-server nfs-client
  zypper install -y -t pattern ha_sles
  echo "192.168.0.152 ha15n2.labs.suse.com ha15n2" >>/etc/hosts
  echo "192.168.0.150 ha15iscsi.labs.suse.com ha15iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.ha15n1:initiator01" >/etc/iscsi/initiatorname.iscsi
  echo "node.session.auth.authmethod = CHAP" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.username = username" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.password = password" >>/etc/iscsi/iscsid.conf
  sed -i 's/node.startup = manual/node.startup = automatic/g' /etc/iscsi/iscsid.conf 
  systemctl enable --now iscsi iscsid
  iscsiadm -m discovery -t sendtargets -p 192.168.0.150
  iscsiadm --mode node --target iqn.2022-08.com.suse.labs.ha15iscsi:ha15 --portal ha15iscsi.labs.suse.com:3260 -o new
  systemctl restart iscsi iscsid
  # these need to be done after iscsi and softdog to avoid issues when the kernel updates
  zypper install -y --oldpackage dlm-kmp-default$(rpm -q kernel-default | grep -Eo '\-[0-9.-]+') ocfs2-kmp-default$(rpm -q kernel-default | grep -Eo '\-[0-9.-]+')
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    # give node 2 time to setup its end of things
    sleep 30
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
    rescan-scsi-bus.sh
    crm cluster init -s $(fdisk -l 2>/dev/null | grep "1 GiB" | awk '{print $2}' | cut -c 1-8) -i eth1 -y
    sed -i 's/use_lvmlockd = 0/use_lvmlockd = 1/' /etc/lvm/lvm.conf
    systemctl enable --now lvmlockd
    mkdir /shared
    mkdir /data
    mkdir -p /exports/data2
    systemctl enable --now nfsserver
    ssh ha15n2 systemctl enable --now nfsserver
    echo "Running join on ha15n2 now that the node is ready for it."
    ssh ha15n2 crm cluster join -y -i eth1 -c ha15n1
    crm configure load update /tmp/crm_ha15_part1.txt
    parted --script /dev/sdb mklabel gpt mkpart primary 1MiB 5GiB mkpart primary 5GiB 8GiB mkpart primary 8GiB 9.9GiB
    ssh ha15n2 rescan-scsi-bus.sh
    mkfs.xfs /dev/sdb1
    crm configure load update /tmp/crm_ha15_part4.txt
    mkfs.ext4 /dev/sdb2
    mkdir -p /exports/data2
    vgcreate --shared vg-shared /dev/sda
    lvcreate -an -L 9.9G -n lv-shared vg-shared
    crm configure load update /tmp/crm_ha15_part2.txt
    sleep 10
    mkfs.ocfs2 -N 4 /dev/vg-shared/lv-shared
    crm configure load update /tmp/crm_ha15_part3.txt
    crm configure load update /tmp/crm_ha15_part5.txt
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

ssh ha15n2 reboot
reboot
echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
