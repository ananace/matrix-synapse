Matrix Synapse
==============

To set up, you can use Docker to generate configuration and keys;

```
$ docker run -rm -it -v config:/synapse/config -v tls:/synapse/tls -v keys:/synapse/keys ananace/matrix-synapse:0.25.1 config
$ docker run -rm -it -v config:/synapse/config -v tls:/synapse/tls -v keys:/synapse/keys ananace/matrix-synapse:0.25.1 keys
```

It's recommended to also provide some backing for /synapse/data/media to store retrieved media.
