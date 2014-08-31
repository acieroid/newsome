FreeBSD + ZFS Installation
==========================

The `install` directory contains some stuff to get a FreeBSD running in no
time, with a ZFS root file system! Get an [image of
mfsBSD](http://mfsbsd.vx.sk/files/images/), boot it, connect to it (ssh is
running by default!) with root:mfsroot as credentials.

You will probably want to set some parameters concerning the installation, such
as the network-related parameters. Just edit the ``parameters.sh`` script:

    $ vi parameters.sh


When you're satisfied, copy the parameters script and `install.sh`, and launch
the installation:

    $ scp install.sh parameters.sh root@ip:
    $ ssh root@ip # mfsbsd connects with dhcp, root password: mfsroot
    # sh install.sh

You will be prompted for a root password at the end of the procedure, and you
can then reboot.

Post-installation
=================

Note: from here, when asked whether you want to bootstrap pkgng, answer
'y'. There doesn't seem to have a way to avoid pkgng to ask this question.

You now have a complete FreeBSD installation. You can use it as-is, or continue
this guide to get an awesome service management infrastructure.

Get the `postinst.sh` script (as well as your modified version of the
`parameters.sh` script) and launch it. It will fetch the necessary scripts and
do the post-installation steps needed to get awesom's service management
infrastructure running.

    $ scp postinst.sh parameters.sh root@ip:
    $ ssh root@ip # root password is the password you gave during installation
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
  - both normal and standard edition of mfsBSD

Ensure your machine have enough RAM : ZFS required at least 512MB.

Status
======

  - ✔ Installation script (`install/install.sh`): works great @acieroid
  - ~ Post-installation (`install/*.sh`): not perfect
    - Not tested since last modification (pf.conf generation)
    - TODO: install & setup unbound
      - no idea of the requirements & how to configure
    - TODO: SSL @nginx
      - one certificate per domain?
    - TODO: nicer default pages @nginx
      - replace 502 by some information page
      - awesom home page
    - TODO: host on which to listen in nginx.conf
  - ~ Service management (`service-utils/`): almost complete:
    - service-manager.py
      - ✔ start, stop, restart
      - not tested: update
      - ✗ update service description
    - service-create.sh (not tested since last modification)
      - TODO: ssh of jail at IP 172.0.16.XXX on port 42XXX
      - TODO: parameters (eg. $JINTERFACE)
      - TODO: backups: how?
        - maybe define a list of files/directories to backup in the service
          description file
      - TODO: how to let the user update its description?
        - idea: the service should have a $NAME.sh in  his directory/repo, and
          can send a update-description command through the pipe, resulting in
          service-update-description.sh being run on the host (as it needs to
          possibly update the host, port, or deps). A change to the jail or
          service name should not be authorized.
          - changes to the host might also be refused to avoid clashes, or in
            general
    - TODO: service-delete.sh: send remove command to service-manager,
      then remove the user, and the jail if it is empty
    - move scripts not needed by the admin somewhere else than in PATH to avoid
      auto-completion on those services and therefore provide a simpler
      interface
  - ✗ Awesom services descriptions (`services/`): incomplete (only paste)
    - come up with a few skeleton (for go, pyhon, etc.) and guidelines (eg.
     "don't rely on variables not defined inside the service file itself")