# Problematic

In the current awesom's deployment, we identify a
few major issues:

- Knowledge fragmentation between various sysadmin, or
  lost of knowledge through time;
- Difficulty to deploy new services easily;
- Difficulty to migrate the whole system from a given
  hardware to another.

This lead to interesting questions like:

- what's the port for this subsystem already?
- ah, i can't install to update this else i might break
  this, this and that?
- when shall we move to a cheaper, up-to-date server? how
  to migrate all that stuff easily?

# Current technical situation

Basically, we have a FreeBSD running with various jails
corresponding more or less to group of services, who
may or may not be related.

# Solutions
## Global architecture
We try to automatize as much as we can. The idea is to
be able to redeploy "fastly" (ie. in a few hours versus
within months) the system.

We kept a FreeBSD system, isolating services/user through
jails following current needs. FreeBSD's support for
ZFS allows to easily have quotas/backup/other nice features.

## Service deployment
A service is configure through a single file, indicating
the type of the service, its IP port, various dependencies,
how to build and launch it.

All services are administered through a single
service-manager.py/supervisord.

## Knowledge
The technical knowledge (eg. port, IP address and stuff)
is usually kept in archived/versionned configuration files.

Non-technical knowledge (eg. what's the use for this
script/program, why is GOPATH local to each program instead
of system wide) is maintained in archived/versionned text files.

During further use of the system, one should usually kept
the new configuration files archived, and store in a wiki/using
IRC logs with easily greppable patterns related information
for further references.

# Further work
## Porting to other systems
Would be nice to experiment with docker/linux namespaces.
As they are still insecured at this date, we decided to
kept jails.

## Around HTTP
Most services use HTTP. Currently, we use a master nginx as
a proxies to services depending on their host name. Maybe it
would be nice to experiment with something simplier (eg.
9front's `hproxy.c`, which is dozen lines of C).

As a cosmetic touch, why not agree'd on common CSS policies
between services.

