#!/usr/bin/env bash
###########################################################
# Base script to get started on a new vm (Debian-12 minimal)
###########################################################

# install some utility
echo '###Installing utility apps..'

nala install git ethtool htop net-tools tree -y
sleep 2

# configure sysctl tweaks
echo '###Configuring sysctl tweaks..'

cd vm
for i in *.conf;
do
        cp "$i" /etc/sysctl.d/;
        sysctl -p /etc/sysctl.d/"$i" >/dev/null 2>&1;
done
sleep 2

# disable transparent hubpages
echo '###Disabling transparent hubpages..'

cp /etc/default/grub /etc/default/grub.orig

isInGrub=$(cat /etc/default/grub | grep -c "transparent_hugepage")

if [ $isInGrub -eq 0 ]; then
        sed -e "/^GRUB_CMDLINE_LINUX=/ s/\"$/transparent_hugepage=never\"/" -i /etc/default/grub
else
        echo 'transparent_hubpage has been disabled, skipped..'
fi
sleep 1

# complete
echo '###Task is completed..'
