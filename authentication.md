##[Work in progress]

#### OIDC

#### Kubernetes Dashboard

#### Dex
Dex runs natively on top of any Kubernetes cluster using Third Party Resources and can drive API server authentication through the OpenID Connect plugin.

By default you have administrator rights using the TLS certificates. If you plan to grant restricted permissions to other users, Dex can facilitate users access using OpenID Connect Tokens.

In this example we use the [Github provider](https://github.com/coreos/dex/blob/master/Documentation/github-connector.md) to identify the users.

Please configure the`./addons/dex/elb/internal-elb.yaml` file then expose the service.

    kubectl create -f ./addons/dex/elb/internal-elb.yaml

The DNS is configured automatically by `ExternalDNS` add-on and should be available in  approximately 1 minute.

You can now use a client like dex's [example-app](https://github.com/coreos/dex/tree/master/cmd/example-app) to obtain a authentication token.

If you prefer, you can use this app as a always running service by configuring and deploying `./addons/kid/kid.yaml`

    kubectl create secret \
    generic kid \
    --from-literal=CLIENT_ID=your-client-id \
    --from-literal=CLIENT_SECRET=your-client-secret \
    -n kube-system    

    kubectl create -f ./addons/kid/kid.yaml

Please check the dex [documentation](https://github.com/coreos/dex/tree/master/Documentation) if you need more informations.

Make a quick test by granting a user permissions to list the pods in `kube-system` namespace.

    kubectl create -f `./examples/rbac/pod-reader.yaml`
    kubectl create rolebinding pod-reader --role=pod-reader --user=user@example.com --namespace=kube-system


Example of `~/.kube/config` for a user

    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority-data: ca.pem_base64_encoded
        server: https://kubeapi.example.com
      name: your_cluster_name
    contexts:
    - context:
        cluster: your_cluster_name
        user: user@example.com
      name: your_cluster_name
    current-context: your_cluster_name
    kind: Config
    preferences: {}
    users:
    - name: user@example.com
      user:
        auth-provider:
          config:
            access-token: id_token
            client-id: client_id
            client-secret: client_secret
            extra-scopes: groups
            id-token: id_token
            idp-issuer-url: https://dex.example.com
            refresh-token: refresh_token
          name: oidc

If you already have the `~/.kube/config` set, you can use this example to configure the user authentication

    kubectl config set-credentials user@example.com \
      --auth-provider=oidc \
      --auth-provider-arg=idp-issuer-url=https://dex.example.com \
      --auth-provider-arg=client-id=your_client_id \
      --auth-provider-arg=client-secret=your_client_secret \
      --auth-provider-arg=refresh-token=your_refresh_token \
      --auth-provider-arg=id-token=your_id_token \
      --auth-provider-arg=extra-scopes=groups

Once your `id_token` expires, `kubectl` will attempt to refresh your `id_token` using your `refresh_token` and `client_secret` storing the new values for the `refresh_token` and `id_token` in your `~/.kube/config`
