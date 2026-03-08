---
title: Libvirt and Vagrant
date: 2020-07-28T15:43:42+02:00
draft: false
categories:
  - blog
tags:
  - libvirt
  - vagrant
---

[Vagrant]: https://www.vagrantup.com/
[Libvirt]: https://libvirt.org/
[qemu]: https://www.qemu.org/
[Linux]: https://en.wikipedia.org/wiki/Linux
[Fedora]: https://getfedora.org/
[Ubuntu]: https://ubuntu.com/
[Debian]: https://www.debian.org/

[Libvirt][] is the default toolkit to manage virtualization platforms on Linux. Libvirt and [qemu][] is a great combination with [Vagrant][]. It's the default combination on most [Linux][] systems, also on my favorite - [Fedora][].

This combination allows for some awesome features and some restrictions. One of the restrictions is that [Ubuntu][] isn't available as a box, but [Debian][] is. And Debian is the foundation of Ubuntu, and it's more open than Ubuntu.

The biggest feature is that it allows for more permanent development environments and direct connection to already existing [network bridges](https://en.wikipedia.org/wiki/Bridging_(networking)).

## Preparation

Allow your user to manage libvirt VMs on the computer.

```bash
sudo usermod -Ga libvirt $(whoami)
```

## Vagrantfile

Below is an example of a `Vagrantfile` that creates a VM with connection to a bridge `bridge0` on a network `192.168.1.0/24` that restart automatically after a reboot of the host.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/buster64"

  # Connect to bridge named bridge0 with public IP 192.168.1.100
  config.vm.network "public_network", dev: "bridge0", mode: "bridge", type: "bridge", ip: "192.168.1.100"

  # Use rsync to sync files into /vagrant
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # Libvirt provider
  config.vm.provider "libvirt" do |l|
    l.cpus = 1
    l.memory = "256"

    # Use qemu:///system sesion, not the user session qemu:///session
    l.qemu_use_session = false

    # Restart on host reboot
    l.autostart = true
  end
end
```

<!---
# vim: set spell spelllang=en_GB:
-->
