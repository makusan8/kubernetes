
# Kubernetes / K8s

## How-To setup Kubernetes cluster in a single VM

Prequisites (at least):
  - Basic kubernetes knowledge
  - Debian 12 minimal
  - 2 core
  - 2gb ram
  - 20gb hd
  - nala package manager
  - sudo right

I'll be using freshly installed Debian 12 (minimal) as my VM,
you can either use other distro of your choice as well. Be sure
to change the package manager and package names accordingly.

Once you're ready, let's start :-)


## 1. Preparing our base vm

Debian minimal usually don't have sudo installed by default,
unless you didn't specify root password during your os installation.


- Change to root and install sudo, nala(package manager), git :

```bash
su -
apt install sudo nala git -y

```

- Add sudo right to your user, you've to exit & relogin after that :

```bash
adduser youruser sudo

```

- Edit sudoers file, so we don't have to enter password everytime we run it :

```

# from your terminal
sudo visudo

...
# add NOPASSWD: in sudoers
%sudo ALL=(ALL) NOPASSWD:ALL

```

- Fetch the fastest mirror for nala, choose 1 from the prompt menu :

```bash
sudo nala fetch

```

We're gonna apply few settings to our base VM :

  - install basic utility tools
  - these are useful especially for vm :
    - configure sysctl tweaks
    - disable transparent hubpages

- clone this repository, and run the script :

```
git clone https://github.com/makusan8/kubernetes.git
cd kubernetes
chmod +x pre_install.sh
sudo ./pre_install.sh

```

## 2. Enable some config for Kubernetes / K8s

Before we start installing k8s, we need to disable swap and enable few more tweaks to
our system, these are required for k8s or it won't work properly. 

- Ensure swap is disabled :

```bash
# turn off swap
sudo swapoff -a

# disable swap in fstab
sudo cp /etc/fstab /etc/fstab.orig
sudo sed -e '/swap/ s/^#*/#/g' -i /etc/fstab

# disable swap in initramfs-tools
sudo sed -e '/RESUME/ s/^#*/#/g' -i /etc/initramfs-tools/conf.d/resume

```

(Optional) During my OS installation, I've selected full-guided LVM for my disk and 
even if we've disabled the swap above, the logical volume for that swap still exists,
leaving us with an empty space as well. Let's fix that :

```bash
# verify your lv first
sudo lvs

# remove swap lv, doing this will detach the swap space
sudo lvremove debian-vg/swap_1

# expand the root volume to use that empty swap space
sudo lvextend -r -l +100%FREE debian-vg/root

```

> [!NOTE]
> If you want to automatically install k8s, 
> you can just run my script ks8_install.sh
> this will cover the installation until step 3 : 

```
chmod +x ks8_install.sh
sudo ./ks8_install.sh

```

### For manual way, let's follow along below :

- Load the bridge, overlay modules and enable ip routing :

```bash 
# add this in k8s.conf
sudo tee /etc/modules-load.d/k8s.conf<<EOF
overlay
br_netfilter
EOF

# load modules
sudo modprobe overlay
sudo modprobe br_netfilter

# enable sysctl ip routing & bridging
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# reload our sysctl
sudo sysctl --system

```


## 3. Install CRI-O Container Runtime & K8s

We'll be using CRI-O, this is the easiest runtime to setup compare
to Containerd or Docker

- Let's continue to install our container first :

```bash
# install requirements
sudo nala install gnupg2 \
libseccomp2 \
curl \
lsb-release \
apt-transport-https \
ca-certificates \
software-properties-common -y

# set variables, copy this in terminal
OS=Debian_12
VERSION=1.26

# add Kubic Repo, copy this in one sentence
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | \
sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

# import public key, copy this in one sentence
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | \
sudo apt-key add -

# add cri-o repo, copy this in one sentence
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | \
sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

# import another public key, copy this in one sentence
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | \
sudo apt-key add -

# install cri-o
sudo nala update && sudo nala upgrade -y
sudo nala install cri-o cri-o-runc cri-tools -y

# start cri-o
sudo systemctl enable crio.service
sudo systemctl start crio.service

# check cri-o status
sudo systemctl status crio.service
sudo crictl info

```

For our k8s,

- Install kubectl, kubelet, kubeadm :

```bash
# import key, copy this in one sentence
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | \ 
sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/cgoogle.gpg

# enable k8s repo
sudo tee /etc/apt/sources.list.d/kubernetes.list<<EOF
deb http://apt.kubernetes.io/ kubernetes-xenial main
# deb-src http://apt.kubernetes.io/ kubernetes-xenial main
EOF

# install k8s
sudo nala update
sudo nala install -y kubelet kubeadm kubectl

# hold k8s packages to prevent upgrade
sudo apt-mark hold kubelet kubeadm kubectl

# reload systemctl
sudo systemctl daemon-reload
sudo systemctl enable kubelet

```

Finally we're almost ready..


## 4. Start K8s Cluster

Now we can start initiating our cluster :

> [!NOTE]
> the --pod-network-cidr ip range below is optional,
> as long it doesn't interfere with our LAN network.

```
# initiate the cluster

sudo kubeadm init --node-name master --pod-network-cidr=192.168.0.0/16

```

The cluster will take some time to finish, because it will download
few images first and store them into cri-o container.

- Once it's finished, you can see the images : 

```
# check the images
sudo crictl images

# --output from command above
registry.k8s.io/coredns/coredns           v1.10.1
registry.k8s.io/etcd                      3.5.9-0 
registry.k8s.io/kube-apiserver            v1.28.2 
registry.k8s.io/kube-controller-manager   v1.28.2 
registry.k8s.io/kube-proxy                v1.28.2
registry.k8s.io/kube-scheduler            v1.28.2
registry.k8s.io/pause                     3.6     
registry.k8s.io/pause                     3.9

```

- Let's make kubectl work for current user :

```
# copy kubectl config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

We can just run kubectl command without sudo.

- Let's check our node :

```
# check the nodes
kubectl get nodes

# --output from above command
NAME     STATUS   ROLES           AGE   VERSION
master   Ready    control-plane   28m   v1.28.2

# full view of the nodes
kubectl get nodes -o wide

```

- View cluster pods :

```
# check the pods
kubectl get pods --all-namespaces -o wide

# --output from above command
NAMESPACE     NAME                             READY   STATUS
kube-system   coredns-5dd5756b68-5h2st         0/1     ContainerCreating
kube-system   coredns-5dd5756b68-lcwvm         0/1     ContainerCreating

```

As you can see above, the coredns pods are in Creating/Pending state. These pods
are responsible to our internal DNS.

It turns out that we don't have any network plugin yet in our cluster.

- Install the calico network plugin :

```
# install calico network plugin
kubectl apply -f https://projectcalico.docs.tigera.io/manifests/calico.yaml

```

- Wait until all the pods status are running :

```
# watch the pods progress
watch kubectl get pods -n kube-system

# control + c to stop after all the pods are running

```

If you've noticed, there are two coredns currently running in our cluster.
For single VM we don't really need that, because we're just running it in single node.

- Scale down the CoreDNS :

```
# edit the coredns config 
kubectl edit -n kube-system deployment coredns

# --edit the replicas value to 1, you'll enter in vi mode
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10

```

- Now we only have one pod of coredns running :

```
# check dns
kubectl -n kube-system get pods

# --output from above command
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-7ddc4f45bc-p2c8q   1/1     Running   0          14m
calico-node-wxcc9                          1/1     Running   0          14m
coredns-5dd5756b68-5h2st                   1/1     Running   0          60m
etcd-master                                1/1     Running   0          60m
kube-apiserver-master                      1/1     Running   0          60m
kube-controller-manager-master             1/1     Running   0          60m
kube-proxy-rlcmm                           1/1     Running   0          60m
kube-scheduler-master                      1/1     Running   0          60m

```

- Let's check again our nodes status :

```
# node status
kubectl get nodes -o wide

# cluster information
kubectl cluster-info

# global health check
kubectl get --raw='/readyz?verbose'

```

Before we move forward, our steps so far are just for setting up single node cluster,
meaning we don't have any other worker nodes around it. 

By default, K8s assumes you will be connecting other nodes to your master node
to make a 'proper' cluster. So to stop us from placing our Pods in the master,
they have applied a taint to your node, which is called 'NoSchedule'.

And we need to remove it's taint mode. Otherwise, our pods will be stucked
in a pending state.

- Check the taints :

```
# check the taint status
kubectl get node master -o yaml

# --output from above command
taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane

```

- Remove the taints :

```
# remove the taints
kubectl taint nodes --all node-role.kubernetes.io/control-plane=:NoSchedule-

# add worker labal to master node
kubectl label node master node-role.kubernetes.io/worker=

# see our node again
kubectl get nodes

# --output from above command
NAME     STATUS   ROLES                  AGE   VERSION
master   Ready    control-plane,worker   18h   v1.28.2

```

Great! now we can start testing out our cluster by deploying a test app.

- Create a test yaml file (nginx) :

```
# create test-app.yaml
nano test-app.yaml

# copy paste this config below
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
	labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.18.0
        ports:
        - containerPort: 80

```

- Deploy the test app :

```
# deploy the app
kubectl apply -f test-app.yaml

# check the status
kubectl get pods

# --output from above command
NAME                     READY   STATUS    RESTARTS   AGE
nginx-584b4f6d78-p7wzx   1/1     Running   0          3m8s
nginx-584b4f6d78-vtpn9   1/1     Running   0          3m8s

```

- Digging more into our test app :

```
# get the ip
kubectl get pods -o wide

# -- output from above command (truncated)
NAME				IP
nginx-584b4f6d78-p7wzx		192.168.219.71
nginx-584b4f6d78-vtpn9		192.168.219.70

# ping
ping 192.168.219.71
PING 192.168.219.71 (192.168.219.71) 56(84) bytes of data.
64 bytes from 192.168.219.71: icmp_seq=1 ttl=64 time=0.114 ms
64 bytes from 192.168.219.71: icmp_seq=2 ttl=64 time=0.036 ms

# check the name of our container
kubectl get pods nginx-584b4f6d78-p7wzx -o jsonpath='{.spec.containers[*].name}'

# --output from above command
nginx

# we can even login inside the container 
kubectl exec -it nginx-584b4f6d78-p7wzx -c nginx -- /bin/bash

# --output from above command
root@nginx-584b4f6d78-p7wzx:/# pwd
/
exit

# access the nginx web using curl or you can use browser
curl http://192.168.219.71

# --output from above command
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>

```

There you have it, a fully functioning Kubernetes Cluster in a single Node/VM,
that is perfect for homelab learning environment!
