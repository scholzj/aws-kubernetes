#!/bin/bash

NODES=$(kubectl get nodes -l '!node-role.kubernetes.io/master' -o=jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')

for NODE in $NODES
do
    ssh -oStrictHostKeyChecking=no centos@${NODE} 'for i in {1..5} ; do sudo mkdir /mnt/vol-$i; done'
done

NODES=$(kubectl get nodes -l '!node-role.kubernetes.io/master' -o=jsonpath='{.items[*].metadata.name}')

for NODE in $NODES
do
    for i in {1..5}
    do
        cat <<EOF > /tmp/local-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $NODE-vol-$i
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/vol-$i
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - $NODE
EOF

        kubectl apply -f /tmp/local-volume.yaml
    done
done

cat <<EOF > /tmp/local-storage-class.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

kubectl apply -f /tmp/local-storage-class.yaml