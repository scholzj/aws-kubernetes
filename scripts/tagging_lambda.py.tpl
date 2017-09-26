#!/usr/bin/env python

import boto3
import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
log_handler = logging.StreamHandler()
log_handler.setLevel(logging.INFO)
log_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
log_handler.setFormatter(log_formatter)
LOGGER.addHandler(log_handler)

# Tagging configuration generated on ${timestamp}
region = "${aws_region}"
cluster = "${cluster_name}"
setTags = ${tags}

if 'Name' not in setTags.keys():
    setTags['Name'] = "${cluster_name}-resource"

# Tag the resources ...
def lambda_handler(event, context):
    kubeClusterTagKey = 'kubernetes.io/cluster/' + cluster
    kubeClusterTagValue = 'owned'
    filter = [{'Name':'tag:' + kubeClusterTagKey, 'Values':[kubeClusterTagValue]}]

    ec2 = boto3.resource('ec2', region_name=region)

    instances = ec2.instances.filter(Filters=filter)
    for instance in instances:
        newTags = prepare_new_tags(instance.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to instance %s", instance.id)
            instance.create_tags(Tags=newTags)

        for volume in instance.volumes.all():
            newTags = prepare_new_tags(volume.tags)
            if len(newTags) > 0:
                LOGGER.info("Adding tags to attached volume %s", volume.id)
                volume.create_tags(Tags=newTags)

        for eniref in instance.network_interfaces:
            eni = ec2.NetworkInterface(eniref.id)
            newTags = prepare_new_tags(eni.tag_set)
            if len(newTags) > 0:
                LOGGER.info("Adding tags to network interface %s", eni.id)
                eni.create_tags(Tags=newTags)

    volumes = ec2.volumes.filter(Filters=filter)
    for volume in volumes:
        newTags = prepare_new_tags(volume.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to volume %s", volume.id)
            volume.create_tags(Tags=newTags)

    sec_groups = ec2.security_groups.filter(Filters=filter)
    for sg in sec_groups:
        newTags = prepare_new_tags(sg.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to security group %s", sg.id)
            sg.create_tags(Tags=newTags)

    internet_gateways = ec2.internet_gateways.filter(Filters=filter)
    for igw in internet_gateways:
        newTags = prepare_new_tags(igw.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to internet gateways %s", igw.id)
            igw.create_tags(Tags=newTags)

    # DHCP Options
    dhcp_options_sets = ec2.dhcp_options_sets.filter(Filters=filter)
    for dhcp in dhcp_options_sets:
        newTags = prepare_new_tags(dhcp.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to DHCP Options %s", dhcp.id)
            dhcp.create_tags(Tags=newTags)

    # Subnets
    subnets = ec2.subnets.filter(Filters=filter)
    for subnet in subnets:
        newTags = prepare_new_tags(subnet.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to subnet %s", subnet.id)
            subnet.create_tags(Tags=newTags)

    # Network Interfaces
    network_interfaces = ec2.network_interfaces.filter(Filters=filter)
    for eni in network_interfaces:
        newTags = prepare_new_tags(eni.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to network interface %s", eni.id)
            eni.create_tags(Tags=newTags)

    # Route tables
    route_tables = ec2.route_tables.filter(Filters=filter)
    for rtg in route_tables:
        newTags = prepare_new_tags(rtg.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to routing table %s", rtg.id)
            rtg.create_tags(Tags=newTags)

    # VPC
    # Current setup is VPC == Cluster. Therefore we can tag things through VPC. With shared VPC, which should be avoided.
    # The untagged things under the VPC should be anyway related to VPC and not Kubernetes cluster. So if they are only
    # here, they are not ours in shared VPC
    vpcs = ec2.vpcs.filter(Filters=filter)
    for vpc in vpcs:
        newTags = prepare_new_tags(vpc.tags)
        if len(newTags) > 0:
            LOGGER.info("Adding tags to VPC %s", vpc.id)
            vpc.create_tags(Tags=newTags)

        # Network ACLs
        for acl in vpc.network_acls.all():
            newTags = prepare_new_tags(acl.tags)
            if len(newTags) > 0:
                LOGGER.info("Adding tags to network ACL %s", acl.id)
                acl.create_tags(Tags=newTags)

        # Route tables
        for rtg in vpc.route_tables.all():
            newTags = prepare_new_tags(rtg.tags)
            if len(newTags) > 0:
                LOGGER.info("Adding tags to routing tables %s", rtg.id)
                rtg.create_tags(Tags=newTags)

        # Security Groups
        for sg in vpc.security_groups.all():
            newTags = prepare_new_tags(sg.tags)
            if len(newTags) > 0:
                LOGGER.info("Adding tags to security group %s", sg.id)
                sg.create_tags(Tags=newTags)

    # Autoscaling groups
    autoscaling = boto3.client('autoscaling', region_name=region)
    asgs = autoscaling.describe_auto_scaling_groups(MaxRecords=100)
    for asg in asgs['AutoScalingGroups']:
        for tag in asg['Tags']:
            if tag['Key'] == kubeClusterTagKey and tag['Value'] == kubeClusterTagValue:
                newTags = prepare_new_tags(asg['Tags'])

                if len(newTags) > 0:
                    for nt in newTags:
                        nt['ResourceId'] = tag['ResourceId']
                        nt['ResourceType'] = tag['ResourceType']
                        nt['PropagateAtLaunch'] = True

                    LOGGER.info("Adding tags to autoscaling group %s", tag['ResourceId'])
                    autoscaling.create_or_update_tags(Tags=newTags)
                continue

    loadbalancing = boto3.client('elb', region_name=region)
    elbs = loadbalancing.describe_load_balancers(PageSize=400)
    for elb in elbs['LoadBalancerDescriptions']:
        tags = loadbalancing.describe_tags(LoadBalancerNames=[elb['LoadBalancerName']])
        for tag in tags['TagDescriptions'][0]['Tags']:
            if tag['Key'] == kubeClusterTagKey and tag['Value'] == kubeClusterTagValue:
                newTags = prepare_new_tags(tags['TagDescriptions'][0]['Tags'])
                if len(newTags) > 0:
                    LOGGER.info("Adding tags to load balancer %s", elb['LoadBalancerName'])
                    loadbalancing.add_tags(LoadBalancerNames=[elb['LoadBalancerName']], Tags=newTags)
                continue

# Check the existing tags and prepare a list with new tags
def prepare_new_tags(tags):
    newTags = []

    for key, value in setTags.iteritems():
        if key == 'Name':
            if find_tag(tags, key) == None:
                newTags.append({'Key': key, 'Value': value})
        elif find_tag(tags, key) != value:
            newTags.append({'Key': key, 'Value': value})

    return newTags

# Find and return individual tag
def find_tag(tags, key):
    if tags != None:
        for t in tags:
            if t['Key'] == key:
                return t['Value']

    return None

if __name__ == "__main__":
    lambda_handler(None, None)