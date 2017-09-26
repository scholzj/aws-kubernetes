#!/bin/bash

set -o verbose
set -o errexit
set -o pipefail

if [ -z "$KUBERNETES_VERSION" ]; then
  KUBERNETES_VERSION="1.7.5"
fi

export CLUSTER_NAME="${cluster_name}"

if [ -z "$CLUSTER_NAME" ]; then
  CLUSTER_NAME="aws-kubernetes"
fi

export AWS_SUBNETS="${aws_subnets}"

if [ -z "$AWS_SUBNETS" ]; then
  AWS_SUBNETS="$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl http://169.254.169.254/latest/meta-data/mac)/subnet-id)"
fi

# Set this only after setting the defaults
set -o nounset

# Set fully qualified hostname
# This is needed to match the hostname expected by kubeadm and the hostname used by kubelet
hostname $(curl -s http://169.254.169.254/latest/meta-data/hostname)

# Make DNS lowercase
export DNS_NAME=$(echo "${dns_name}" | tr 'A-Z' 'a-z')

# Install AWS CLI client
yum install -y epel-release
yum install -y awscli

# Tag subnets
for SUBNET in $AWS_SUBNETS
do
  aws ec2 create-tags --resources $${SUBNET} --tags Key=kubernetes.io/cluster/$${CLUSTER_NAME},Value=shared --region ${aws_region}
done

# Install docker
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum makecache fast
yum install -y docker-ce

# Install Kubernetes components
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kubelet-$${KUBERNETES_VERSION} kubeadm-$${KUBERNETES_VERSION} kubernetes-cni

# Fix kubelet configuration
sed -i 's/--cgroup-driver=systemd/--cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sed -i '/Environment="KUBELET_CGROUP_ARGS/i Environment="KUBELET_CLOUD_ARGS=--cloud-provider=aws"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sed -i 's/$KUBELET_CGROUP_ARGS/$KUBELET_CLOUD_ARGS $KUBELET_CGROUP_ARGS/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Start services
systemctl enable docker
systemctl start docker
systemctl enable kubelet
systemctl start kubelet

# Set settings needed by Docker
sysctl net.bridge.bridge-nf-call-iptables=1
sysctl net.bridge.bridge-nf-call-ip6tables=1

# Fix certificates file on CentOS
if cat /etc/*release | grep ^NAME= | grep CentOS ; then
    rm -rf /etc/ssl/certs/ca-certificates.crt/
    cp /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
fi

# Initialize the master
cat >/tmp/kubeadm.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
token: ${kubeadm_token}
cloudProvider: aws
kubernetesVersion: v$${KUBERNETES_VERSION}
apiServerCertSANs:
- $${DNS_NAME}
EOF

kubeadm reset
kubeadm init --config /tmp/kubeadm.yaml
rm /tmp/kubeadm.yaml

# Use the local kubectl config for further kubectl operations
export KUBECONFIG=/etc/kubernetes/admin.conf

# Install weave
kubectl apply -f /tmp/weave.yaml

# Allow the user to administer the cluster
kubectl create clusterrolebinding admin-cluster-binding --clusterrole=cluster-admin --user=admin

# Prepare the kubectl config file for download to client
export KUBECONFIG_OUTPUT=/home/centos/kubeconfig
kubeadm alpha phase kubeconfig client-certs \
  --client-name admin \
  --server "https://$${DNS_NAME}:6443" \
  > $$KUBECONFIG_OUTPUT
chown centos:centos $$KUBECONFIG_OUTPUT
chmod 0600 $$KUBECONFIG_OUTPUT

# Install Tiller (Helm)
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
# Wait for tiller
kubectl rollout status -w deployment/tiller-deploy --namespace=kube-system

# Install unzip
yum install -y unzip

# Download and install addons
aws s3 cp ${addons_zip_url} /tmp/ && unzip /tmp/addons.zip -d /tmp/addons && rm /tmp/addons.zip

for ADDON in ${addons}
do
  helm install /tmp/addons/$ADDON -f /tmp/addons/$ADDON/default-values.yaml --namespace kube-system --wait --timeout 600
done