local awsAccountId = std.extVar('awsAccountId');
local clusterName = std.extVar('clusterName');
local nodePoolName = std.extVar('clusterName') + '-system-pool';
local downstreamNamespace = std.extVar('downstreamNamespace');
local k8sData = import "./lib/k8sData.libsonnet";
local amiData = import "./lib/amiData.libsonnet";

[
  {
    apiVersion: 'cluster.x-k8s.io/v1beta1',
    kind: 'MachinePool',
    metadata: {
      name: nodePoolName,
      namespace: downstreamNamespace,
      labels: {
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
      },
    },
    spec: {
      clusterName: clusterName,
      replicas: std.parseInt(std.extVar('clusterSystemNodeReplicas')),
      template: {
        spec: {
          clusterName: clusterName,
          bootstrap: {
            configRef: {
              apiVersion: 'bootstrap.cluster.x-k8s.io/v1beta2',
              kind: 'EKSConfigTemplate',
              name: clusterName,
            },
            dataSecretName: clusterName + '-userdata', //https://release-1-8.cluster-api.sigs.k8s.io/developer/providers/bootstrap
          },
          infrastructureRef: {
            apiVersion: 'infrastructure.cluster.x-k8s.io/v1beta2',
            kind: 'AWSManagedCluster',
            name: clusterName,
          },
          version: k8sData.kubernetesMachinePoolVersion,
        },
      },
    },
  },
  {
    apiVersion: 'infrastructure.cluster.x-k8s.io/v1beta2',
    kind: 'AWSManagedMachinePool',
    metadata: {
      name: nodePoolName,
      namespace: downstreamNamespace,
      labels: {
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
      },
    },
    spec: {
      additionalTags: {
        App: std.extVar('clusterAdditionalTagsApp'),
        Group: std.extVar('clusterAdditionalTagsGroup'),
        Org: std.extVar('clusterAdditionalTagsOrg'),
        Stack: std.extVar('clusterAdditionalTagsStack'),
        Team: std.extVar('clusterAdditionalTagsTeam'),
        Email: std.extVar('clusterAdditionalTagsEmail'),
        VpEmail: std.extVar('clusterAdditionalTagsVpEmail'),
        AppId: std.extVar('clusterAdditionalTagsAppId'),
        AppRefId: std.extVar('clusterAdditionalTagsAppRefId'),
        CostCode: std.extVar('clusterAdditionalTagsCostCode'),
        DataPriv: std.extVar('clusterAdditionalTagsDataPriv'),
        OpsOwner: std.extVar('clusterAdditionalTagsOpsOwner'),
        SecOwner: std.extVar('clusterAdditionalTagsSecOwner'),
        DevOwner: std.extVar('clusterAdditionalTagsDevOwner'),
      },
      eksNodegroupName: nodePoolName,
      amiType: "CUSTOM",
      awsLaunchTemplate: {
        imageLookupBaseOS: amiData.baseOS,
        imageLookupFormat: amiData.lookupFormat,
        imageLookupOrg: amiData.lookupOrg,
        name: nodePoolName,
        instanceType: std.extVar('clusterSystemNodeType'),
        rootVolume: {
          size: 250,
          type: 'gp3',
        },
        instanceMetadataOptions: {
          httpTokens: 'required',
          httpPutResponseHopLimit: 2,
        },
      },
      availabilityZones: std.split(std.extVar('awsAvailabilityZones'), ','),
      labels: {
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
        'ljc.kubesources.com/node-role': 'system',
      },
      taints: [
        {
          key: 'ljc.kubesources.com/node-role',
          value: 'system',
          effect: 'no-schedule',
        },
      ],
      subnetIDs: std.split(std.extVar('awsIntraSubnets'), ','),
      roleAdditionalPolicies: [
        'arn:aws:iam::aws:policy/AmazonEKSVPCResourceController',
        'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore',
        'arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy',
        std.format('arn:aws:iam::%s:policy/capa-nodes-elb-policy', awsAccountId),
        std.format('arn:aws:iam::%s:policy/capa-nodes-assume-policy', awsAccountId),
        std.format('arn:aws:iam::%s:policy/capa-nodes-karpenter-controller-policy', awsAccountId),
      ],
    },
  },
]