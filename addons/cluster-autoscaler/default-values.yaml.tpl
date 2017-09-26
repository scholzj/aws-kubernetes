autoscalingGroups:
  ${asg_nodes}
awsRegion: ${aws_region}
cloudProvider: aws
image:
  tag: v0.6.2
tolerations:
  - key: "node-role.kubernetes.io/master"
    effect: NoSchedule
extraArgs:
  skip-nodes-with-local-storage: false
nodeSelector:
  node-role.kubernetes.io/master: ""
podAnnotations:
  scheduler.alpha.kubernetes.io/tolerations: '[{"key":"dedicated", "value":"master"}]'
rbac:
  create: true
resources:
  limits:
    cpu: 100m
    memory: 300Mi
  requests:
    cpu: 100m
    memory: 300Mi