local PINNED_DATE = "202506";
local k8sData = import "./k8sData.libsonnet";
 

// ubuntu-eks/k8s_1.32/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-20250516 - maybe
// ubuntu-eks/k8s_1.32/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250430 - want
{
  baseOS: 'ubuntu',
  // baseOS: 'amzn_2',
  lookupFormat: '{{.BaseOS}}-eks/k8s_{{.K8sVersion | printf "%.4s"}}/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-' + PINNED_DATE + "*",
  // lookupFormat: 'charter_eks_{{.K8sVersion | printf "%.4s"}}_{{.BaseOS}}_ami_' + PINNED_DATE + "*",
  lookupOrg: '679593333241', // aws-marketplace,
  // amiFamily: "AL2", //Used by Karpenter
  // name: 'charter_eks_' + std.toString(k8sData.k8sVersionFloat) + '_amzn_2_ami_' + PINNED_DATE + '*',  //Used by Karpenter
}