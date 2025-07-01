#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "scaleout15n1" ]; then
  SUSEConnect --de-register
  SUSEConnect --cleanup
  rpm -e --nodeps sles-release
  SUSEConnect -p $SAPPRODUCT -r $SAPREGCODE
  SUSEConnect -p sle-module-basesystem/15.5/x86_64
  SUSEConnect -p sle-module-desktop-applications/15.5/x86_64
  SUSEConnect -p sle-module-server-applications/15.5/x86_64
  SUSEConnect -p sle-ha/15.5/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-sap-applications/15.5/x86_64
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
  zypper install -y saptune SAPHanaSR-ScaleOut SAPHanaSR-ScaleOut-doc ClusterTools2 sapstartsrv-resource-agents sap-suse-cluster-connector supportutils-plugin-ha-sap
  echo "${SUBNET}${N2IP} scaleout15n2.labs.suse.com scaleout15n2" >>/etc/hosts
  echo "${SUBNET}${N3IP} scaleout15n3.labs.suse.com scaleout15n3" >>/etc/hosts
  echo "${SUBNET}${N4IP} scaleout15n4.labs.suse.com scaleout15n4" >>/etc/hosts
  echo "${SUBNET}${N5IP} scaleout15n5.labs.suse.com scaleout15n5" >>/etc/hosts
  echo "${SUBNET}${N6IP} scaleout15n6.labs.suse.com scaleout15n6" >>/etc/hosts
  echo "${SUBNET}${ISCSIIP} scaleout15iscsi.labs.suse.com scaleout15iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.scaleout15n1:initiator01" >/etc/iscsi/initiatorname.iscsi
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
    # give node 2 time to setup its end of things
    sleep 30
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
    rescan-scsi-bus.sh
    until fdisk -l 2>/dev/null | grep " 1 GiB" ; do
      echo "The iscsi SBD device is not yet available. Sleeping 10 seconds.."
      rescan-scsi-bus.sh
      systemctl restart iscsi
      sleep 10
    done
    DEV=$(fdisk -l 2>/dev/null | grep ' 1 GiB' | awk '{print $2}' | cut -c 1-8 | sed 's/\/dev\///' )
    BYID=$(ls -l /dev/disk/by-id/ | grep "$DEV" | head -1 | awk '{print $9}' | sed 's/^/\/dev\/disk\/by-id\//' )
    echo "The iscsi SBD device ${BYID} was found! Continuing.."
    until crm cluster init -s ${BYID} -i eth1 -y; do
      echo "Cluster inited failed.. Sleeping 10 seconds.."
      sleep 10
    done
    saptune solution apply HANA
    saptune service takeover
    saptune service enablestart
    mkdir /hana
    echo "scaleout15iscsi:/var/lib/exports/hanaexport1 /hana nfs defaults,_netdev 0 0" >>/etc/fstab
    mount -a
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_site_srHook_*" >> /etc/sudoers
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_gsh *" >> /etc/sudoers
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_hxe_glob_mts *" >> /etc/sudoers
    echo "hxeadm ALL=(ALL) NOPASSWD: /usr/sbin/SAPHanaSR-hookHelper *" >> /etc/sudoers
    for i in {2..6}; do 
      until ssh scaleout15n${i} sbd -d ${BYID} dump 2>/dev/null; do
        echo "The SBD device is not readable yet on scaleout15n${i}. Rescanning scsi bus.."
        ssh scaleout15n${i} rescan-scsi-bus.sh
        ssh scaleout15n${i} systemctl restart iscsi
        sleep 10
      done
      echo "Running join on scaleout15n${i} now that the node is ready for it."
      ssh scaleout15n${i} rescan-scsi-bus.sh
      ssh scaleout15n${i} crm cluster join -y -i eth1 -c scaleout15n1
    done
    sed -i "s/IP1/${SUBNET}${N1IP}/" /tmp/custom/global.ini
    sed -i "s/IP2/${SUBNET}${N2IP}/" /tmp/custom/global.ini
    sed -i "s/IP3/${SUBNET}${N3IP}/" /tmp/custom/global.ini
    sed -i "s/IP4/${SUBNET}${N4IP}/" /tmp/custom/global.ini
    sed -i "s/IP5/${SUBNET}${N5IP}/" /tmp/custom/global.ini
    sed -i "s/IP6/${SUBNET}${N6IP}/" /tmp/custom/global.ini
    until grep "/hana" /proc/mounts; do
      echo "The NFS /hana mount is unavailable on scaleout15n1. Sleeping 10 seconds.."
      mount -a
      sleep 10
    done
    /opt/hdblcm --hdbinst_server_import_content=off --batch --configfile=/tmp/install.rsp
    until /usr/sap/HXE/HDB00/exe/hdbsql -p SuSE1234 -u SYSTEM -d SYSTEMDB "BACKUP DATA FOR FULL SYSTEM USING FILE ('backup')"; do
      echo "Backup failed. Trying again in 10 seconds.."
      sleep 10
    done
    for i in {2..3}; do
      until ssh scaleout15n${i} grep "/hana" /proc/mounts; do
        echo "The NFS /hana mount is unavailable on scaleout15n${i}. Sleeping 10 seconds.."
        ssh scaleout15n${i} mount -a
        sleep 10
      done
    done
    /hana/shared/HXE/hdblcm/hdblcm --action=add_hosts --addhosts=scaleout15n2,scaleout15n3 --root_user=root --listen_interface=global --batch --password=SuSE1234 --sapadm_password=SuSE1234
    echo "reserved_port/instance_list=00" >> /usr/sap/hostctrl/exe/host_profile
    echo "reserved_port/product_list=HANA,HANAREP,XSA" >> /usr/sap/hostctrl/exe/host_profile
    echo "" > /proc/sys/net/ipv4/ip_local_reserved_ports
    /usr/sap/hostctrl/exe/saphostexec -restart
    su - hxeadm -c 'HDB stop'
    su - hxeadm -c 'HDB start'
    su - hxeadm -c 'hdbnsutil -sr_enable --name=scaleout15n1'
    su - hxeadm -c 'HDB info'
    sleep 5
    rsync -zahP /hana/shared/HXE/global/security/rsecssfs/ scaleout15n4:/hana/shared/HXE/global/security/rsecssfs/
    ssh scaleout15n4 "su - hxeadm -c 'HDB stop'"
    until ssh scaleout15n4 "su - hxeadm -c 'hdbnsutil -sr_register --remoteHost=scaleout15n1 --remoteInstance=00 --replicationMode=syncmem --operationMode=delta_datashipping --name=scaleout15n4'" ; do
      echo "Registration failed. Trying again in 10 seconds.."
      sleep 10
    done
    ssh scaleout15n4 "su - hxeadm -c 'HDB start'"
    crm configure load update /tmp/crm_scaleout15_part1.txt
    crm configure load update /tmp/crm_scaleout15_part2.txt
    sed -i "s/FLOATINGIP1/${FLOATINGIP1}/" /tmp/crm_scaleout15_part3.txt
    sed -i "s/FLOATINGIP2/${FLOATINGIP2}/" /tmp/crm_scaleout15_part3.txt
    crm configure load update /tmp/crm_scaleout15_part3.txt
    crm configure load update /tmp/crm_scaleout15_part4.txt
    crm configure load update /tmp/crm_scaleout15_part5.txt
    crm_resource --wait
    crm resource cleanup
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
