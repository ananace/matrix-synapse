Matrix Synapse
==============

To set up, you can use Docker to generate configuration and keys;

```
$ mkdir config tls keys
$ docker run --rm -it \
  -v `pwd`/config:/synapse/config \
  -v `pwd`/tls:/synapse/tls \
  -v `pwd`/keys:/synapse/keys \
  -e SERVER_NAME=hs.example \
     ananace/matrix-synapse:0.25.1 config
```

Generating TLS and signing keys separately can be done with;
```
$ docker run --rm -it \
  -v `pwd`/config:/synapse/config:ro \
  -v `pwd`/tls:/synapse/tls \
  -v `pwd`/keys:/synapse/keys \
  -e SERVER_NAME=hs.example \
     ananace/matrix-synapse:0.25.1 keys
```

This will create the folders of `config`, `tls`, and `keys`, for Configuration, TLS certificates, and 

It's recommended to also provide some backing store for /synapse/data/media to store retrieved media.


To run with workers, create worker configuration files and launch with - for instance;
```
$ docker run --rm -it \
  -v config:/synapse/config:ro \
  -v tls:/synapse/tls:ro \
  -v keys:/synapse/keys:ro \
     ananace/matrix-synapse:0.25.1 synapse.app.synchrotron \
     -c /synapse/config/synchrotron.worker
```

More information about workers can be found at; https://github.com/matrix-org/synapse/blob/master/docs/workers.md
