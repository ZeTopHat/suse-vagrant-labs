#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha12n1" ]; then
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
  echo "${SUBNET}.122 ha12n2.labs.suse.com ha12n2" >>/etc/hosts
  echo "${SUBNET}.120 ha12iscsi.labs.suse.com ha12iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2019-20.com.suse.labs.ha12n1:ha12n1" >/etc/iscsi/initiatorname.iscsi
  echo "node.session.auth.authmethod = CHAP" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.username = username" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.password = password" >>/etc/iscsi/iscsid.conf
  sed -i 's/node.startup = manual/node.startup = automatic/g' /etc/iscsi/iscsid.conf
  systemctl enable --now iscsi iscsid
  iscsiadm -m discovery -t sendtargets -p ${SUBNET}.120
  iscsiadm --mode node --target iqn.2019-12.com.suse.labs.ha12iscsi:ha12 --portal ha12iscsi.labs.suse.com:3260 -o new
  systemctl restart iscsi iscsid
  # these need to be done after iscsi and softdog to avoid issues when the kernel updates
  zypper install -y --oldpackage dlm-kmp-default$(rpm -q kernel-default | grep -Eo '\-[0-9.-]+') libdlm ocfs2-kmp-default$(rpm -q kernel-default | grep -Eo '\-[0-9.-]+')
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    sleep 30;
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
    until fdisk -l 2>/dev/null | grep " 1 GiB" ; do
      echo "The iscsi SBD device is not yet available. Sleeping 10 seconds.."
      sleep 10
    done
    echo "The iscsi SBD device $(fdisk -l 2>/dev/null | grep ' 1 GiB' | awk '{print $2}' | cut -c 1-8) was found! Continuing.."
    crm cluster init -s $(fdisk -l 2>/dev/null | grep " 1 GiB" | awk '{print $2}' | cut -c 1-8) -i eth1 -y
    mkdir /shared
    mkdir /data
    mkdir -p /exports/data2
    systemctl enable nfsserver
    until ssh ha12n2 sbd -d $(fdisk -l 2>/dev/null | grep " 1 GiB" | awk '{print $2}' | cut -c 1-8) dump 2>/dev/null; do
      echo "The SBD device is not readable yet on ha12n2. Rescanning scsi bus.."
      ssh ha12n2 rescan-scsi-bus.sh
      ssh ha12n2 systemctl restart iscsi
      sleep 10
    done
    echo "Running join on ha12n2 now that the node is ready for it."
    ssh ha12n2 crm cluster join -y -i eth1 -c ha12n1
    crm configure load update /tmp/crm_ha12_part1.txt
    sleep 5
    parted --script /dev/sdb mklabel gpt mkpart primary 1MiB 5GiB mkpart primary 5GiB 8GiB mkpart primary 8GiB 9.9GiB
    ssh ha12n2 rescan-scsi-bus.sh
    mkfs.xfs /dev/sdb1
    sed -i "s/FLOATINGIP1/${FLOATINGIP1}/" /tmp/crm_ha12_part3.txt
    crm configure load update /tmp/crm_ha12_part3.txt
    sleep 5
    mkfs.ext4 /dev/sdb2
    systemctl enable --now nfsserver
    ssh ha12n2 systemctl enable --now nfsserver
    sed -i "s/FLOATINGIP2/${FLOATINGIP2}/" /tmp/crm_ha12_part4.txt
    crm configure load update /tmp/crm_ha12_part4.txt
    sleep 5
    pvcreate /dev/sda
    vgcreate --clustered y vg-shared /dev/sda
    lvcreate -ay -L 9.9G -n lv-shared vg-shared
    sleep 10
    mkfs.ocfs2 -N 4 /dev/vg-shared/lv-shared
    crm configure load update /tmp/crm_ha12_part2.txt
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

ssh ha12n2 reboot
reboot
echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
