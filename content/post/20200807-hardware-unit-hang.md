---
title: "e1000e: Detected Hardware Unit Hang"
date: 2020-08-07T01:20:05+02:00
draft: false
categories:
  - blog
tags:
  - NetworkManager
  - bug
  - network
---

Are you, as I, suffering from *Detected Hardware Unit Hang* in the kernel log from an e1000e network card? How do you notice it. A transfer goes to zero bytes for around 10 seconds, then restarts, then goes to zero, then restarts and so on...

<!--more-->

## Workaround

The workaround is to turn off TCP offloading on the network card. This can be done with `ethtool` or with NetworkManager as a more permanent solution. I found the workaround on Server Fault, [e1000e Reset adapter unexpectedly / Detected Hardware Unit Hang](https://serverfault.com/questions/616485/e1000e-reset-adapter-unexpectedly-detected-hardware-unit-hang).

### ethtool

```bash
ethtool -K eth0 tx off rx off
```

### NetworkManager

This was my permanent solution on my problem. See *The bug*. Documentation of this way of modifying the network card was provided by RedHat at [Chapter 29. Configuring ethtool offload features using NetworkManager](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/configuring-ethtool-offload-features-using-networkmanager_configuring-and-managing-networking).

1. Find the network card NetworkManger connection name. My network card name is `eno1`. See the log excerpt from *The bug*.
    ```bash
    nmcli dev show eno1 | grep -i general.conn
    ```
0. Add permanent configuration to the connection. My connection is named `bridge0 slave 1`.
    ```bash
    nmcli con modify 'bridge0 slave 1' ethtool.feature-rx off ethtool.feature-tx off
    ```
0. Activate.
    ```bash
    sudo nmcli con up 'bridge0 slave 1'
    ```

## The bug

You detect it in the **kernel** log. You'll see them in `dmesg` or `journalctl -b -t kernel` it will look something like this:

```text {hl_lines=[1]}
[ 2044.821230] e1000e 0000:00:1f.6 eno1: Detected Hardware Unit Hang:
                 TDH                  <3e>
                 TDT                  <6d>
                 next_to_use          <6d>
                 next_to_clean        <3d>
               buffer_info[next_to_clean]:
                 time_stamp           <1001a884a>
                 next_to_watch        <3e>
                 jiffies              <1001a9f40>
                 next_to_watch.status <0>
               MAC Status             <40080083>
               PHY Status             <796d>
               PHY 1000BASE-T Status  <3c00>
               PHY Extended Status    <3000>
               PCI Status             <10>
[ 2046.036778] e1000e 0000:00:1f.6 eno1: Reset adapter unexpectedly
[ 2046.036873] bridge0: port 1(eno1) entered disabled state
[ 2051.705902] e1000e 0000:00:1f.6 eno1: NIC Link is Up 1000 Mbps Full Duplex, Flow Control: Rx/Tx
[ 2051.706018] bridge0: port 1(eno1) entered blocking state
[ 2051.706023] bridge0: port 1(eno1) entered forwarding state
```

This was taken from my own `dmesg`.

<!---
# vim: set spell spelllang=en:
-->
