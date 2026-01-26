#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "suma15" ]; then
  echo "always"
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    SUSEConnect -p sle-module-containers/$SLEPRODUCT/x86_64
    SUSEConnect -p Multi-Linux-Manager-Server-SLE/$SUMAPRODUCT/x86_64 -r $SUMAREGCODE
    zypper install -y podman mgradm mgradm-bash-completion
    systemctl enable --now podman.service
    parted /dev/vdb mklabel gpt
    parted /dev/vdb mkpart primary xfs 1MiB 204799MiB
    mgr-storage-server /dev/vdb1
    if [[ -n "$MIRRORUSER" ]]; then
      echo "scc:" >>/tmp/mgradm.yaml
      echo "  user: ${MIRRORUSER}" >>/tmp/mgradm.yaml
      echo "  password: ${MIRRORPASS}" >>/tmp/mgradm.yaml
    fi
    mgradm -c /tmp/mgradm.yaml install podman suma15.labs.suse.com
    if [[ -n "$MIRRORUSER" ]]; then
      echo "Configuring channels using mirror credentials.."
      podman cp /tmp/.mgr-sync uyuni-server:/root/
      mgrctl exec -- mgr-sync refresh
      mgrctl exec -- mgr-sync add channel sle-product-sles15-sp7-pool-x86_64
      mgrctl exec -- mgr-sync add channel sle-product-sles15-sp7-updates-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-basesystem15-sp7-pool-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-basesystem15-sp7-updates-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-server-applications15-sp7-pool-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-server-applications15-sp7-updates-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-python3-15-sp7-pool-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-python3-15-sp7-updates-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-systems-management-15-sp7-pool-x86_64
      mgrctl exec -- mgr-sync add channel sle-module-systems-management-15-sp7-updates-x86_64
      mgrctl exec -- mgr-sync add channel managertools-sle15-pool-x86_64-sp7
      mgrctl exec -- mgr-sync add channel managertools-sle15-updates-x86_64-sp7
      mgrctl exec -- mgr-sync list channels
    fi
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
