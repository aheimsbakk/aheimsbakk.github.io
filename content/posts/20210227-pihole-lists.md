---
title: "Malware lists for PiHole"
date: 2021-02-27T18:30:20+01:00
draft: false
categories:
  - uris
tags:
  - security
  - link
---

Excerpt from [Wikipedia](https://en.wikipedia.org/wiki/Pi-hole): *Pi-hole is a Linux network-level advertisement and Internet tracker blocking application which acts as a DNS sinkhole and optionally a DHCP server, intended for use on a private network. It is designed for use on embedded devices with network capability, such as the Raspberry Pi, but it can be used on other machines running Linux, including cloud implementations.*

Configuring [PiHole](https://pi-hole.net/) to resolve IP towards [Quad9](https://www.quad9.net/), which is currently the best public available malware domain filtering DNS service. On top of that you can add your own lists. Recommended lists are the two below.

Sources for malware lists:

* A blocklist of malicious websites that are being used for malware distribution, based on the Database dump (CSV) of Abuse.ch. [Domains and IP addresses](https://curben.gitlab.io/malware-filter/urlhaus-filter-domains.txt), source at [GitHub](https://gitlab.com/curben/urlhaus-filter).
* Unified hosts file with base extensions. [Adware + malware](https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts), source at [GitHub](https://github.com/StevenBlack/hosts)

<!---
vim: set spell spelllang=en:
-->
