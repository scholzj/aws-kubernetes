# AWS Kubernetes

AWS Kubernetes is a Kubernetes cluster deployed using [Kubeadm](https://kubernetes.io/docs/admin/kubeadm/) tool. It provides full integration with AWS. It is able to handle ELB load balancers, EBS disks, Route53 domains etc.

**This installation is taylored for Deutsche Boerse ProductDev AWS account.  It might not work in normal AWS account! For Sandbox and private accounts, use the repo on [GitHub](https://github.com/scholzj/aws-kubernetes)**

<!-- TOC -->

- [AWS Kubernetes](#aws-kubernetes)
    - [Prerequisites and dependencies](#prerequisites-and-dependencies)
    - [Configuration](#configuration)
        - [Using multiple / different subnets for workers nodes](#using-multiple--different-subnets-for-workers-nodes)
    - [Creating AWS Kubernetes cluster](#creating-aws-kubernetes-cluster)
    - [Deleting AWS Kubernetes cluster](#deleting-aws-kubernetes-cluster)
    - [Addons](#addons)
    - [Adding new addons](#adding-new-addons)
    - [Tagging](#tagging)

<!-- /TOC -->

## Updates

* *22.8.2017:* Update Kubernetes and Kubeadm to 1.7.4
* *30.8.2017:* New addon - Fluentd + ElasticSearch + Kibana
* *2.9.2017:* Update Kubernetes and Kubeadm to 1.7.5
* *18.9.2017:* Updated addons:
  - ingress -> 0.9.0-beta.13
  - heapster -> v1.4.2
  - external-dns -> v0.4.4
  - cluster-autoscaler -> v0.6.2
* *20.9.2017:* Addons installed as Helm charts
* *21.9.2017:* Replaced Calico by Weave.

## Prerequisites and dependencies

* To deploy AWS Kubernetes there are no other dependencies apart from [Terraform](https://www.terraform.io). The current setup with IAM roles integrated **needs at least Terraform 0.10.5**. Kubeadm is used only on the EC2 hosts and doesn't have to be installed locally.

## Configuration

The configuration is done through Terraform variables. Example *tfvars* file is part of this repo and is named `example.tfvars`. Change the variables to match your environment / requirements before running `terraform apply ...`.

| Option | Explanation | Example |
|--------|-------------|---------|
| `aws_region` | AWS region which should be used | `eu-central-1` |
| `cluster_name` | Name of the Kubernetes cluster (also used to name different AWS resources) | `my-aws-kubernetes` |
| `master_instance_type` | AWS EC2 instance type for master | `t2.medium` |
| `worker_instances` | AWS EC2 instance types for worker nodes. It is a list of objects with following format: `{ instance_type = "..." min_instance_count = ... max_instance_count = ... }`| `[ { instance_type = "t2.medium" min_instance_count = 3 max_instance_count = 6 } ]` |
| `ssh_public_key` | SSH key to connect to the remote machine | `~/.ssh/id_rsa.pub` |
| `master_subnet_id` | Subnet ID where master should run | `subnet-8d3407e5` |
| `worker_subnet_ids` | List of subnet IDs where workers should run | `[ "subnet-8d3407e5" ]` |
| `hosted_zone` | DNS zone which should be used | `my-domain.com` |
| `hosted_zone_private` | Is the DNS zone public or private | `false` |
| `addons` | List of addons (Helm) chart names. They have to be placed in `addons` directory | `[ "<your-addon-name>" ]` |
| `tags` | Tags which should be applied to all resources | see *example.tfvars* file |
| `tags2` | Tags in second format which should be applied to AS groups | see *example.tfvars* file |
| `ssh_access_cidr` | List of CIDRs from which SSH access is allowed | `[ "0.0.0.0/0" ]` |
| `api_access_cidr` | List of CIDRs from which API access is allowed | `[ "0.0.0.0/0" ]` |

### Using multiple / different subnets for workers nodes

In order to run workers in additional / different subnet(s) than master you have to tag the subnets with `kubernetes.io/cluster/{cluster_name}=shared`. For example `kubernetes.io/cluster/my-aws-kubernetes=shared`. During the cluster setup, the bootstrapping script will automatically add these tags to the subnets specified in `worker_subnet_ids`.

## Creating AWS Kubernetes cluster

To create AWS Kubernetes cluster, 
* Export AWS credentials into environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
* Initialize Terraform:
```bash
terraform init
```
* Apply Terraform configuration:
```bash
terraform apply --var-file example.tfvars
```

## Deleting AWS Kubernetes cluster

To delete AWS Kubernetes cluster, 
* Export AWS credentials into environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
* Uninstall all Kubernetes addons (they were installed as Helm packages)
```
helm delete $(helm ls -aq) --purge
```
* Destroy Terraform configuration:
```bash
terraform destroy --var-file example.tfvars
```

## Addons

Currently, following addons are supported as Helm packages:
* Kubernetes dashboard
* Heapster for resource monitoring
* Storage class for automatic provisioning of persisitent volumes
* External DNS (Replaces Route53 mapper)
* Ingress
* Autoscaler
* Logging with Fluentd + ElasticSearch + Kibana

The addons will be installed automatically based on the Terraform variables. 

## Adding new addons

Custom addons can be added if needed:
 1) Place the addon Helm chart into `addons` directory.
 1) Add the directory name into `addons` variable. 

For every chart in the `addons` list, the initialization script will automatically call `helm install <chart name> -f <chart name>/default-values.yaml`. The cluster is using RBAC. So the custom addons have to be *RBAC ready*.

# Kubernetes Tagging Lambda

When you operate Kubernetes cluster, you will sooner or later create some additional resources like volumes or load balancers. These resources should be tagged with product, cost center etc. This repository contains installation of AWS Lambda function which will go through all your resources, identify them based on tag `KubernetesCluster` tag which should contain the name of your Kubernetes cluster. For every resource it find it will make sure that the required tags are attached.

## Tagged resources

* EC2 instances
* Network interfaces
* EBS Volumes
* Security Groups
* Internet Gateways (*not applicable in ProductDev*)
* DHCP Option sets (*not applicable in ProductDev*)
* Subnets (*not applicable in ProductDev*)
* Route tables (*not applicable in ProductDev*)
* VPCs (*not applicable in ProductDev*)
* Network ACLs (*not applicable in ProductDev*)
* Autoscaling Groups
* Elastic Loadbalancers