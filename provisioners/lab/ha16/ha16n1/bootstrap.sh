#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha16n1" ]; then
  SUSEConnect -r $HAREGCODE -p $HAPRODUCT
  echo "StrictHostKeyChecking no" >>/etc/ssh/ssh_config
  mkdir -p /root/.ssh
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
  echo "${SUBNET}${N2IP} ha16n2.labs.suse.com ha16n2" >>/etc/hosts
  echo "${SUBNET}${ISCSIIP} ha16iscsi.labs.suse.com ha16iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.ha16n1:initiator01" >/etc/iscsi/initiatorname.iscsi
  echo "node.session.auth.authmethod = CHAP" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.username = username" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.password = password" >>/etc/iscsi/iscsid.conf
  sed -i 's/node.startup = manual/node.startup = automatic/g' /etc/iscsi/iscsid.conf 
  systemctl enable --now iscsi iscsid
  iscsiadm -m discovery -t sendtargets -p ${SUBNET}${ISCSIIP}
  iscsiadm --mode node --target iqn.2022-08.com.suse.labs.ha16iscsi:ha16 --portal ha16iscsi.labs.suse.com:3260 -o new
  systemctl restart iscsi iscsid
  # these need to be done after iscsi and softdog to avoid issues when the kernel updates
  zypper install -y dlm-kmp-default gfs2-kmp-default gfs2-utils lvm2-lockd sg3_utils
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    # give node 2 time to setup its end of things
    sleep 30
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
    rescan-scsi-bus.sh
    until fdisk -l 2>/dev/null | grep " 1 GiB" ; do
      echo "The iscsi SBD device is not yet available. Sleeping 10 seconds.."
      sleep 10
    done
    DEV=$(fdisk -l 2>/dev/null | grep ' 1 GiB' | awk '{print $2}' | cut -c 1-8 | sed 's/\/dev\///' )
    BYID=$(ls -l /dev/disk/by-id/ | grep "$DEV" | head -1 | awk '{print $9}' | sed 's/^/\/dev\/disk\/by-id\//' )
    echo "The iscsi SBD device ${BYID} was found! Continuing.."
    crm cluster init -s ${BYID} -i ${IPADDRESS} -y
    sed -i 's/use_lvmlockd = 0/use_lvmlockd = 1/' /etc/lvm/lvm.conf
    systemctl enable lvmlockd
    mkdir /shared
    mkdir /data
    mkdir -p /exports/data2
    systemctl enable --now nfs-server
    ssh ha16n2 systemctl enable --now nfs-server
    firewall-cmd --add-service nfs
    firewall-cmd --add-service nfs --permanent
    until ssh ha16n2 sbd -d ${BYID} dump 2>/dev/null; do
      echo "The SBD device is not readable yet on ha16n2. Rescanning scsi bus.."
      ssh ha16n2 rescan-scsi-bus.sh
      ssh ha16n2 systemctl restart iscsi
      sleep 10
    done
    echo "Running join on ha16n2 now that the node is ready for it."
    ssh ha16n2 crm cluster join -y -i ${SUBNET}${N2IP} -c ha16n1
    crm configure load update /tmp/crm_ha16_part1.txt
    parted --script /dev/sdb mklabel gpt mkpart primary 1MiB 5GiB mkpart primary 5GiB 8GiB mkpart primary 8GiB 9.9GiB
    ssh ha16n2 rescan-scsi-bus.sh
    mkfs.xfs /dev/sdb1
    sed -i "s/FLOATINGIP1/${FLOATINGIP1}/" /tmp/crm_ha16_part4.txt
    FSDATA=$(ls -l /dev/disk/by-id/ | grep "sdb1" | head -1 | awk '{print $9}' | sed 's/^/\\\/dev\\\/disk\\\/by-id\\\//' )
    sed -i "s/FSDATA/${FSDATA}/" /tmp/crm_ha16_part4.txt
    crm configure load update /tmp/crm_ha16_part4.txt
    mkfs.ext4 /dev/sdb2
    mkdir -p /exports/data2
    crm_resource --wait
    vgcreate --shared vg-shared /dev/sda
    lvcreate -an -L 9.9G -n lv-shared vg-shared
    crm configure load update /tmp/crm_ha16_part2.txt
    sleep 10
    mkfs.gfs2 -O -j 4 -t hacluster:lv-shared /dev/vg-shared/lv-shared
    crm configure load update /tmp/crm_ha16_part3.txt
    sed -i "s/FLOATINGIP2/${FLOATINGIP2}/" /tmp/crm_ha16_part5.txt
    NFSFS=$(ls -l /dev/disk/by-id/ | grep "sdb2" | head -1 | awk '{print $9}' | sed 's/^/\\\/dev\\\/disk\\\/by-id\\\//' )
    sed -i "s/NFSFS/${NFSFS}/" /tmp/crm_ha16_part5.txt
    crm configure load update /tmp/crm_ha16_part5.txt
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
