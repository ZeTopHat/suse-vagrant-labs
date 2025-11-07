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
    SUSEConnect -p SUSE-Manager-Server/$SUMAPRODUCT/x86_64 -r $SUMAREGCODE
    SUSEConnect -p sle-module-containers/$SLEPRODUCT/x86_64
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
    fi
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
