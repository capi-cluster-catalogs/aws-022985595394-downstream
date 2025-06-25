local addons = import './lib/addons.libsonnet';
local k8sData = import './lib/k8sData.libsonnet';
 
local awsAccountId = std.extVar('awsAccountId');
local downstreamNamespace = std.extVar('downstreamNamespace');
local clusterName = std.extVar('clusterName');
 
// local cluster = importstr './clusters//config.yaml'; // Import the config file, presented into scope by ArgoCD under the hood via `libs`.
// local clusterTags = std.parseYaml(cluster).cluster.tags;
local cluster = import './clusters/bfe/phoenix-test/config.yaml'; // Import the config file, presented into scope by ArgoCD under the hood via `libs`.
// local cluster = import './clusters/' + std.extVar('BfeClusterFolderName') + std.extVar('clusterName') + '/config.yaml'; // Import the config file, presented into scope by ArgoCD under the hood via `libs`.
local clusterTags = std.parseYaml(cluster).clusterConfig.tags;
 
[
  {
    apiVersion: 'cluster.x-k8s.io/v1beta1',
    kind: 'Cluster',
    metadata: {
      name: clusterName,
      namespace: downstreamNamespace,
      labels: {
        'bfe.phoenix.spectrum.com/account': awsAccountId,
        'bfe.phoenix.spectrum.com/name': clusterName,
      },
    },
    spec: {
      clusterNetwork: {
        pods: {
          cidrBlocks: [
            '192.168.0.0/16',
            '100.64.0.0/16',
          ],
        },
      },
      infrastructureRef: {
        apiVersion: 'infrastructure.cluster.x-k8s.io/v1beta2',
        kind: 'AWSManagedCluster',
        name: clusterName,
      },
      controlPlaneRef: {
        apiVersion: 'controlplane.cluster.x-k8s.io/v1beta2',
        kind: 'AWSManagedControlPlane',
        name: clusterName + '-cp',
      },
    },
  },
 
  //CAPA - AWSManagedCluster
  {
    apiVersion: 'infrastructure.cluster.x-k8s.io/v1beta2',
    kind: 'AWSManagedCluster',
    metadata: {
      name: clusterName,
      namespace: downstreamNamespace,
      labels: {
        'bfe.phoenix.spectrum.com/account': awsAccountId,
        'bfe.phoenix.spectrum.com/name': clusterName,
      },
    },
    spec: {},
  },
  // CAPA - AWSClusterRoleIdentity
  {
    apiVersion: "infrastructure.cluster.x-k8s.io/v1beta2",
    kind: "AWSClusterRoleIdentity",
    metadata: {
      name: awsAccountId + "-aws-cluster-role-identity",
      namespace: downstreamNamespace,
    },
    spec: {
      allowedNamespaces: [
        downstreamNamespace,
      ],
      durationSeconds: 3600,
      roleARN: 'arn:aws:iam::' + awsAccountId + ':role/' + awsAccountId + '-capa-assume-role',
      sourceIdentityRef: {
        kind: 'AWSClusterControllerIdentity',
        name: 'default',
      },
    },
  },
 
  // // //CAPA - AWSManagedControlPlane
  // {
  //   apiVersion: 'controlplane.cluster.x-k8s.io/v1beta2',
  //   kind: 'AWSManagedControlPlane',
  //   metadata: {
  //     name: clusterName,
  //     namespace: downstreamNamespace,
  //   },
  //   spec: {
  //     additionalTags: clusterTags,
  //     // additionalTags: {
  //     //   'charter.com/source': 'capi',
  //     //   App: std.extVar('cluster.tags.application'),
  //     //   Group: std.extVar('cluster.tags.group'),
  //     //   Org: std.extVar('cluster.tags.organization'),
  //     //   Stack: std.extVar('cluster.tags.stack'),
  //     //   Team: std.extVar('cluster.tags.team'),
  //     //   Email: std.extVar('cluster.tags.email'),
  //     //   VicePresident: std.extVar('cluster.tags.vpEmail'),
  //     // },
  //     addons: addons,
  //     associateOIDCProvider: true,
  //     eksClusterName: clusterName,
  //     endpointAccess: {
  //       private: true,
  //       public: std.extVar('clusterPublicAccess'),
  //       publicCIDRs: std.extVar('clusterPublicAccessCidrs'),
  //     },
  //     iamAuthenticatorConfig: {
  //       mapRoles: std.flattenArrays([std.mapWithIndex(function(index, x) {
  //         username: std.format('Admin-%s', [std.toString(index)]),
  //         rolearn: std.format('arn:aws:iam::%s:role/%s', [awsAccountId, x]),
  //         groups: ['system:masters'],
  //       }, std.split(std.extVar('cluster.authentication.iamRoles'), ',')), [{
  //         username: 'system:node:{{EC2PrivateDNSName}}',
  //         rolearn: std.format('arn:aws:iam::%s:role/capi-karpenter-node-role', awsAccountId),
  //         groups: ['system:masters'],
  //       }]]),
  //     },
  //     identityRef: {
  //       kind: 'AWSClusterRoleIdentity',
  //       name: std.extVar('account'),
  //     },
  //     logging: {
  //       apiServer: true,
  //       audit: true,
  //       authenticator: true,
  //       controllerManager: true,
  //       scheduler: true,
  //     },
  //     network: {
  //       securityGroupOverrides: {
  //         'node-eks-additional': std.extVar('networking.vpc.additionalSecurityGroups')
  //       },
  //       subnets: std.map(
  //         function(x) {
  //           id: x,
  //         }, std.split(std.extVar('networking.vpc.privateSubnets'), ',') //Private Subnets
  //       ),
  //       vpc: {
  //         id: std.extVar('networking.vpc.id'),
  //       },
  //     },
  //     region: 'us-east-1',
  //     roleAdditionalPolicies: [
  //       'arn:aws:iam::aws:policy/AmazonEKSVPCResourceController',
  //       'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore',
  //     ],
  //     sshKeyName: 'default',
  //     version: k8sData.k8sVersion
  //   },
  // },
  // {
  //   apiVersion: 'bootstrap.cluster.x-k8s.io/v1beta2',
  //   kind: 'EKSConfigTemplate',
  //   metadata: {
  //     name: std.extVar('clusterName'),
  //     namespace: downstreamNamespace,
  //     labels: {
  //       'cluster.charter.com/account': std.extVar('account'),
  //       'cluster.charter.com/name': std.extVar('clusterName'),
  //     },
  //   },
  //   spec: {
  //     template: {},
  //   },
  // },
]