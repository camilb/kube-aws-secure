# Secure Kubernets HA cluster in AWS using kube-aws

This repository contains an example of how to deploy a secure Kubernetes HA cluster in AWS using [kube-aws](https://github.com/kubernetes-incubator/kube-aws)

The fallowing setup use a base Cloudformation stack to configure Public and Private Subnets, IGW, NatGW, Route Tables and KMS. After the stack is created we'll deploy Kubernetes on top of it using `kube-aws`.

**Features:**

* all the nodes are deployed in private subnets
* 3 distinct availability zones
* 3 masters in HA, one per availability zone.
* workers configured using node pools, similar to [GKE node pools](https://cloud.google.com/container-engine/docs/node-pools)
* HA ETCD with encrypted partitions for data, automatic backups to S3 and automatic recovery from failover.
* role based authentication using the RBAC plugin
* users authentication using [OpenID Connect Identity](https://kubernetes.io/docs/admin/authentication/#openid-connect-tokens) (OIDC)
* AWS IAM roles directly assigned to pods using [kube2iam](https://github.com/jtblin/kube2iam)
* cluster autoscaling

![alt](https://www.camil.org/content/images/2017/05/kube-aws-secure.png)


### Deploy the Kubernetes cluster

1. Clone this repository locally

2. Create the base Cloudformation stack by customizing and running `./vpc/deploy.vpc.sh` script

3. Install [kube-aws](https://github.com/kubernetes-incubator/kube-aws); in this example I'm using`kube-aws` v0.9-7-rc.3

4. Get the output values from the Cloudformation base stack created and update the `./kube-aws/cluster.yaml`

        aws cloudformation describe-stacks --stack-name kube-aws-vpc | jq -r '.Stacks[].Outputs'



5. Render the stack and credentials. Go to `./kube-aws` directory and execute the fallowing command:

        kube-aws render credentials --generate-ca
        kube-aws render stack
Please read the `kube-aws` [documentation](https://github.com/kubernetes-incubator/kube-aws/blob/master/Documentation/kubernetes-on-aws-render.md) if you plan to use your own CA.

6. To launch the cluster, first you'll need a S3 bucket. Use an existing bucket or create a new one.

        kube-aws up --s3-uri s3://your-bucket-name

7. Access your Kubernetes cluster. Since we are creating all the resources in private networks, in order to access it, you'll need a VPN placed in one of the public subnets. I'm using [pritunl](https://docs.pritunl.com/docs/installation), which is very easy to configure. In approximately 5 minutes you can get it up and running on a `t2.nano`


*Optionally you can configure your `~/.kube/config`according to `kubeconfig` file to avoid passing the `--kubeconfig` flag on your commands.*

**Important**

*In order to expose public services using ELB or Ingress, the public subnets have to be tagged with the cluster name.*

*Ex. `KubeernetesCluser=cluster_name`*

### Add-ons

#### kube2iam
First we'll configure the `kube2iam`to allow some of our applications to assume AWS IAM Roles.

When RBAC is enabled `kube2iam`needs permissions to list pods and namespaces. We have to grant these permissions.

    kubectl create -f ./addons/kube2iam/rbac.yaml

 deploy the `kube2iam` DaemonSet

*change the accound ID to yours in` ./addons/kube2iam/k2i.ds.yaml`, then create the DaemonSet*

    kubectl create -f ./addons/kube2iam/k2i.ds.yaml

Now your pods can assume all the roles that have a trust relationship configured.

#### Route53

This add-on is based on [ExternalDNS](https://github.com/kubernetes-incubator/external-dns) project which allows you to control Route53 DNS records dynamically via Kubernetes resources.

Create a role named `k8s-route53`using this [policy](https://github.com/camilb/kube-aws-secure/blob/master/addons/route53/route53-policy.json). You also have to establish a trust relationship in order to allow the role to be assumed. An example is provided [here](https://github.com/camilb/kube-aws-secure/blob/master/addons/route53/route53-trust.json).

Now change the values in [external-dns.yaml](https://github.com/camilb/kube-aws-secure/blob/master/addons/route53/external-dns.yaml) and deploy it.

    kubectl create -f ./addons/route53/external-dns.yaml

#### Nginx Ingress Controller

I'm choosing nginx over traefik because of the Proxy Protocol support. This allows to use the nginx ingress controller in AWS behind an ELB configured with Proxy Protocol. This way the ingress external address will be always associated with your ELB. Also you don't have to expose your workers publicly and get better DDOS protection from your ELB.

    kubectl create -f ./addons/ingress/nginx/rbac.yaml
    kubectl create -f ./addons/ingress/nginx/nginx.yaml

#### kube-lego
Kube-Lego automatically requests certificates for Kubernetes Ingress resources from Let's Encrypt.

    kubectl create -f ./addons/kube-lego/rbac.yaml
    kubectl create -f ./addons/kube-lego/kube-lego.yaml



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

At this point you have a pretty secure, highly available, Kubernetes cluster in AWS.

For even better security please also consider using the [Pod Security Policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) and [Calico Network Policy](https://www.projectcalico.org/calico-network-policy-comes-to-kubernetes/)

#### Monitoring
A easy to setup, in-cluster, monitoring solution using Prometheus is available [here](https://github.com/camilb/prometheus-kubernetes)
