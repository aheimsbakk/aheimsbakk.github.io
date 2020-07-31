---
title: List CPU vulnerabilities
date: 2020-07-31T16:25:02+02:00
description: List your CPU vulnerabilities and mitigations.
draft: false
categories:
  - blog
tags:
  - security
  - oneliner
---

[Hardware vulnerabilities]: https://www.kernel.org/doc/html/latest/admin-guide/hw-vuln/index.html

Oneliner to list your CPU vulnerabilities and mitigations. Read more about the different vulnerabilities and mitigations at [Hardware vulnerabilities][].

<!--more-->

```bash
grep -E '.*' /sys/devices/system/cpu/vulnerabilities/* | \
    sed -E 's/(^.*\/)([^:]*):(.*$)/\2 -=> \3/'
```

<!---
# vim: set spell spelllang=en:
-->
