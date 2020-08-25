Matrix Synapse
==============

A Kubernetes-optimized Synapse image, some old example manifests can be found in the [kubernetes](kubernetes/) folder.

For a managed deployment, look at the charts available at;  
https://gitlab.com/ananace/charts - supports workers, handles the signing key as a secret, built upon the K8s ingress resource.  
https://github.com/dacruz21/matrix-chart/ - lacks workers, mounts a PVC for signing key, includes bridges and a mail relay, requires LoadBalancer support.

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
