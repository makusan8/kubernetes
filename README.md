# Kubernetes / K8s

## How-To setup basic Kubernetes cluster on a single VM

Prequisites (at least):
  - Debian 12 minimal
  - 2 core
  - 2gb ram
  - nala package manager
  - sudo right

I'll be using freshly installed Debian 12 (minimal) as my vm,
you can either use other distro of your choice as well. Be sure
to change the package manager and package names accordingly.

Once you're ready, let's start :-)


## 1. Install & Configure base system

Change to root and install sudo, nala(package manager) :

```bash
su -
apt install sudo nala -y
```

Add sudo right to your user, you've to relogin after that :

```bash
adduser youruser sudo
```

Fetch fastest mirror, choose 1 from the prompt menu :

```bash
sudo nala fetch
```

* still work in progress..
