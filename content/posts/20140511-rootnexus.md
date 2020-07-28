---
title: Flashing a custom rom on Nexus 4
date: 2014-05-11
draft: false
categories:
  - blog
tags:
  - howto
  - android
---

Flashing a custom image on an [Android] mobile could be just fun. But if you don't know why you want to do it, or do it just because it's a challenge. **Then don't!** 

## The bad and the good

I'm only pointing out some of the cons and the pros here.

### Negative sides 

* An OS image could contain [malware]; only use community trusted images.
* If you don't pay attention you can get [malware] running as root. That's B A D !
* May not have all the phones vendor functionality. 
* The image may be buggy.

#### Consequences of a buggy image

* Lock up your phone when you least expect it.
* Drain the battery quicker. 
* Suddenly reboot.

### Positive sides 

* You can get a newer more secure operating system.
* Use less battery.
* No [crapware].
* Extra security functions.

## Flashing CyanogenMod

One of the custom [Android] images based on [AOSP] is [CyanogenMod]. As I know, it's one of the more used ones. Quite stable if you keep away from the [nightlies] and rich on functionality but not bloated.

### Preparations 

1. Install [adb] and [fastboot] to help manage your Nexus phone.

        sudo apt-get install android-tools-adb android-tools-fastboot

2. Download custom a recovery image. Personally I prefer [ClockworkMod] and the touch recovery. Note, this image is compiled for the Nexus 4 phone. Other phones use other images.
    
        wget http://download2.clockworkmod.com/recoveries/recovery-clockwork-touch-6.0.4.7-mako.img

3. Download the latest M snapshot from [CyanogenMod] on [download.cyanogenmod.org](http://download.cyanogenmod.org). The model name for Nexus 4 is *mako*.

        wget http://download.cyanogenmod.org/get/jenkins/67695/cm-11-20140504-SNAPSHOT-M6-mako.zip

4. Download [Google Apps] from a trusted source. Again I prefer [CyanogenMod] as source and download from [wiki.cyanogenmod.org](http://wiki.cyanogenmod.org/w/Google_Apps#Downloads).
    
        wget http://itvends.com/gapps/gapps-kk-20140105-signed.zip

5. And to be on the safe side. Download the origian Nexus 4 firmware from Googles page [Factory Images for Nexus Devices](https://developers.google.com/android/nexus/images). Just in case... And if it is the case, untar the file and read the included instructions.

        wget https://dl.google.com/dl/android/aosp/occam-kot49h-factory-02e344de.tgz

### Doing the deed

This is notes for my personal use. If you decide to go through with this I don't take any responsibility for any [bricked] or damaged devices. 

#### 1. Enable USB debugging on Android

* **Settings** → **About phone**. 

        Press repeatedly on **Build number** until you become a developer.
    
* **Settings** → **Developer options**. 

        Check **USB debugging**.

#### 2. Unlock bootloader

* Connect phone to computer with USB cable.

* Check that the cable is usable by listing devices with adb. If you don't get any response. Change the cable and try again. The last cable could be a cheep charger cable without data wires.

        adb devices

* Reboot phone into [bootloader].

        adb reboot bootloader

* Check that you get connection with [fastboot].

        fastboot devices

* Unlock your [bootloader]. This takes some time while the phone is erasing all data.

        fastboot oem unlock

* Choose **Yes** on phone by pressing **Volume up**, and then accept by pressing **Power**.

#### 3. Flash and enter recovery

* Flash recovery image.

        fastboot flash recovery recovery-clockwork-touch-6.0.4.7-mako.img

* Enter recovery image by pressing **Volume up** until **Recovery mode** is shown on top of screen. Press **Power** to enter the recovery image.

#### 4. Prepare and install CyanogenMod

* In [ClockworkMod] Recovery enter **mounts and storage** → **format /system**. **Yes - Format**.

* In [ClockworkMod] Recovery enter **mounts and storage** → **format /data and /data/media (/sdcard)**. **Yes - Format**.

* Check the partitions is OK by going back to main menu and choose **wipe data/factory reset** and **Yes - Wipe all user data**. Check that you don't get any errors on formatting **/data**.

* Choose **install zip** → **choose zip from sideload** and sideload [CyanogenMod].

        adb sideload cm-11-20140504-SNAPSHOT-M6-mako.zip

* Then sideload gapps. Select again **choose zip from sideload**.

        adb sideload gapps-kk-20140105-signed.zip

* Just be on the safe side, go back and choose **wipe data/factory reset** and **Yes - Wipe all user data**.

* **reboot system now**. First boot takes some time, be patient. 

If you get problems booting into a clean system, I've read that another factory reset could do the trick. 

#### 5. Encrypt or not

After installing the phone you can choose to encrypt it or not. I like to encrypt my device with a passphrase. It's my data so why give it away if the phone get stolen; encryption makes it a bit harder for the bad guys.

[bootloader]: https://en.wikipedia.org/wiki/Bootloader "Booting"
[bricked]: https://en.wikipedia.org/wiki/Bricked "Bricked"
[Google Apps]: https://en.wikipedia.org/wiki/Google_apps
[ClockworkMod]: http://www.clockworkmod.com
[malware]: https://en.wikipedia.org/wiki/Malware "Malware"
[Android]: https://en.wikipedia.org/wiki/Android_%28operating_system%29 "Android operating system"
[crapware]: https://en.wikipedia.org/wiki/Crapware "Pre-installed software"
[AOSP]: https://source.android.com "Android Open Source Project"
[Cyanogenmod]: http://www.cyanogenmod.org 
[nightlies]: https://en.wikipedia.org/wiki/Nightlies "Neutral build"
[adb]: https://developer.android.com/tools/help/adb.html "Android Debug Bridge"
[fastboot]: https://en.wikipedia.org/wiki/Android_software_development#Fastboot "Fastboot"


