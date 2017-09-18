apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: external-dns
    k8s-addon: external-dns.alpha.kubernetes.io
  name: external-dns
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - "extensions"
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: external-dns
  labels:
    k8s-app: external-dns
    k8s-addon: external-dns.alpha.kubernetes.io
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: kube-system
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
  labels:
    app: external-dns
    k8s-addon: external-dns.alpha.kubernetes.io
spec:
  strategy:
    type: Recreate
  replicas: 1
  template:
    metadata:
      labels:
        app: external-dns
        k8s-addon: external-dns.alpha.kubernetes.io
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: "true"
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.opensource.zalan.do/teapot/external-dns:v0.4.4
        args:
        - --source=service
        - --source=ingress
        - --provider=aws
        - --registry=txt
        - --txt-owner-id=${cluster_name}
        #- --domain-filter={{ dns_zone }}. # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
        #- --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
      nodeSelector:
        node-role.kubernetes.io/master: ""
      tolerations:
        - key: "node-role.kubernetes.io/master"
          effect: NoSchedule