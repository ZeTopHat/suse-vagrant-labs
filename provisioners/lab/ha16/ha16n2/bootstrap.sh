#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "ha16n2" ]; then
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
  echo "${SUBNET}${N1IP} ha16n1.labs.suse.com ha16n1" >>/etc/hosts
  echo "${SUBNET}${ISCSIIP} ha16iscsi.labs.suse.com ha16iscsi" >>/etc/hosts
  echo "InitiatorName=iqn.2022-08.com.suse.labs.ha16n2:initiator02" >/etc/iscsi/initiatorname.iscsi
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
    echo "softdog" > /etc/modules-load.d/watchdog.conf
    systemctl restart systemd-modules-load
    sed -i 's/use_lvmlockd = 0/use_lvmlockd = 1/' /etc/lvm/lvm.conf
    systemctl enable lvmlockd
    mkdir /shared
    mkdir /data
    firewall-cmd --add-service nfs
    firewall-cmd --add-service nfs --permanent
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
