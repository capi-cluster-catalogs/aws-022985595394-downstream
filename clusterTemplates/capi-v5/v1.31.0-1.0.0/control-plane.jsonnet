local addons = import './lib/addons.libsonnet';
local k8sData = import './lib/k8sData.libsonnet';
local awsAccountId = std.extVar('awsAccountId');
local downstreamNamespace = std.extVar('downstreamNamespace');
local clusterName = std.extVar('clusterName');

local awsPrivateSubnets = std.map(function(value) {
  id: value,
}, std.split(std.extVar('awsPrivateSubnets'), ','));

local clusterAdminRoleNames = std.map(function(roleName) {
  rolearn: std.format('arn:aws:iam::%s:role/%s', [awsAccountId, roleName]),
  username: "sso-admin",
  groups: ['sso-admin-group'],
}, std.split(std.extVar('clusterAdminRoleNames'), ','));

local stringToBool(s) =
  if s == "true" then true
  else if s == "false" then false
  else error "invalid boolean: " + std.manifestJson(s);

 
[
  {
    apiVersion: 'cluster.x-k8s.io/v1beta1',
    kind: 'Cluster',
    metadata: {
      name: clusterName,
      namespace: downstreamNamespace,
      labels: {
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
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
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
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
      labels: {
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
      },
    },
    spec: {
      allowedNamespaces: {
        list: [
          downstreamNamespace,
        ]
      },
      durationSeconds: 3600,
      sessionName: awsAccountId + '-aws-cluster-role-identity-session',
      roleARN: 'arn:aws:iam::' + awsAccountId + ':role/' + awsAccountId + '-capa-assume-role',
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
      addons: addons,
      associateOIDCProvider: true,
      eksClusterName: clusterName,
      endpointAccess: {
        private: true,
        public: stringToBool(std.extVar('clusterPublicAccess')),
        publicCIDRs: std.split(std.extVar('clusterPublicAccessCidrs'), ','),
      },
      iamAuthenticatorConfig: {
        mapRoles: clusterAdminRoleNames,
      },
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
  {
    apiVersion: 'bootstrap.cluster.x-k8s.io/v1beta2',
    kind: 'EKSConfigTemplate',
    metadata: {
      name: clusterName,
      namespace: downstreamNamespace,
      labels: {
        'ljc.kubesources.com/account': awsAccountId,
        'ljc.kubesources.com/name': clusterName,
      },
    },
    spec: {
      template: {},
    },
  ,
]