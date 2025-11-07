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
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} part 2 configurations."
