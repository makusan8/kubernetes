#!/usr/bin/env bash
######################################
# This script was tested on Debian 12
######################################


# Load modules
echo '###Loading require modules..'
tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
sleep 1

# Enable sysctl ip forwarding
echo '###Enabling ip forwarding..'
tee /etc/sysctl.d/10-ip-forwarding.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
sleep 1


# Install prequisite
echo '###Installing prequisite..'
nala update
nala install -y libseccomp2 gnupg2 curl apt-transport-https ca-certificates software-properties-common
sleep 1

# Install cri-o container


# Install k8s
echo '###Installing k8s..'
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/cgoogle.gpg
tee /etc/apt/sources.list.d/kubernetes.list<<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main
# deb-src http://apt.kubernetes.io/ kubernetes-xenial main
EOF

nala update
nala install git docker.io kubelet kubeadm kubectl -y
sleep 1
apt-mark hold kubelet kubeadm kubectl

tee /etc/systemd/system/kubelet.service.d/0-containerd.conf<<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF

sleep 1
systemctl daemon-reload
systemctl enable kubelet