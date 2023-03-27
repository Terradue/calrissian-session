# Calrissian session: a Helm template to create a calrissian kubernetes session

Calrissian is a CWL implementation designed to run inside a Kubernetes cluster. Its goal is to be highly efficient and scalable, taking advantage of high capacity clusters to run many steps in parallel.  

Calrissian requires a Kubernetes, configured to provision PersistentVolumes with the ReadWriteMany access mode. Kubernetes installers and cloud providers don't usually include this type of storage, so this Helm chart provides a deployment using Longhorn.

This Helm chart deploys and configures:

- three ReadWriteMany `PersistentVolumeClaim`s
- `configMap`s setting:
    - the access to an S3 bucket 
    - the access to container registries
- `Role`s to create pods and access pod logs
- `RoleBinding`s to associate the roles to the namespace default service account
- a `Deployment` with a pod that can be attached to a Visual Studio Code session
- an optional `ServiceAccount` 
- a `Secret` to pull containers from private registries

## Requirements

- a kubeconfig file to access a kubernetes cluster
- an environment variable exporting that config file
- longhorn installed on the cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) and [helm](https://helm.sh/docs/intro/install/) installed

### Setting the KUBECONFIG environment variable

Example: 

```console
export KUBECONFIG=~/Downloads/kubeconfig-k8s-bold-nightingale.yaml
```

### Longhorn (if not installed on the cluster)

To verify if longhorn is installed, list the pod in the `longhorn-system` namespace: 

```
kubectl -n longhorn-system get pod
```

If you get `No resources found in longhorn-system namespace.` follow the steps below to install longhorn.

Add and update the longhorn Helm chart with:

```
helm repo add longhorn https://charts.longhorn.io
helm repo update
```

Install longhorn with:

```
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --set longhorn.persistence.defaultClassReplicaCount=1
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

Or update the `values.yaml` file and then:

```console
helm upgrade --install calrissian-session calrissian-session --namespace "$NAMESPACE_NAME" --values calrissian-session/values.yaml
```

## Access the calrissian session pod in Visual Studio Code

`~/.kube/config` must be a symbolic link to the `$KUBECONFIG` file to use the pod with a Visual Studio Code attached to:

```
rm -f ~/.kube/config
ln -s ~/Downloads/kubeconfig-k8s-bold-nightingale.yaml ~/.kube/config
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
calrissian --stdout /calrissian-output/results.json \
           --stderr  /calrissian-output/app.log \
           --max-ram 16G \
           --max-cores "8" \
           --tmp-outdir-prefix /calrissian-tmp/ \
           --outdir /calrissian-output/ \
           --usage-report /calrissian-output/usage.json \
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

### Uninstall longhorn:

To uninstall longhorn do:

```
helm uninstall longhorn -n longhorn-system
```

