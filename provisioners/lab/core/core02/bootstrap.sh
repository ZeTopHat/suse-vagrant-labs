#! /bin/bash

MACHINE=$1
DEPLOY=$2

echo "Deploying ${MACHINE} ${DEPLOY} configurations..."

if [ "$MACHINE" == "core02" ]; then
  if [ "$DEPLOY" == "training" ]; then
    SUSEConnect --product sle-module-desktop-applications/15.5/x86_64
    SUSEConnect --product sle-module-development-tools/15.5/x86_64
    zypper mr -e SLE-Module-Basesystem15-SP5-Debuginfo-Updates
    zypper install -y kdump crash cron
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="crashkernel=296M,high crashkernel=72M,low"/' /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg
    systemctl enable kdump
    sysctl vm.panic_on_oom=1 >/dev/null
    echo "vm.panic_on_oom=1" >>/etc/sysctl.conf
    (sudo crontab -u root -l 2>/dev/null; echo "*/5 * * * * if [[ -f '/root/.do_not_delete' ]]; then exit; else touch /root/.do_not_delete && sync && perl -wE 'my @xs; for (1..2**20) { push @xs, q{a} x 2**20 }; say scalar @xs;' ; fi") | sudo crontab -
    (sudo crontab -u root -l 2>/dev/null; echo "*/4 * * * * if [[ -f '/root/.do_not_delete' ]]; then sudo crontab -r ; else exit ; fi") | sudo crontab -
    reboot
  elif [ "$DEPLOY" == "fulldeploy" ]; then
    echo "There are no fulldeploy configurations. Did you mean to set this to a training deployment?"
  else
    echo "Deployment not recognized."
  fi
else
  echo "Machine not recognized."
fi

echo "Finished deploying ${MACHINE} ${DEPLOY} configurations."
