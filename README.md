Matrix Synapse
==============

A Kubernetes-optimized Synapse image, example manifests can be found in the [kubernetes](kubernetes/) folder.

&nbsp;

To run with workers, create worker configuration files and launch with - for instance;
```
$ docker run --rm -it \
  -v config:/synapse/config:ro \
  -v tls:/synapse/tls:ro \
  -v keys:/synapse/keys:ro \
     ananace/matrix-synapse:latest \
     synapse.app.synchrotron \
     -c /synapse/config/synchrotron.worker
```

More information about workers can be found at; https://github.com/matrix-org/synapse/blob/master/docs/workers.md
