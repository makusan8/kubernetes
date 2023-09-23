
# Kubernetes / K8s

## How-To setup basic Kubernetes cluster on a single VM

Prequisites (at least):
  - Debian 12 minimal
  - 2 core
  - 2gb ram
  - 30gb hd
  - nala package manager
  - sudo right

I'll be using freshly installed Debian 12 (minimal) as my vm,
you can either use other distro of your choice as well. Be sure
to change the package manager and package names accordingly.

Once you're ready, let's start :-)


## 1. Install & Configure base system

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

Edit sudoers file, so we don't have to enter password everytime we run sudo :

```
sudo visudo

%sudo ALL=(ALL) NOPASSWD:ALL
```

Let's fetch the fastest mirror for nala, choose 1 from the prompt menu :

```bash
sudo nala fetch
```

We're gonna apply few settings to our base vm :

  - install basic utility tools
  - configure sysctl tweaks
  - disable transparent hubpages
  - disable swap 

Clone this repository, and run the script :

```bash
git clone https://github.com/makusan8/kubernetes.git
cd kubernetes
chmod +x pre_install.sh
sudo ./pre_install.sh
```


## 2. Install & Configure Kubernetes / K8s
