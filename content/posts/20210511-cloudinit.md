---
title: "Ubuntu cloud images with KVM"
date: 2021-05-11T18:22:08+02:00
draft: false
categories:
  - blog
tags:
  - libvirt
  - ubuntu
---

Ubuntu are using [`cloud-init`](https://cloudinit.readthedocs.io/en/latest/) for their [cloud images](https://cloud-images.ubuntu.com/). This can be used in combination with [`libvirtd`](https://libvirt.org/) and [`kvm`](https://www.linux-kvm.org/page/Main_Page) to pre-configure your virtual machine at boot.

<!--more-->

## Prepare cloud-init configuration

You can specify much more configuration than we've done in this example. This configuration sets the password `ubuntu` for the default user for the image. On Ubuntu images this user is `ubuntu`.

```bash
cat >user-data <<EOF
#cloud-config
password: ubuntu
chpasswd: { expire: False }
ssh_pwauth: True
EOF
```

Create a disk image out of the configuration.

```bash
cloud-localds user-data.img user-data
```

## Virtual machine using cloud-init

### Placing the files

1. Download your prefered cloud image which ends with `.img`. They are [qcow2](https://en.wikipedia.org/wiki/Qcow) images.
0. Copy the image to `/var/lib/libvirit/images/your-vm-name.img`
0. Resize the disk to the size you want, example 16G.
    ```bash
    qemu-img resize /var/lib/libvirt/images/your-vm-name.img 16G
    ```
0. Copy the configuration image to `/var/lib/libvirt/images/user-data.img`

### Creating the VM

* Create the VM definition. Use `your-vm-name.img` as your primary disk.
* Then add a secondary disk with the configuration data, `user-data.img`.
* Boot the virtual machine. Now it will run `cloud-init` on first boot.
* After first boot you can remove the `user-data.img` disk. This can be done live. You need to do this step if you want to use snapshots from the graphical interface.

<!---
vim: set spell spelllang=en:
-->
