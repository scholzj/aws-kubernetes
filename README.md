# Kubernetes Tagging Lambda

When you operate Kubernetes cluster, you will sooner or later create some additional resources like volumes or load balancers. These resources should be tagged with product, cost center etc. This repository contains installation of AWS Lambda function which will go through all your resources, identify them based on tag `KubernetesCluster` tag which should contain the name of your Kubernetes cluster. For every resource it find it will make sure that the required tags are attached.

**This installation is taylored for Deutsche Boerse ProductDev AWS account. It might not work in normal AWS account!**

<!-- TOC -->

- [Kubernetes Tagging Lambda](#kubernetes-tagging-lambda)
    - [Prerequisites and dependencies](#prerequisites-and-dependencies)
    - [Configuration](#configuration)
    - [Deploying tagging lambda](#deploying-tagging-lambda)
    - [Deleting tagging lambda](#deleting-tagging-lambda)
    - [Tagged resources](#tagged-resources)

<!-- /TOC -->

## Prerequisites and dependencies

* The Lambda deployment is written using [Terraform](https://www.terraform.io). The current setup with IAM roles integrated **needs at least Terraform 0.10.0**.
* Generating of the lambda function from the template and packing it into ZIP archive expects `bash` and `zip` being available.
* This deployment might not work on Windows machine. Tested only on Linux and macOS

## Configuration

The configuration is done through Terraform variables. Example *tfvars* file is part of this repo and is named `example.tfvars`. Change the variables to match your environment / requirements before running `terraform apply ...`.

| Option | Explanation | Example |
|--------|-------------|---------|
| `aws_region` | AWS region which should be used | `eu-central-1` |
| `cluster_name` | Name of the Kubernetes cluster (used to find the resources for tagging but also to name resources created by this configuration) | `my-minikube` |
| `tags` | Tags which should be applied to all resources | `{ Hello = "World" }` |

## Deploying tagging lambda

To deploy the tagging lambda, 
* Export AWS credentials into environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
* Initialize Terraform:
```bash
terraform init
```
* Apply Terraform configuration with tagging lambda:
```bash
terraform apply --var-file example.tfvars
```

## Deleting tagging lambda

To delete tagging lambda, 
* Export AWS credentials into environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
* Destroy Terraform configuration:
```bash
terraform destroy --var-file example.tfvars
```

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