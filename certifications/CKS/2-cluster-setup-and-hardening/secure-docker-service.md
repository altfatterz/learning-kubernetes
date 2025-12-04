# Docker Service Configuration

```bash
# run as a daemon
$ systemctl start docker
$ systemctl stop docker
$ systemctl status docker

# for ground process
$ dockerd
$ dockerd --debug

# unix socket - set by default
# Docker CLI only able to talk by default on the same host as the Docker daemon 
/var/run/docker.sock
```

- Secure the docker host with usual best practices
    - disable password based authentication
    - enable SSH key based authentication
    - determine users who need access to the server
    - disable root user, root sudo

```bash
# external docker cli can connect to this host
# make sure the ip is private 
$ dockerd --debug --host=tcp://192.168.1.10:2375

# don't do it on public facing host
# person with access can delete containers / run own containers / volumes etc /
# gain root access to the host system by running a privileged container - then later target other hosts on the network
$ export DOCKER_HOST="tcp://192.168.1.10:2375"
$ docker ps
```

- By default, the Docker daemon serves unencrypted traffic

```bash
# note the 2376 is the secure port
$ dockerd --debug --host=tcp://192.168.1.10:2376 --tls=true --tlscert=/var/docker/server.pem  --tlskey=/var/docker/serverkey.pem 
```

- Use configuration file instead:

```bash
# /etc/docker/daemon.json
{
  "debug": true,
  # note the port is 2376 is the secure port
  "hosts": ["tcp://192.168.1.10:2376"],
  "tls": true
  "tlscert": "/var/docker/server.pem"
  "tlskey": "/var/docker/serverkey.pem"
}
# no longer need to specify the parameters, take from the default /etc/docker/daemon.json file
$ dockerd

# this /etc/docker/daemon.json file is also run when running with systemctl
$ systemct start docker  

# connect with Docker CLI
$ export DOCKER_TLS=true
$ export DOCKER_HOST="tcp://192.168.1.10:2376"
$ docker ps
```

- Now there is secure communication but still no authentication, lets use certificate based authentication

```bash
# /etc/docker/daemon.json
# now only clients with client certificates signed from the cacert can access the docker daemon
{
  "debug": true,
  # note the port is 2376 is the secure port
  "hosts": ["tcp://192.168.1.10:2376"],
  "tls": true
  "tlscert": "/var/docker/server.pem"
  "tlskey": "/var/docker/serverkey.pem"
  # enabled authentication
  "tlsverify": true
  # verify the certificate of clients when they send them
  "tlscacert": "/var/docker/caserver.pem"
}

# only enables encryption 
$ export DOCKER_TLS=true
# enables authentication
$ export DOCKER_TLS_VERIFY=true
$ export DOCKER_HOST="tcp://192.168.1.10:2376"
# copy client.pem / clientkey.pem / cacert.pem to the client
$ docker --tlscert=<> --tlskey=<> --tlscacert=<>

```

Docker globacl config options:

```bash
      --config string      Location of client config files (default "/Users/altfatterz/.docker")
  -c, --context string     Name of the context to use to connect to the daemon (overrides DOCKER_HOST env var and default context set with "docker context use")
  -D, --debug              Enable debug mode
  -H, --host string        Daemon socket to connect to
  -l, --log-level string   Set the logging level ("debug", "info", "warn", "error", "fatal") (default "info")
      --tls                Use TLS; implied by --tlsverify
      --tlscacert string   Trust certs signed only by this CA (default "/Users/altfatterz/.docker/ca.pem")
      --tlscert string     Path to TLS certificate file (default "/Users/altfatterz/.docker/cert.pem")
      --tlskey string      Path to TLS key file (default "/Users/altfatterz/.docker/key.pem")
      --tlsverify          Use TLS and verify the remote
  -v, --version            Print version information and quit
```

Docker Docs: https://docs.docker.com/get-started/resources/

