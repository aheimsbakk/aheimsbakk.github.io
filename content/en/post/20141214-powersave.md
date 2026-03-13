---
title: Power saving on laptop
date: 2014-12-14
draft: false
categories:
  - blog
tags:
  - intel
---

Notes for power saving on my i5 laptop.

<!--more-->

## /etc/rc.local

```bash
#  SATA power save
echo medium_power | tee /sys/class/scsi_host/host*/link_power_management_policy > /dev/null

# Set minimum performance to 30% of CPU MHz
echo 30 > /sys/devices/system/cpu/intel_pstate/min_perf_pct

# Set CPU governor to power save since we run on a laptop
# Valid values: powersave performance
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null

# Increase for CrashPlan so unlocking gnome-shell lock screen works
echo 1048576 > /proc/sys/fs/inotify/max_user_watches
```

## /etc/default/grub

```bash
# Make my back light buttons work correctly
# Full power save for GPU
GRUB_CMDLINE_LINUX="video.use_native_backlight=1 i915.enable_rc6=7 i915.enable_fbc=1 i915.lvds_downclock=1"
```

