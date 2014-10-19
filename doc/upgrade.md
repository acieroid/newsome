# How to keep FreeBSD up-to-date

We use the `freebsd-update` tool to do so.

## Upgrading to the last patch of the current version

This should take only a few minutes to perform the whole process.

If the kernel is modified, this will require a reboot. If it was not the case,
it is still a good idea to reboot (will use newer version of executables, might
show you what broke).

### The host
    freebsd-update fetch
    freebsd-update install

### The jails
    ezjail-admin update -u

## Upgrading to a different FreeBSD version

First, make sure that you are at the latest patch release. If this is not the
case, upgrade to the latest patch release first (see previous section).
We take as an example an upgrade from 9.2-RELEASE-p12 to 9.3-RELEASE.

The whole process can take a substantial amount of time, depending on the delta
between the versions. An upgrade from 9.2 to 9.3 takes less than an hour, but
from 9.2 to 10.0 it takes a few hours.

### The host
    freebsd-update -r 9.3-RELEASE upgrade
    freebsd-update install

You might need to reboot at this point and run freebsd-update install again, if
you get the following output:

    Installing updates...
    Kernel updates have been installed.  Please reboot and run
    "/usr/sbin/freebsd-update install" again to finish installing updates.

Now, any installed port should be updated. Since we use pkg instead of ports, we just make sure that we are up to date:

    pkg update
    pkg upgrade

Then, we run `freebsd-update install` one more time to finish the installation.

### The jails
    ezjail-admin update -u

This should be quite fast.

TODO: this doesn't seem to correctly perform the update:

    MD5 (/bin/cat) = 9aaf58116a050755500551f4b69504e9
    MD5 (/usr/jails/basejail/bin/cat) = 894ca2bd49ac9e54f46a5f81cc1ea057

## Potential problems

### Problems that prevents boot
  - A mountpoint of `/etc/fstab` is not accessible.

To diagnose and fix those problems without physical access to the machine (eg.
on a kimsufi), you can use qemu to boot the host from a rescuecd (TODO:
document how to do that, this basically involves compiling a static binary of
qemu and booting with the right options).
