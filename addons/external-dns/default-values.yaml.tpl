image:
  tag: v0.4.4
provider: aws
nodeSelector:
  node-role.kubernetes.io/master: ""
tolerations:
  - key: "node-role.kubernetes.io/master"
    effect: NoSchedule
policy: sync
podAnnotations:
  scheduler.alpha.kubernetes.io/critical-pod: "true"
extraArgs:
  registry: txt
  txt-owner-id: ${cluster_name}
resources:
  limits:
    memory: 50Mi
  requests:
    memory: 50Mi
    cpu: 10m
rbac:
  create: true