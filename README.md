# Calrissian session: a Helm template to create a calrissian kubernetes session

Calrissian is a CWL implementation designed to run inside a Kubernetes cluster. Its goal is to be highly efficient and scalable, taking advantage of high capacity clusters to run many steps in parallel.  

Calrissian requires a Kubernetes cluster, configured to provision PersistentVolumes with the `ReadWriteMany` access mode. 

This Helm chart deploys and configures:

- a ReadWriteMany `PersistentVolumeClaim`
- `configMap`s setting:
    - the access to an S3 bucket 
    - the access to container registries
- `Role`s to create pods and access pod logs
- `RoleBinding`s to associate the roles to the namespace default service account
- a `Deployment` with a pod that includes `calrissian` and typical development tools (the pod can be attached to a Visual Studio Code session)
- an optional `ServiceAccount` 
- a `Secret` to pull containers from container registries

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | node affinity |
| image | object | `{"pullPolicy":"Always","repository":"ghcr.io/terradue/calrissian-session/calrissian-session","tag":"latest"}` | Calrissian container image for running the Calrissian pod |
| imageCredentials | list | `[{"auth":"bXNhZ2....RVURt","registry":"ghcr.io"},{"auth":"ZmFi...mlRTldqZw==","https://index.docker.io/v1/":null}]` | container registries credentials |
| imageCredentials[0] | object | `{"auth":"bXNhZ2....RVURt","registry":"ghcr.io"}` | registry is the container registry |
| imageCredentials[0].auth | string | `"bXNhZ2....RVURt"` | auth is the base64 auth string (see your ~/.docker/config.json file) |
| nodeSelector | object | `{"k8s.scaleway.com/pool-name":"processing-node-pool-iride-xl"}` | specify the node selector for the Calrissian pod and the Calrissian worker pods |
| podAnnotations | object | `{}` | optional pod annotations |
| podSecurityContext | object | `{}` | additional settings for the pod security context |
| replicaCount | int | `1` | number of pods, one is usually enough |
| resources | object | `{"limits":{"cpu":"4","memory":"12Gi"},"requests":{"cpu":"4","memory":"8Gi"}}` | specify the resources for the Calrissian pod |
| s3 | object | `{"access_key_id":"SC...8Z","bucket_pattern":"s3:\\/\\/ir....tplace\\/.*","enabled":true,"endpoint_url":"https://s3.....cloud","region":"...","secret_access_key":"bf...dc6","signature_version":"s3v4"}` | use s3, if true, configMaps are mounted to access the S3 bucket |
| securityContext | object | `{"privileged":true}` | running with privileged set to true allows running podman in the Calrissian pod |
| serviceAccount | object | `{"annotations":{},"create":true,"name":"calrissian-sa"}` | Service account to use |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `"calrissian-sa"` | The name of the service account to use. |
| storageClass | string | `"openebs-kernel-nfs-scw"` | ReadWriteMany storage class for Calrissian worker  |
| tolerations | list | `[]` | tolerations |
| volumeSize | string | `"10Gi"` | size of the ReadWriteMany volume for Calrissian executions |

## Requirements

- a kubeconfig file to access a kubernetes cluster
- an environment variable named `KUBECONFIG` exporting that config file
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) and [helm](https://helm.sh/docs/intro/install/) installed

### Setting the KUBECONFIG environment variable

Example: 

```console
export KUBECONFIG=~/Downloads/kubeconfig.yaml
```

### A kubernetes namespace for the Calrissian session

Export an environment variable exporting the namespace for the Calrissian session, e.g.:

```console
export NAMESPACE_NAME=calrissian-session
```

Tip: You can create a namespace with:

```
kubectl create namespace "$NAMESPACE_NAME"
```

## Install or upgrade a calrissian session

Add the helm repo with:

```
helm repo add calrissian-session https://terradue.github.io/calrissian-session
helm repo update
```

Deploy the calrissian session with:

```
helm upgrade --install my-calrissian-session calrissian-session/calrissian-session --namespace "$NAMESPACE_NAME" --create-namespace \
    --set imageCredentials[0].registry=docker.terradue.com \
    --set imageCredentials[0].auth="aaa....bbbb" \
    --set s3.enabled=true \
    --set s3.access_key_id="cc..dd" \
    --set s3.secret_access_key="ee...ff" \
    --set s3.region=a_region \
    --set s3.endpoint_url=https://s3.somedomain.com \
    --set s3.signature_version=s3v4
```

Or create a `values.yaml` file and then:

```console
helm upgrade --install calrissian-session calrissian-session --namespace "$NAMESPACE_NAME" --values calrissian-session/values.yaml
```

## Access the calrissian session pod in Visual Studio Code

`~/.kube/config` must be a symbolic link to the `$KUBECONFIG` file to use the pod with a Visual Studio Code attached to:

```
rm -f ~/.kube/config
ln -s ~/Downloads/kubeconfig.yaml ~/.kube/config
```

**Visual Studio requirements** 

- [Kubernetes extension installed](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
- [Remote Development extension installed](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

**Attach the pod to a VS Code session**

Procedure:

1. Connect the kubernetes cluster to VS Code:
    - Open the Command Palette and use `Kubernetes: Set Kubeconfig`
    - Select `Add new Kubeconfig` to select a new kubeconfig file **OR** select a kubeconfig out of the list 
2. Click on the `Kubernetes` icon 
3. Navigate to the namespace `$NAMESPACE` (defined above) and right-click it and select "Use Namespace" (you might have to refresh the list of namespaces)
4. Expand "Workloads" and "Pods"
5. Right-click the pod named "calrissian-session-nnnn" where nnnn is an uid created by kubernetes and select "Attach Visual Studio Code". This will open a new VS Code window
6. Monitor the progress on the new Visual Studio Code window

Once ready, proceed with the next step.

**Clone Repository** 

Go to the "Explorer" and select "Clone Repository"

1. Clone the repo https://gitlab.com/app-packages/terradue/dnbr-sentinel-2-cog.git 
2. Select /home as the target repo
3. Open the cloned repository folder (bottom right question)

**Run a CWL Workflow** 

1. Open a new terminal
2. Run the application with: 

```console
calrissian --stdout /calrissian/results.json \
           --stderr  /calrissian/app.log \
           --max-ram 16G \
           --max-cores "8" \
           --tmp-outdir-prefix /calrissian/tmp \
           --outdir /calrissian/output \
           --usage-report /calrissian/usage.json \
           app-package.cwl#dnbr \
           params.yaml
```

The expected output is:

```
INFO calrissian 0.10.0 (cwltool 3.1.20211004060744)
INFO Resolved 'app-package.cwl#dnbr' to 'file:///home/app-package-04/dnbr-sentinel-2-cog/app-package.cwl#dnbr'
INFO [workflow ] starting step node_nbr
INFO [step node_nbr] start
INFO [workflow node_nbr] starting step node_stac_2
INFO [step node_stac_2] start
INFO [step node_stac_2] start
INFO [step node_stac_2] start
INFO [step node_nbr] start
INFO [workflow node_nbr_2] starting step node_stac_3
INFO [step node_stac_3] start
INFO [step node_stac_3] start
INFO [step node_stac_3] start
INFO [workflow ] start
INFO [workflow node_nbr] start
INFO [workflow node_nbr_2] start
INFO [step node_stac_3] completed success
INFO [workflow node_nbr_2] starting step node_subset_2
INFO [step node_subset_2] start
INFO [step node_subset_2] start
INFO [step node_stac_2] completed success
INFO [step node_subset_2] start
INFO [workflow node_nbr] starting step node_subset
INFO [step node_subset] start
INFO [step node_subset] start
INFO [step node_subset] start
INFO [step node_subset] completed success
INFO [workflow node_nbr] starting step node_nbr_2
INFO [step node_nbr_2] start
INFO [step node_subset_2] completed success
INFO [workflow node_nbr_2] starting step node_nbr_3
INFO [step node_nbr_3] start
INFO [step node_nbr_2] completed success
INFO [workflow node_nbr] starting step node_cog_2
INFO [step node_cog_2] start
INFO [step node_nbr_3] completed success
INFO [workflow node_nbr_2] starting step node_cog_3
INFO [step node_cog_3] start
INFO [step node_cog_2] completed success
INFO [workflow node_nbr] completed success
INFO [step node_cog_3] completed success
INFO [workflow node_nbr_2] completed success
INFO [step node_nbr] completed success
INFO [workflow ] starting step node_dnbr
INFO [step node_dnbr] start
INFO [step node_dnbr] completed success
INFO [workflow ] starting step node_cog
INFO [step node_cog] start
INFO [step node_cog] completed success
INFO [workflow ] starting step node_stac
INFO [step node_stac] start
INFO [step node_stac] completed success
INFO [workflow ] completed success
{
    "stac": {
        "location": "file:///calrissian-output/r30kfi8f",
        "basename": "r30kfi8f",
        "class": "Directory",
        "listing": [
            {
                "class": "File",
                "location": "file:///calrissian-output/r30kfi8f/catalog.json",
                "basename": "catalog.json",
                "checksum": "sha1$a5d1d9821e889aa125778e4f2e14a788ff1512ce",
                "size": 225,
                "path": "/calrissian-output/r30kfi8f/catalog.json"
            },
            {
                "class": "File",
                "location": "file:///calrissian-output/r30kfi8f/dnbr-item.json",
                "basename": "dnbr-item.json",
                "checksum": "sha1$1c0a635ad501c599ab258019d05c7b276515c565",
                "size": 818,
                "path": "/calrissian-output/r30kfi8f/dnbr-item.json"
            },
            {
                "class": "File",
                "location": "file:///calrissian-output/r30kfi8f/dnbr.tif",
                "basename": "dnbr.tif",
                "checksum": "sha1$df335a81cc67198654951d0a0fb98c5b89db67fe",
                "size": 1407480,
                "path": "/calrissian-output/r30kfi8f/dnbr.tif"
            }
        ],
        "path": "/calrissian-output/r30kfi8f"
    }
}
INFO Final process status is success
```

## Clean-up

### Uninstall a calrissian session

```console
export NAMESPACE_NAME=calrissian-session
helm uninstall my-calrissian-session --namespace "$NAMESPACE_NAME" 
```
