# Secure Kubernets HA cluster in AWS using kube-aws

This repository contains an example of how to deploy a secure Kubernetes HA cluster in AWS using [kube-aws](https://github.com/kubernetes-incubator/kube-aws) automatically.

The fallowing setup use a base CloudFormation stack to configure Public and Private Subnets, IGW, NatGW, Route Tables, KMS and deploys automatically a VPN server in a public subnet. After the stack is created, the Kubernetes cluster is automatically deployed on top of it using `kube-aws`.

[![asciicast](https://asciinema.org/a/145270.png)](https://asciinema.org/a/145270)

**Features:**

* simple and interactive deployment
* all the nodes are deployed in private subnets
* 3 distinct availability zones
* multi AZ masters
* workers configured using node pools, similar to [GKE node pools](https://cloud.google.com/container-engine/docs/node-pools)
* HA ETCD with encrypted partitions for data, automatic backups to S3 and automatic/manual recovery from failover
* role based authentication using the RBAC plugin
* users authentication using [OpenID Connect Identity](https://kubernetes.io/docs/admin/authentication/#openid-connect-tokens) (OIDC)
* AWS IAM roles directly assigned to pods using [kube2iam](https://github.com/jtblin/kube2iam)
* cluster autoscaling
* VPN server automatically deployed to a public subnet

![alt](https://www.camil.org/content/images/2017/05/kube-aws-secure.png)


### Deploy the Kubernetes cluster

1. Clone this repository locally

2. run `./deploy` and fallow the instructions

3. Access your Kubernetes cluster. Since  all the resources are in private networks, in order to access it, you'll need a VPN placed in one of the public subnets.[Pritunl](https://docs.pritunl.com/docs/installation) is now automatically deployed to a public subnet with a Elastic IP and DNS reccord.


*Optionally you can configure your `~/.kube/config`according to `kubeconfig` file to avoid passing the `--kubeconfig` flag on your commands.*

**Important**

*In order to expose public services using ELB or Ingress, the public subnets have to be tagged with the cluster name.*

*Ex. `KubeernetesCluser=cluster_name`*

*This is now set automatically*


### Add-ons


*Note: all the addons can now be deployed automatically using addons/deploy script*
#### Route53

This add-on is based on [ExternalDNS](https://github.com/kubernetes-incubator/external-dns) project which allows you to control Route53 DNS records dynamically via Kubernetes resources.

*Note: before deploying this addon, you have to create a IAM role and setup a trust relationship*

#### Nginx Ingress Controller

[Nginx ingress controller](https://github.com/kubernetes/ingress-nginx) is deployed behind a ELB configured with Proxy Protocol. This way the ingress external address will be always associated with your ELB. Also you don't have to expose your workers publicly and get better protection from your ELB.

#### kube-lego
[Kube-Lego](https://github.com/jetstack/kube-lego) automatically requests certificates for Kubernetes Ingress resources from Let's Encrypt.

#### Monitoring
A easy to setup, in-cluster, monitoring solution using Prometheus is available [here](https://github.com/camilb/prometheus-kubernetes)
