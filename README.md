Matrix Synapse
==============

To set up, you can use Docker to generate configuration and keys;

```
$ docker run -rm -it -v config:/synapse/config -v tls:/synapse/tls -v keys:/synapse/keys ananace/matrix-synapse:0.25.1 config
$ docker run -rm -it -v config:/synapse/config -v tls:/synapse/tls -v keys:/synapse/keys ananace/matrix-synapse:0.25.1 keys
```

It's recommended to also provide some backing for /synapse/data/media to store retrieved media.


To run with workers, create worker configuration files and launch with;
```
$ docker run --rm -it -v config:/synapse/config:ro -v tls:/synapse/tls:ro -v keys:/synapse/keys:ro ananace/matrix-synapse:0.25.1 synapse.app.synchrotron -c /synapse/config/synchrotron.worker
```
