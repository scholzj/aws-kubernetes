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

## Prerequisites and dependencies

* To deploy AWS Kubernetes there are no other dependencies apart from [Terraform](https://www.terraform.io). The current setup with IAM roles integrated **needs at least Terraform 0.10.0**. Kubeadm is used only on the EC2 hosts and doesn't have to be installed locally.

## Configuration

The configuration is done through Terraform variables. Example *tfvars* file is part of this repo and is named `example.tfvars`. Change the variables to match your environment / requirements before running `terraform apply ...`.

| Option | Explanation | Example |
|--------|-------------|---------|
| `aws_region` | AWS region which should be used | `eu-central-1` |
| `cluster_name` | Name of the Kubernetes cluster (also used to name different AWS resources) | `my-aws-kubernetes` |
| `master_instance_type` | AWS EC2 instance type for master | `t2.medium` |
| `worker_instance_type` | AWS EC2 instance type for worker | `t2.medium` |
| `ssh_public_key` | SSH key to connect to the remote machine | `~/.ssh/id_rsa.pub` |
| `master_subnet_id` | Subnet ID where master should run | `subnet-8d3407e5` |
| `worker_subnet_ids` | List of subnet IDs where workers should run | `[ "subnet-8d3407e5" ]` |
| `min_worker_count` | Minimal number of worker nodes | `3` |
| `max_worker_count` | Maximal number of worker nodes | `6` |
| `hosted_zone` | DNS zone which should be used | `my-domain.com` |
| `hosted_zone_private` | Is the DNS zone public or private | `false` |
| `addons` | List of addons YAML files which should be installed. These files have to be placed into `scripts/addons` directory | `[ "<your-addon-name>.yaml" ]` |
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
* Destroy Terraform configuration:
```bash
terraform destroy --var-file example.tfvars
```

## Addons

Currently, following addons are supported:
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
 1) The addon YAML file has to be placed into `scripts/addons` directory.
 1) In the `scripts-2-s3.tf`:
    - a new `aws_s3_bucket_object` resource entry has to be added:
    ```hcl-terraform
    resource "aws_s3_bucket_object" "<your-addon-name>" {
        bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
        key    = "addons/<your-addon-name>.yaml"
        source = "scripts/addons/<your-addon-name>.yaml"
        etag   = "${md5(file("scripts/addons/<your-addon-name>.yaml"))}"
        acl    = "public-read"
    }
    ```
    - the entry has to be added to the list of `depends_on` in the `init-aws-kubernetes-master` resource.
 1) Add the file name into `addons` variable. 

For every file in the `addons` list, the initialization scripts will automatically call `kubectl -f apply <Addon file>` to deploy it. The cluster is using RBAC. So the custom addons have to be *RBAC ready*.

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