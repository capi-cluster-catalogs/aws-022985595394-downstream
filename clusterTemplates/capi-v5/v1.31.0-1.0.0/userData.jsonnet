local clusterName = std.extVar('clusterName');
local awsAccountId = std.extVar('awsAccountId');
[
  {
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: clusterName + '-userdata',
      namespace: awsAccountId,
      labels: {
        'cluster.charter.com/account': awsAccountId,
        'cluster.charter.com/name': clusterName,
      },
    },
    data: {
      //https://release-1-8.cluster-api.sigs.k8s.io/developer/providers/bootstrap
      value: std.base64('#cloud-config\n' + 'write_files:\n' + 'runcmd:\n' + '  - /etc/eks/bootstrap.sh ' + clusterName),
    },
    type: 'Opaque',
  },
]