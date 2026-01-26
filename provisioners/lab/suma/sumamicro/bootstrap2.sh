#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} part 2 configurations..."

if [ "$MACHINE" == "sumamicro" ]; then
  echo "always part 2"
  if [ "$DEPLOY" == "training" ]; then
    echo "training part 2"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy part 2"
    if [[ -n "$MIRRORUSER" ]]; then
      echo "scc:" >>/tmp/mgradm.yaml
      echo "  user: ${MIRRORUSER}" >>/tmp/mgradm.yaml
      echo "  password: ${MIRRORPASS}" >>/tmp/mgradm.yaml
    fi
    mgradm -c /tmp/mgradm.yaml install podman sumamicro.labs.suse.com
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

echo "Finished deploying ${MACHINE} ${DEPLOY} part 2 configurations."
