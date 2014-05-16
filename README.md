FreeBSD + ZFS Installation
==========================

The `install` directory contains some stuff to get a FreeBSD running in no time,
with a ZFS root file system! Get an [image of
mfsBSD](http://mfsbsd.vx.sk/files/images/), boot it, connect to it (ssh is
running by default!) with root:mfsroot as credentials, and copy the
`install/install.sh` script on it, using eg. fetch or scp.

You will probably want to change some parameters in this script, such as the
network-related parameters. Just edit the script. When you're satisfied, launch
`install.sh`:

    # sh install.sh

You will be prompted for a root password at the end of the procedure, and you
can then reboot.

Post-installation
=================

Note: from here, when asked whether you want to bootstrap pkgng, answer
'y'. There doesn't seem to have a way to avoid pkgng to ask this question.

You now have a complete FreeBSD installation. You can use it as-is, or continue
this guide to get an awesome service management infrastructure.

Get the `postinst.sh` script and launch it. It will install fetch the necessary
scripts and do the post-installation steps needed to get awesom's service
management infrastructure running.

    # sh postinst.sh

Service Management
==================

Once everything is installed, you can use the `service-create.sh` script to
deploy new services.

    # service-create.sh paste-py.sh

Look in the `services` directory for example services. The creation of a service
uses variables defined in this service file, and calls setup() from within the
jail. To launch a service, use supervisord, which will call the service's
start() function:

    # supervisorctl start paste

Internally, the service-jail-action script is used to call functions from the
service file, as follows:

    # jexec -U paste test service-jail-action.sh /home/paste/services/paste-py.sh start

It can notably be used to call update() to update the service.

Compatibility
=============
This has been tested and works on the following versions of FreeBSD:
  - 10.0-RELEASE
  - amd64 and i386
  - both normal and standard edition

Ensure your machine have enough RAM : ZFS required at least 512MB.

TODO
====
  - Service update
  - Make scripts idempotent
  - Maor test
  - What else?
