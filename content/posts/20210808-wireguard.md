---
title: "Wireguard VPN server"
date: 2021-08-08T15:56:52+02:00
draft: false
categories:
  - blog
tags:
  - network
  - security
  - wireguard
---

From Wikipedia: [WireGuard](https://www.wireguard.com/) is a communication protocol and free and open-source software that implements encrypted virtual private networks (VPNs), and was designed with the goals of ease of use, high speed performance, and low attack surface.

<!-- more -->

## Installation

Install the package that contain the `wg-quick` helper tool.

### Fedora

    sudo dnf install -y wireguard-tools

### Ubuntu

    sudo apt-get install -y wireguard-tools resolvconf

## Configuration

Wireguard is a point to point VPN. Talking about VPN server and VPN clients doesn't make much sense with Wireguard, but it helps to keep sense of which configuration to use where.

On the server we enable IP for both IPv4 and IPv6 and forwards packages to let the clients have internet access. Server and clients communicate on private address ranges. In this example we use `10.0.0.0/24` and `fd00::/64`.


### Server and client

Generate private and public key for server and clients.

```bash
# Secure Wireguard keys and config
umask 077

# Generate private and public key
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
```

### Server

If you want to change server IP and Wireguard subnets, do it here.

```bash
export IPV4_IP=10.0.0.1
export IPV4_NET=10.0.0.0/24
export IPV6_IP=fd00::1
export IPV6_NET=fd00::/64
```

Configure the IP forwarding and main Wireguard configuration.

```bash
# Set variables
GATEWAY_INTERFACE=$(ip route | grep default | cut -d' ' -f5)
PRIVATE_KEY=$(sudo cat /etc/wireguard/privatekey)
PUBLIC_KEY=$(sudo cat /etc/wireguard/publickey)

# Allow IP forwarding
cat <<EOF | sudo tee /etc/sysctl.d/99-forward.conf
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF
sudo sysctl -p /etc/sysctl.d/99-forward.conf

# Secure Wireguard keys and config
umask 077

# Create inital configuration
cat <<EOF | sudo tee /etc/wireguard/wg0.conf
[Interface]
Address = $IPV4_IP, $IPV6_IP
SaveConfig = true
PostUp = iptables -I FORWARD -i %i -j ACCEPT; iptables -t nat -I POSTROUTING -s $IPV4_NET -o $GATEWAY_INTERFACE -j MASQUERADE; ip6tables -I FORWARD -i %i -j ACCEPT; ip6tables -t nat -I POSTROUTING -s $IPV6_NET -o $GATEWAY_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -s $IPV4_NET -o $GATEWAY_INTERFACE -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -s $IPV6_NET -o $GATEWAY_INTERFACE -j MASQUERADE
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
EOF

# Enable wireguard configuration
sudo systemctl enable wg-quick@wg0 --now

# Allow wireguard port, replace with firewalld if you're using it
test -f /usr/sbin/ufw && ufw allow 51820/udp
```

### Client(s)

Change variables for each client.

```bash
export IPV4_IP=10.0.0.10
export IPV6_IP=fd00::10
# Change to your servers key and address
export SERVER_PUBLIC_KEY=hN5CiKMB8hiV4zoX/hztqamV/Lpz2TcPUGFtABRQYgc=
export SERVER_ADDRESS=my.wireguard.server.foo:51820
```

And then write the client configuration.

```bash
# Set variables
PRIVATE_KEY=$(sudo cat /etc/wireguard/privatekey)
PUBLIC_KEY=$(sudo cat /etc/wireguard/publickey)

cat <<EOF | sudo tee /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $PRIVATE_KEY
DNS = 1.1.1.1, 1.0.0.1
Address = $IPV4_IP, $IPV6_IP
ListenPort = 51820

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
# If your client is behind a NAT firewall
PersistentKeepalive = 25
Endpoint = $SERVER_ADDRESS
EOF

# Allow wireguard port, replace with firewalld if you're using it
test -f /usr/sbin/ufw && ufw allow 51820/udp

# Write out command to run on the server once to add this client
echo wg set wg0 peer $PUBLIC_KEY allowed-ips $IPV4_IP,$IPV6_IP
```

The `SaveConfig` on the server ensures that the client will be stored permanently.


<!---
vim: set spell spelllang=en:
-->
