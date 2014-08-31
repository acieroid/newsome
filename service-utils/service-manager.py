#!/usr/local/bin/python2.7
# TODO: static services only need upate and update-desc
import itertools
import os
import select
import signal
import subprocess
import sys

MAIN_PIPE = '/root/services.pipe'
STATE_FILE = '/root/services.state'
SERVICES = []
OPEN_FLAGS = os.O_RDONLY | os.O_NONBLOCK
KEVENT_FILTER = select.KQ_FILTER_READ
KEVENT_FLAGS = select.KQ_EV_ADD | select.KQ_EV_ENABLE
PIPE_PATH = '/usr/jails/{0}/home/{1}/service.pipe'

def signal_term_handler(signal, frame):
    if os.path.exists(MAIN_PIPE):
        os.remove(MAIN_PIPE)
    sys.exit(0)

def save_state(services):
    with open(STATE_FILE, 'w') as f:
        # "The name is intended to match readlines(); writelines() does not add
        # line separators" WHY, PYTHON, WHY?
        f.writelines(['{0} {1}\n'.format(jail, name)
                      for (jail, name) in services])

def load_state():
    services = {}
    inv_services = {}
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, 'r') as f:
            for line in f:
                splitted = line.rstrip().split(' ')
                if len(splitted) != 2:
                    print('Ignoring malformed line in {0}: {1}'.format(STATE_FILE, line))
                jail, name = splitted
                fname = PIPE_PATH.format(jail, name)
                kev = select.kevent(os.open(fname, OPEN_FLAGS),
                                    filter=KEVENT_FILTER,
                                    flags=KEVENT_FLAGS)
                services[(jail, name)] = kev
                inv_services[kev.ident] = (jail, name)
        print('Restored previous state with {0} services'.format(len(services)))
    return (services, inv_services)

def service_exists(jail, name):
    return os.path.exists(PIPE_PATH.format(jail, name))

def start_service(service):
    jail, name = service
    print('Starting {0}'.format(name))
    subprocess.call(["/usr/local/bin/supervisorctl", "start", name])

def stop_service(service):
    jail, name = service
    print('Stopping {0}'.format(name))
    subprocess.call(["/usr/local/bin/supervisorctl", "stop", name])

def restart_service(service):
    jail, name = service
    print('Restarting {0}'.format(name))
    subprocess.call(["/usr/local/bin/supervisorctl", "restart", name])

def update_service(service):
    jail, name = service
    print('Updating {0}'.format(name))
    subprocess.call(["/usr/sbin/jexec",
                     "-U", name, jail, "service-jail-action.sh",
                     "/home/{0}/{0}.sh".format(name), "update"])

def update_service_desc(service):
    print('update_service_desc: NYI')

def run():
    main_fd = os.open(MAIN_PIPE, OPEN_FLAGS)
    kqueue = select.kqueue()
    main_kevent = select.kevent(main_fd, filter=KEVENT_FILTER,
                                flags=KEVENT_FLAGS)
    services, inv_services = load_state()
    while True:
        save_state(services.keys())
        sys.stdout.flush() # without flushing, can't see the logs @supervisord
        evs = kqueue.control([main_kevent] + services.values(), 1, None)
        for ev in evs:
            fd, nbytes = ev.ident, ev.data
            # TODO: is it safe to assume that we will get only one command, and
            # one full command at each read?
            data = os.read(fd, nbytes).rstrip().split(' ')
            if fd == main_fd:
                # we have to close the fd and open it again (else we
                # indefinitely get read events of 0 bytes)
                os.close(main_fd)
                main_fd = os.open(MAIN_PIPE, OPEN_FLAGS)
                main_kevent = select.kevent(main_fd, filter=KEVENT_FILTER,
                                            flags=KEVENT_FLAGS)
                if len(data) < 1:
                    print('Empty command received on main pipe: {0}'.format(data))
                    continue
                cmd = data[0]
                if cmd == 'add':
                    if len(data) != 3:
                        print('Wrong number of arguments for add: {0}'.format(data))
                        continue
                    cmd, jail, name = data
                    if (jail, name) in services:
                        print('Ignoring addition of an already registered service: {0} on jail {1}'.format(name, jail))
                        continue
                    if not service_exists(jail, name):
                        print('Cannot add non-existent service: {0} on jail {1}'.format(name, jail))
                        continue
                    print('Add service {0} on jail {1}'.format(name, jail))
                    fname = PIPE_PATH.format(jail, name)
                    kev = select.kevent(os.open(fname, OPEN_FLAGS),
                                        filter=KEVENT_FILTER,
                                        flags=KEVENT_FLAGS)
                    services[(jail, name)] = kev
                    inv_services[kev.ident] = (jail, name)
                elif cmd == 'remove':
                    if len(data) != 3:
                        print('Wrong number of arguments for remove: {0}'.format(data))
                        continue
                    cmd, jail, name = data
                    if not (jail, name) in services:
                        print('Cannot remove a non-existent service: {0} on jail {1}'.format(name, jail))
                        continue
                    print('Remove service {0} from jail {1}'.format(name, jail))
                    kev = services[(jail, name)]
                    os.close(kev.ident)
                    del services[(jail, name)]
                elif cmd == 'list':
                    if len(data) != 1:
                        print('Wrong number of arguments for list: {0}'.format(data))
                        continue
                    fst = lambda (x, y): x
                    snd = lambda (x, y): y
                    l = [(j, map(snd, list(s)))
                         for (j, s) in itertools.groupby(services.keys(), key=fst)]
                    print('List of services:')
                    for (jail, servs) in l:
                        print('Jail {0}: {1}'.format(jail, ', '.join(servs)))
                    print('End of list of services.')
                else:
                    print('Unknown command on main pipe: {0}'.format(cmd))
            else:
                service = inv_services[ev.ident]
                jail, name = service
                os.close(fd)
                fname = PIPE_PATH.format(jail, name)
                kev = select.kevent(os.open(fname, OPEN_FLAGS),
                                    filter=KEVENT_FILTER,
                                    flags=KEVENT_FLAGS)
                services[(jail, name)] = kev
                del inv_services[ev.ident]
                inv_services[kev.ident] = (jail, name)
                if len(data) != 1:
                    print('Incorrect number of arguments received on pipe {0}: {1}'.format(fname, data))
                    continue
                cmd = data[0]
                if cmd == 'start':
                    start_service(service)
                elif cmd == 'stop':
                    stop_service(service)
                elif cmd == 'restart':
                    restart_service(service)
                elif cmd == 'update':
                    update_service(service)
                elif cmd == 'update-desc':
                    update_service_desc(service)

if __name__ == '__main__':
    signal.signal(signal.SIGTERM, signal_term_handler)
    if os.path.exists(MAIN_PIPE):
        print('{0} already exists, please be sure that service-manager.py is not already running, and remove this file'.format(MAIN_PIPE))
        sys.exit(1)
    try:
        os.mkfifo(MAIN_PIPE)
        run()
    finally:
        os.remove(MAIN_PIPE)
