rbac:
  create: true
controller:
  image:
    tag: 0.9.0-beta.13
  publishService:
    enabled: true
  ## DaemonSet or Deployment
  kind: DaemonSet
  resources:
    limits:
      cpu: 100m
      memory: 64Mi
    requests:
      cpu: 100m
      memory: 64Mi
  config:
    use-proxy-protocol: "true"
  service:
    annotations:
      ${annotations}
defaultBackend:
  enabled: true
  image:
    tag: 1.3
  resources:
    limits:
      cpu: 10m
      memory: 20Mi
    requests:
      cpu: 10m
      memory: 20Mi