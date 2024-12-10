#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "s4hana01" ]; then
  SUSEConnect --de-register
  SUSEConnect --cleanup
  rpm -e --nodeps sles-release
  SUSEConnect -p $SAPPRODUCT -r $SAPREGCODE
  SUSEConnect -p sle-module-basesystem/15.6/x86_64
  SUSEConnect -p sle-module-desktop-applications/15.6/x86_64
  SUSEConnect -p sle-module-server-applications/15.6/x86_64
  SUSEConnect -p sle-ha/15.6/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-sap-applications/15.6/x86_64
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
  zypper install -y saptune SAPHanaSR sapstartsrv-resource-agents sap-suse-cluster-connector supportutils-plugin-ha-sap
  zypper install -y -t pattern ha_sles sap-nw sap_server
  echo "${SUBNET}${N2IP} s4hana02.labs.suse.com s4hana02" >>/etc/hosts
  echo "${SUBNET}${ISCSIIP} s4hanaiscsi.labs.suse.com s4hanaiscsi" >>/etc/hosts
  echo "${FLOATINGIP1} s4hascs" >>/etc/hosts
  echo "${FLOATINGIP2} s4hers" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.s4hana01:initiator01" >/etc/iscsi/initiatorname.iscsi
  echo "node.session.auth.authmethod = CHAP" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.username = username" >>/etc/iscsi/iscsid.conf
  echo "node.session.auth.password = password" >>/etc/iscsi/iscsid.conf
  sed -i 's/node.startup = manual/node.startup = automatic/g' /etc/iscsi/iscsid.conf 
  systemctl enable --now iscsi iscsid
  iscsiadm -m discovery -t sendtargets -p ${SUBNET}${ISCSIIP}
  iscsiadm --mode node --target iqn.2022-08.com.suse.labs.s4hanaiscsi:s4hana --portal s4hanaiscsi.labs.suse.com:3260 -o new
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
    until fdisk -l 2>/dev/null | grep " 1 GiB" ; do
      echo "The iscsi SBD device is not yet available. Sleeping 10 seconds.."
      sleep 10
    done
    DEV=$(fdisk -l 2>/dev/null | grep ' 1 GiB' | awk '{print $2}' | cut -c 1-8 | sed 's/\/dev\///' )
    BYID=$(ls -l /dev/disk/by-id/ | grep "$DEV" | head -1 | awk '{print $9}' | sed 's/^/\/dev\/disk\/by-id\//' )
    echo "The iscsi SBD device ${BYID} was found! Continuing.."
    until crm cluster init -s ${BYID} -i eth1 -y; do
      echo "Cluster inited failed.. Sleeping 10 seconds.."
      sleep 10
    done
    saptune solution apply S4HANA-APPSERVER
    saptune service takeover
    saptune service enablestart
    mkdir -p /sapcd
    mkdir -p /usr/sap/S4H/{ASCS00,ERS10,SYS}
    mkdir -p /sapmnt
    echo "s4hanaiscsi:/opt /sapcd nfs4 defaults 0 0" >>/etc/fstab
    echo "s4hanaiscsi:/exports/S4H/sapmnt /sapmnt nfs4 defaults 0 0" >>/etc/fstab
    echo "s4hanaiscsi:/exports/S4H/SYS /usr/sap/S4H/SYS nfs4 defaults 0 0" >>/etc/fstab
    mount -a
    parted --script $(fdisk -l 2>/dev/null | grep "10 GiB" | awk '{print $2}' | head -1 | tr -d \:) mklabel gpt mkpart primary 1MiB 9.9GiB
    parted --script $(fdisk -l 2>/dev/null | grep "10 GiB" | awk '{print $2}' | tail -1 | tr -d \:) mklabel gpt mkpart primary 1MiB 9.9GiB
    rescan-scsi-bus.sh
    mkfs.xfs $(fdisk -l 2>/dev/null | grep "10 GiB" | awk '{print $2}' | head -1 | tr -d \:)1
    mkfs.xfs $(fdisk -l 2>/dev/null | grep "10 GiB" | awk '{print $2}' | tail -1 | tr -d \:)1
    mount $(fdisk -l 2>/dev/null | grep "10 GiB" | awk '{print $2}' | head -1 | tr -d \:)1 /usr/sap/S4H/ASCS00
    mount $(fdisk -l 2>/dev/null | grep "10 GiB" | awk '{print $2}' | tail -1 | tr -d \:)1 /usr/sap/S4H/ERS10
    sysctl net.ipv4.tcp_keepalive_time=120
    ip addr add dev eth1 ${FLOATINGIP1}/24
    groupadd -g 1002 sapinst
    mkdir /ascs_install /ers_install /s4hconfigs
    chown root:sapinst /ascs_install /ers_install /s4hconfigs
    chmod 775 /ascs_install /ers_install
    mv /tmp/ascs /s4hconfigs/
    mv /tmp/ers /s4hconfigs/
    chown -R root:sapinst /s4hconfigs
    /sapcd/SWPM/sapinst SAPINST_SKIP_ERRORSTEP=true SAPINST_USE_HOSTNAME=s4hascs SAPINST_INIT_LOGDIR=/ascs_install/ SAPINST_SECUDIR=/ers_install/ SAPINST_CWD=/ascs_install/ SAPINST_INPUT_PARAMETERS_URL=/s4hconfigs/ascs/inifile.params SAPINST_EXECUTE_PRODUCT_ID=NW_ABAP_ASCS:S4HANA1909.CORE.HDB.ABAPHA SAPINST_SKIP_DIALOGS=true SAPINST_START_GUI=false SAPINST_START_GUISERVER=false
    rm -rf /tmp/sapinst_instdir
    ip addr add dev eth1 ${FLOATINGIP2}/24
    /sapcd/SWPM/sapinst SAPINST_SKIP_ERRORSTEP=true SAPINST_USE_HOSTNAME=s4hers SAPINST_INIT_LOGDIR=/ers_install/ SAPINST_SECUDIR=/ers_install/ SAPINST_CWD=/ers_install/ SAPINST_INPUT_PARAMETERS_URL=/s4hconfigs/ers/inifile.params SAPINST_EXECUTE_PRODUCT_ID=NW_ERS:S4HANA1909.CORE.HDB.ABAPHA SAPINST_SKIP_DIALOGS=true SAPINST_START_GUI=false SAPINST_START_GUISERVER=false
    rsync -ahP /usr/sap/sapservices s4hana02:/usr/sap/sapservices
    rsync -ahP /etc/services s4hana02:/etc/services
    rsync -ahP /home/s4hadm/.cshrc s4hana02:/home/s4hadm/
    rsync -ahP /home/s4hadm/.sapenv* s4hana02:/home/s4hadm/
    echo 'service/halib = $(DIR_EXECUTABLE)/saphascriptco.so' >> /usr/sap/S4H/SYS/profile/S4H_ASCS00_s4hascs
    echo 'service/halib_cluster_connector = /usr/bin/sap_suse_cluster_connector' >> /usr/sap/S4H/SYS/profile/S4H_ASCS00_s4hascs
    echo 'service/halib = $(DIR_EXECUTABLE)/saphascriptco.so' >> /usr/sap/S4H/SYS/profile/S4H_ERS10_s4hers
    echo 'service/halib_cluster_connector = /usr/bin/sap_suse_cluster_connector' >> /usr/sap/S4H/SYS/profile/S4H_ERS10_s4hers
    until ssh s4hana02 sbd -d ${BYID} dump 2>/dev/null; do
      echo "The SBD device is not readable yet on s4hana02. Rescanning scsi bus.."
      ssh s4hana02 rescan-scsi-bus.sh
      ssh s4hana02 systemctl restart iscsi
      sleep 10
    done
    echo "Running join on s4hana02 now that the node is ready for it."
    ssh s4hana02 rescan-scsi-bus.sh
    ssh s4hana02 crm cluster join -y -i eth1 -c s4hana01
    sed -i "s/FLOATINGIP1/${FLOATINGIP1}/" /tmp/crm_part1.txt
    ASCSDATA=$(ls -l /dev/disk/by-id/ | grep "$(fdisk -l 2>/dev/null | grep '10 GiB' | awk '{print $2}' | head -1 | tr -d \: | sed 's/\/dev\///' )1" | head -1 | awk '{print $9}' | sed 's/^/\\\/dev\\\/disk\\\/by-id\\\//' )
    sed -i "s/ASCSDATA/${ASCSDATA}/" /tmp/crm_part1.txt
    crm configure load update /tmp/crm_part1.txt
    sed -i "s/FLOATINGIP2/${FLOATINGIP2}/" /tmp/crm_part2.txt
    ERSDATA=$(ls -l /dev/disk/by-id/ | grep "$(fdisk -l 2>/dev/null | grep '10 GiB' | awk '{print $2}' | tail -1 | tr -d \: | sed 's/\/dev\///' )1" | head -1 | awk '{print $9}' | sed 's/^/\\\/dev\\\/disk\\\/by-id\\\//' )
    sed -i "s/ERSDATA/${ERSDATA}/" /tmp/crm_part2.txt
    crm configure load update /tmp/crm_part2.txt
    crm configure load update /tmp/crm_part3.txt
    usermod -a -G haclient s4hadm
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
