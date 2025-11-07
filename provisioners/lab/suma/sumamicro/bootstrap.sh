#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "sumamicro" ]; then
  echo "always"
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    if grep -q "Micro 5" /etc/os-release; then
      transactional-update --continue register -p SUSE-Manager-Server/$SUMAPRODUCT/x86_64 -r $SUMAREGCODE
    else
      transactional-update --continue register -p Multi-Linux-Manager-Server/$SUMAPRODUCT/x86_64 -r $SUMAREGCODE
    fi
    transactional-update --continue run parted /dev/vdb mklabel gpt
    transactional-update --continue run parted /dev/vdb mkpart primary xfs 1MiB 204799MiB
    transactional-update --continue run mkdir -p /var/lib/containers/storage
    transactional-update --continue run mgr-storage-server /dev/vdb1
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
