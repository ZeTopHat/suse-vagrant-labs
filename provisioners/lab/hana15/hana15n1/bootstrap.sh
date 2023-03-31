#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "hana15n1" ]; then
  SUSEConnect --cleanup
  rpm -e --nodeps sles-release
  SUSEConnect -p $SAPPRODUCT -r $SAPREGCODE
  SUSEConnect -p sle-module-basesystem/15.4/x86_64
  SUSEConnect -p sle-module-desktop-applications/15.4/x86_64
  SUSEConnect -p sle-module-server-applications/15.4/x86_64
  SUSEConnect -p sle-ha/15.4/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-sap-applications/15.4/x86_64
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
  zypper install -y open-iscsi lsscsi cron
  zypper install -y -t pattern ha_sles sap-hana
  echo "192.168.0.162 hana15n2.labs.suse.com hana15n2" >>/etc/hosts
  echo "192.168.0.160 hana15iscsi.labs.suse.com hana15iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.hana15n1:initiator01" >/etc/iscsi/initiatorname.iscsi
  echo "node.session.auth.authmethod = CHAP" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.username = username" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.password = password" >>/etc/iscsi/iscsid.conf
  sed -i 's/node.startup = manual/node.startup = automatic/g' /etc/iscsi/iscsid.conf 
  systemctl enable --now iscsi iscsid
  iscsiadm -m discovery -t sendtargets -p 192.168.0.160
  iscsiadm --mode node --target iqn.2022-08.com.suse.labs.hana15iscsi:hana15 --portal hana15iscsi.labs.suse.com:3260 -o new
  systemctl restart iscsi iscsid
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
    saptune solution apply HANA
    saptune service takeover
    saptune service enablestart
    parted /dev/vdb mklabel gpt
    parted /dev/vdb mkpart primary xfs 1MiB 204799MiB
    mkfs -t xfs /dev/vdb1
    mkdir /hana
    echo "$(blkid | grep vdb1 | awk '{print $2}' | sed -e 's/\"//g') /hana xfs defaults 0 0" >>/etc/fstab
    mount -a
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_site_srHook_*" >> /etc/sudoers
    echo "Running join on ha15n2 now that the node is ready for it."
    ssh hana15n2 rescan-scsi-bus.sh
    ssh hana15n2 crm cluster join -y -i eth1 -c hana15n1
    /opt/hdblcm --hdbinst_server_import_content=off --batch --configfile=/tmp/install.rsp
    /usr/sap/HXE/HDB00/exe/hdbsql -p SuSE1234 -u SYSTEM -d SYSTEMDB "BACKUP DATA FOR FULL SYSTEM USING FILE ('backup')"
    su - hxeadm -c 'hdbnsutil -sr_enable --name=hana15n1'
    rsync -zahP /hana/shared/HXE/global/security/rsecssfs/ hana15n2:/hana/shared/HXE/global/security/rsecssfs/
    ssh hana15n2 "su - hxeadm -c 'HDB stop'"
    ssh hana15n2 "su - hxeadm -c 'hdbnsutil -sr_register --remoteHost=hana15n1 --remoteInstance=00 --replicationMode=syncmem --operationMode=delta_datashipping --name=hana15n2'"
    ssh hana15n2 "su - hxeadm -c 'HDB start'"
    crm configure load update /tmp/crm_hana15_part1.txt
    crm configure load update /tmp/crm_hana15_part2.txt
    crm configure load update /tmp/crm_hana15_part3.txt
    crm configure load update /tmp/crm_hana15_part4.txt
    crm configure load update /tmp/crm_hana15_part5.txt
    crm_resource --wait
    crm resource cleanup
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
