local addons = import './lib/addons.libsonnet';
local k8sData = import './lib/k8sData.libsonnet';
 
local awsAccountId = std.extVar('awsAccountId');
local downstreamNamespace = std.extVar('downstreamNamespace');
local clusterName = std.extVar('clusterName');

local awsPrivateSubnets = std.map(function(value) {
  id: value,
}, std.split(std.extVar('awsPrivateSubnets'), ','));




local clusterAdminRoleNames = std.map(function(roleName) {
  rolearn: std.format('arn:aws:iam::%(awsAccountId)s:role/%(roleName)s' % {awsAccountId: awsAccountId, roleName: roleName}),
  username: "sso-admin",
  groups: ['sso-admin-group'],
}, std.extVar('clusterAdminRoleNames'));

local stringToBool(s) =
  if s == "true" then true
  else if s == "false" then false
  else error "invalid boolean: " + std.manifestJson(s);
 
// local cluster = importstr './clusters//config.yaml'; // Import the config file, presented into scope by ArgoCD under the hood via `libs`.
// local clusterTags = std.parseYaml(cluster).cluster.tags;
local cluster = import './clusters/ljc/capi-downstream-poc/config.yaml'; // Import the config file, presented into scope by ArgoCD under the hood via `libs`.
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
      allowedNamespaces: {
        list: [
          downstreamNamespace,
        ]
      },
      durationSeconds: 3600,
      sessionName: awsAccountId + '-capa-role-local-session',
      roleARN: 'arn:aws:iam::' + awsAccountId + ':role/CAPARole-local',
      sourceIdentityRef: {
        kind: 'AWSClusterControllerIdentity',
        name: 'default',
      },
    },
  },
 
  // // //CAPA - AWSManagedControlPlane
  {
    apiVersion: 'controlplane.cluster.x-k8s.io/v1beta2',
    kind: 'AWSManagedControlPlane',
    metadata: {
      name: clusterName,
      namespace: downstreamNamespace,
    },
    spec: {
      additionalTags: {},
      // additionalTags: clusterTags,
      // additionalTags: {
      //   'charter.com/source': 'capi',
      //   App: std.extVar('cluster.tags.application'),
      //   Group: std.extVar('cluster.tags.group'),
      //   Org: std.extVar('cluster.tags.organization'),
      //   Stack: std.extVar('cluster.tags.stack'),
      //   Team: std.extVar('cluster.tags.team'),
      //   Email: std.extVar('cluster.tags.email'),
      //   VicePresident: std.extVar('cluster.tags.vpEmail'),
      // },
      addons: addons,
      associateOIDCProvider: true,
      eksClusterName: clusterName,
      endpointAccess: {
        private: true,
        public: stringToBool(std.extVar('clusterPublicAccess')),
        publicCIDRs: std.split(std.extVar('clusterPublicAccessCidrs'), ',')
      },
      iamAuthenticatorConfig: {
        mapRoles: clusterAdminRoleNames,
      },
      // iamAuthenticatorConfig: {
      //   mapRoles: std.flattenArrays([std.mapWithIndex(function(index, x) {
      //     username: std.format('Admin-%s', [std.toString(index)]),
      //     rolearn: std.format('arn:aws:iam::%s:role/%s', [awsAccountId, x]),
      //     groups: ['system:masters'],
      //   }, std.split(std.extVar('cluster.authentication.iamRoles'), ',')), [{
      //     username: 'system:node:{{EC2PrivateDNSName}}',
      //     rolearn: std.format('arn:aws:iam::%s:role/capi-karpenter-node-role', awsAccountId),
      //     groups: ['system:masters'],
      //   }]]),
      // },
      identityRef: {
        kind: 'AWSClusterRoleIdentity',
        name: awsAccountId + "-aws-cluster-role-identity",
      },
      logging: {
        apiServer: true,
        audit: true,
        authenticator: true,
        controllerManager: true,
        scheduler: true,
      },
      network: {
        securityGroupOverrides: {
          'node-eks-additional': std.extVar('clusterAdditionalSecurityGroup')
        },
        subnets: awsPrivateSubnets,
        vpc: {
          id: std.extVar('awsVpcId'),
        },
      },
      region: std.extVar('awsRegion'),
      roleAdditionalPolicies: [
        'arn:aws:iam::aws:policy/AmazonEKSVPCResourceController',
        'arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore',
      ],
      sshKeyName: 'default',
      version: k8sData.kubernetesVersion
    },
  },
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
  // ,
]