#!/usr/bin/env bash
######################################
# This script was tested on Debian 12
######################################


## Load modules
echo '###Loading require modules..'
tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
sleep 1

## Enable sysctl ip forwarding
echo '###Enabling ip forwarding..'
tee /etc/sysctl.d/10-ip-forwarding.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
sleep 1


## Install prequisite
echo '###Installing prequisite..'
nala install gnupg2 \
libseccomp2 \
curl \
lsb-release \
apt-transport-https \
ca-certificates \
software-properties-common -y
sleep 1

# Install cri-o container
echo '###Installing cri-o container..'
OS=Debian_12
VERSION=1.26

# add Kubic Repo
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | \
sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

# import public key
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | \
sudo apt-key add -

# add cri-o repo
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | \
sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

# import another public key
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | \
sudo apt-key add -

# install cri-o
sudo nala update && sudo nala upgrade -y
sudo nala install cri-o cri-o-runc cri-tools -y

# start cri-o
sudo systemctl enable crio.service
sudo systemctl start crio.service
sleep 1

## Install k8s
echo '###Installing k8s..'
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/cgoogle.gpg
tee /etc/apt/sources.list.d/kubernetes.list<<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main
# deb-src http://apt.kubernetes.io/ kubernetes-xenial main
EOF

sleep 1

nala update
nala install kubelet kubeadm kubectl -y
apt-mark hold kubelet kubeadm kubectl

sleep 1
systemctl daemon-reload
systemctl enable kubelet

echo '###Done installing k8s..'