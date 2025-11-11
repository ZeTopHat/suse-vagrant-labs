#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "hana15trento" ]; then
  SUSEConnect --de-register
  SUSEConnect --cleanup
  rpm -e --nodeps sles-release
  SUSEConnect -p SLES_SAP/$SAPPRODUCT/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-basesystem/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-module-desktop-applications/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-module-server-applications/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-ha/$SAPPRODUCT/x86_64 -r $SAPREGCODE
  SUSEConnect -p sle-module-sap-applications/$SAPPRODUCT/x86_64
  SUSEConnect -p sle-module-containers/$SAPPRODUCT/x86_64
  zypper install -y zypper-search-packages-plugin helm trento-server-installer unzip bash-completion
  zypper install -y -t pattern apparmor
  echo "${SUBNET}${N1IP} hana15n1.labs.suse.com hana15n1" >>/etc/hosts
  echo "${SUBNET}${N2IP} hana15n2.labs.suse.com hana15n2" >>/etc/hosts
  if [ "$DEPLOY" == "training" ]; then
    echo "training"
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "fulldeploy"
    install-trento-server --admin-password vagrantVAGRANT --trento-web-origin hana15trento.labs.suse.com
    /usr/local/bin/k3s completion bash >/root/.bashrc
    /usr/local/bin/k3s kubectl completion bash >>/root/.bashrc
    echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >>/root/.bashrc
    sed -i 's/^DHCLIENT_SET_DEFAULT_ROUTE.*/DHCLIENT_SET_DEFAULT_ROUTE="no"/' /etc/sysconfig/network/dhcp
    echo 'DHCLIENT_SET_DEFAULT_ROUTE="yes"' >>/etc/sysconfig/network/ifcfg-eth2
    echo "## To add a client to trento run the following on that client:" >/root/trentoclient.txt
    echo "# zypper install trento-agent" >>/root/trentoclient.txt
    echo "# vim /etc/trento/agent.yaml" >>/root/trentoclient.txt
    echo "##change the following variables:" >>/root/trentoclient.txt
    echo "facts-service-url: amqp://trento:trento@hana15trento.labs.suse.com:5672" >>/root/trentoclient.txt
    echo "server-url: http://hana15trento.labs.suse.com" >>/root/trentoclient.txt
    echo "api-key: <retrieved from trento settings web page>" >>/root/trentoclient.txt
    echo "# vim /etc/hosts" >>/root/trentoclient.txt
    echo "##Make sure the client resolves hana15trento.labs.suse.com" >>/root/trentoclient.txt
    echo "# systemctl enable --now trento-agent" >>/root/trentoclient.txt
    systemctl restart network
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
