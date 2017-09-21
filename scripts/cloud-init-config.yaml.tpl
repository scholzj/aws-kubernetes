#cloud-config
#
write_files:
-   encoding: gz+b64
    content: ${weave_yaml_content}
    owner: root:root
    path: /tmp/weave.yaml
    permissions: '0664'
