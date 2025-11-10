#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "scaleout15n3" ]; then
  SUSEConnect --de-register
  SUSEConnect --cleanup
  rpm -e --nodeps sles-release
  SUSEConnect -p SLES_SAP/$SAPPRODUCT/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-basesystem/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-module-desktop-applications/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-module-server-applications/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-ha/$SAPPRODUCT/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-sap-applications/$SAPPRODUCT/x86_64
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
  zypper install -y open-iscsi lsscsi cron nfs-client
  zypper install -y -t pattern ha_sles sap-hana sap_server
  systemctl disable YaST2-Firstboot.service
  systemctl disable YaST2-Second-Stage.service
  zypper install -y saptune SAPHanaSR-ScaleOut SAPHanaSR-ScaleOut-doc ClusterTools2 sapstartsrv-resource-agents sap-suse-cluster-connector supportutils-plugin-ha-sap
  echo "${SUBNET}${N1IP} scaleout15n1.labs.suse.com scaleout15n1" >>/etc/hosts
  echo "${SUBNET}${N2IP} scaleout15n2.labs.suse.com scaleout15n2" >>/etc/hosts
  echo "${SUBNET}${N4IP} scaleout15n4.labs.suse.com scaleout15n4" >>/etc/hosts
  echo "${SUBNET}${N5IP} scaleout15n5.labs.suse.com scaleout15n5" >>/etc/hosts
  echo "${SUBNET}${N6IP} scaleout15n6.labs.suse.com scaleout15n6" >>/etc/hosts
  echo "${SUBNET}${ISCSIIP} scaleout15iscsi.labs.suse.com scaleout15iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.scaleout15n3:initiator03" >/etc/iscsi/initiatorname.iscsi
  echo "node.session.auth.authmethod = CHAP" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.username = username" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.password = password" >>/etc/iscsi/iscsid.conf
  sed -i 's/node.startup = manual/node.startup = automatic/g' /etc/iscsi/iscsid.conf 
  systemctl enable --now iscsi iscsid
  iscsiadm -m discovery -t sendtargets -p ${SUBNET}${ISCSIIP}
  iscsiadm --mode node --target iqn.2022-08.com.suse.labs.scaleout15iscsi:scaleout15 --portal scaleout15iscsi.labs.suse.com:3260 -o new
  systemctl restart iscsi iscsid
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
    parted /dev/vdb mklabel gpt
    parted /dev/vdb mkpart primary xfs 1MiB 204799MiB
    mkfs -t xfs /dev/vdb1
    mkdir /hana
    echo "scaleout15iscsi:/var/lib/exports/hanaexport1 /hana nfs defaults,_netdev 0 0" >>/etc/fstab
    mount -a
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_site_srHook_*" >> /etc/sudoers
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_gsh *" >> /etc/sudoers
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_glob_mts *" >> /etc/sudoers
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/SAPHanaSR-hookHelper *" >> /etc/sudoers
    saptune solution apply HANA
    saptune service takeover
    saptune service enablestart
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
