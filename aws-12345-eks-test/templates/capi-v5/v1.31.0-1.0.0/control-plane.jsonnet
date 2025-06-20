local addons = import "./lib/addons.libsonnet";
local kubernetesData = import "./lib/k8sData.libsonnet";
local accountId = std.split(std.extVar("namespace"), "-")[1];
local clusterTags = std.parseYaml(clusterConfig).clusterConfig.additionalTags;
local publicCIDRs = [
  "142.136.0.0/16"
]

[
  {
    apiVersion: c"luster.x-k8s.io/v1beta1",
    kind: "Cluster",
    metadata: {
      name: std.extVar("clusterName"),
      namespace: std.extVar("namespace"),
      labels: {
        "cluster.kubesources.com/accountId": accountId,
        "cluster.kubesources.name": std.extVar("clusterName"),
      },
    },
    spec: {
      clusterNetwork: {
        pods: {
          cidrBlocks: [
            "192.168.0.0/16",
            "100.64.0.0/16",
          ],
        },
      },
      infrastructureRef: {
        apiVersion: "infrastructure.cluster.x-k8s.io/v1beta2",
        kind: "AWSManagedCluster",
        name: std.extVar("clusterName"),
      },
      controlPlaneRef: {
        apiVersion: "controlplane.cluster.x-k8s.io/v1beta2",
        kind: "AWSManagedControlPlane",
        name: std.extVar("clusterName") + "-cp",
      },
    },
  },
  {
    apiVersion: "controlplane.cluster.x-k8s.io/v1beta2",
    kind: "AWSManagedCluster",
    metadata: {
      name: std.extVar("clusterName"),
      namespace: std.extVar("namespace"),
      labels: {
        "cluster.kubesources.com/accountId": accountId,
        "cluster.kubesources.name": std.extVar("clusterName"),
      },
    }
    spec: {}
  },
  {
    apiVersion: "controlplane.cluster.x-k8s.io/v1beta2",
    kind: "AWSManagedControlPlane",
    metadata: {
      name: std.extVar("clusterName") + "-cp",
      namespace: std.extVar("namespace"),
      labels: {
        "cluster.kubesources.com/accountId": accountId,
        "cluster.kubesources.name": std.extVar("clusterName"),
      },
    },
    spec: {
      additionalTags: clusterTags,
      addons: addons,
      associateOIDCProvider: true,
      eksClusterName: std.extVar("clusterName"),
      endpointAccess: {
        private: true,
        public: true,
        publicCIDRs: publicCIDRs,
      },
      iamAuthenticatorConfig: {
        mapRoles: [
          {
            username: "kubernetes-admin",
            rolearn: "arn:aws:iam::022985595394:role/gitlab-runner-provisioner-role",
            groups: [
              "system:masters",
            ],
          },
        ],
      },
      identityRef: {
        kind: "AWSClusterRoleIdentity",
        name: "0123456",
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
          "node-eks-additional": "sg-0b8a3d770a6ea6c67",
        },
        subnets: [
          {
            id: "subnet-032be6b4fef867aa7",
          },
          {
            id: "subnet-06b2aad00fca255bc",
          },
        ],
        vpc: {
          id: std.extVar("networking.vpc.id"),
        },
      },
      region: std.extVar("aws.region"),
      sshKeyName: "default",
      version: kubernetesData.kubernetesVersion
    },
  },
  {
    apiVersion: "bootstrap.cluster.x-k8s.io/v1beta2",
    kind: "EKSConfigTemplate",
    metadata: {
      name: std.extVar("clusterName"),
      namespace: std.extVar("namespace"),
      labels: {
        "cluster.kubesources.com/accountId": accountId,
        "cluster.kubesources.name": std.extVar("clusterName"),
      },
    },
    spec: {
      template: {},
    },
  },
]