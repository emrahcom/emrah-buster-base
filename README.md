Table of contents
=================

- [About](#about)
- [Usage](#usage)
- [Templates](#templates)
- [Requirements](#requirements)

---

About
=====

This repository is the infrastructure of the `emrah-buster` installer.
`emrah-buster` is an installer to create the containerized systems on
Debian Buster (_version 10_) host.

---

Usage
=====

Download the installer and run it with the template name as an argument.

```bash
wget https://raw.githubusercontent.com/emrahcom/emrah-buster-base/master/installer/eb
wget https://raw.githubusercontent.com/emrahcom/emrah-buster-base/master/installer/eb-base.conf
bash eb eb-base
```

---

Templates
=========

See the
[emrah-buster-templates](https://github.com/emrahcom/emrah-buster-templates)
repository for the available templates.

---

Requirements
============

`emrah-buster` requires a Debian Buster (_version 10_) host with a minimal
install and the Internet access during the installation. It's not a good idea
to use your desktop machine or an already in-use production server as a host
machine. Please, use one of the followings as a host:

-  a cloud computer from a hosting/cloud service
   ([DigitalOcean](https://www.digitalocean.com/?refcode=92b0165840d8)'s
   droplet, [Amazon](https://console.aws.amazon.com) EC2 instance etc)

-  a virtual machine (VMware, VirtualBox etc)

-  a Debian Buster container (_with the nesting support_)
   ```
   lxc.include = /usr/share/lxc/config/nesting.conf
   lxc.apparmor.profile = unconfined
   lxc.apparmor.allow_nesting = 1
   ```

-  a physical machine with a fresh installed
   [Debian Buster (_version 10_)](https://www.debian.org/releases/buster/debian-installer/)
