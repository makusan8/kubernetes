
# Kubernetes / K8s

## How-To setup basic Kubernetes cluster in a single VM

Prequisites (at least):
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


Change to root and install sudo, nala(package manager), git :

```bash
su -

apt install sudo nala git -y
```

Add sudo right to your user, you've to exit & relogin after that :

```bash
adduser youruser sudo
```

Edit sudoers file, so we don't have to enter password everytime we run it :

```
# from your terminal
sudo visudo
...

# add NOPASSWD: in sudoers
%sudo ALL=(ALL) NOPASSWD:ALL
```

Let's fetch the fastest mirror for nala, choose 1 from the prompt menu :

```bash
sudo nala fetch
```

We're gonna apply few settings to our base VM :

  - install basic utility tools
  - these are useful especially for vm :
    - configure sysctl tweaks
    - disable transparent hubpages

clone this repository, and run the script :

```
git clone https://github.com/makusan8/kubernetes.git
cd kubernetes
chmod +x pre_install.sh
sudo ./pre_install.sh
```


## 2. Installing Kubernetes / K8s

Before we start installing, we need to disable swap and enable few more tweaks to
our system, there are required for k8s or it won't work. 

Ensure swap is disabled :

```bash
# turn off swap
sudo swapoff -a

# disable swap in fstab
cp /etc/fstab /etc/fstab.orig
sed -e '/swap/ s/^#*/#/g' -i /etc/fstab

# disable swap in initramfs-tools
sed -e '/RESUME/ s/^#*/#/g' -i /etc/initramfs-tools/conf.d/resume
```

(Optional) During my OS installation, I've selected full-guided LVM for my disk and 
even if we've disabled the swap above, the logical volume for that swap still exists,
leaving us with an empty space as well. Let's fix that :

```bash
# verify your lv first
sudo lvs

# remove swap lv, doing this will free the swap space
lvremove debian-vg/swap_1

# expand the root volume to use that empty space
lvextend -r -l +100%FREE debian-vg/root

```




* still in progress..




