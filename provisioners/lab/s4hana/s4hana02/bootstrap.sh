#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "s4hana02" ]; then
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
  zypper install -y open-iscsi lsscsi cron nfs-client sap-suse-cluster-connector
  zypper install -y -t pattern ha_sles sap-nw
  echo "${SUBNET}${N1IP} s4hana01.labs.suse.com s4hana01" >>/etc/hosts
  echo "${SUBNET}${ISCSIIP} s4hanaiscsi.labs.suse.com s4hanaiscsi" >>/etc/hosts
  echo "${FLOATINGIP1} s4hascs" >>/etc/hosts
  echo "${FLOATINGIP2} s4hers" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.s4hana02:initiator02" >/etc/iscsi/initiatorname.iscsi
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
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
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
    sysctl net.ipv4.tcp_keepalive_time=120
    groupadd -g 1003 sapsys
    useradd -s /bin/csh -c "SAP System Administrator" -m -d /home/s4hadm -u 1002 -g sapsys s4hadm
    useradd -s /bin/false -c "SAP System Administrator" -m -d /home/sapadm -u 1003 -g sapsys sapadm
    usermod -a -G haclient s4hadm
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
