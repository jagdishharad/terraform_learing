data "aws_region" "current" {}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["crisil-cis-eks-node-${local.input.cluster_version}-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  most_recent = true
  owners   = ["${local.input.ami_account_id}"]
}

data "aws_ami" "graviton_eks_worker" {
  filter {
    name   = "name"
    values = ["crisil-cis-eks-arm64-node-${local.input.cluster_version}-v*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  most_recent = true
  owners   = ["${local.input.ami_account_id}"]
}

data "aws_ami" "ml_cpu_eks_worker" {
  filter {
    name   = "name"
    values = ["crisil-cis-eks-ml-cpu-node-${local.input.cluster_version}-v*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  most_recent = true
  owners   = ["${local.input.ami_account_id}"]
}


data "aws_eks_cluster" "cluster" {
  name = local.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_id
}

data "aws_iam_role" "cluster_role" {
  name = "eks_cluster-${local.environment}-iamrole"
}

data "aws_iam_role" "worker_role" {
  name = "eks_node_group-${local.environment}-iamrole"
}

data "aws_kms_key" "eks" {
  key_id = "alias/${local.selected_tags.businessunit}-${local.environment}-${local.input.required.awsRegion}-kms-05"
}

data "aws_kms_key" "ebs" {
  key_id = "alias/${local.selected_tags.businessunit}-${local.environment}-${local.input.required.awsRegion}-kms-04"
}

data "aws_iam_user" "aws_users" {
  for_each  = toset(local.file_input.cluster_auth.users.*.username)
  user_name = each.key
}

data "aws_iam_role" "aws_roles" {
  for_each  = toset(local.file_input.cluster_auth.roles.*.rolename)
  name      = each.key
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}


data "aws_subnets" "eks" {
  filter {
    name   = "vpc-id"
    values = [local.input.vpc_id] 
  }

  tags = {
    Target          = "EKS"
    "cluster_type"  = "${upper(local.cluster_type)}"
  }
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "aws_iam_policy" "eks_ebs_csi_policy" {
  name = "AmazonEKS_EBS_CSI_Driver-${local.environment}-Policy"
}

data "aws_iam_policy" "eks_efs_csi_policy" {
  name = "AmazonEKS_EFS_CSI_Driver-${local.environment}-Policy"
}


data "aws_iam_policy" "eks_ca_policy" {
  name = "AmazonEKSClusterAutoscaler-${local.environment}-Policy"
}

data "template_file" "launch_template_userdata" {
  template = file("${path.module}/templates/userdata.sh.tpl")

  vars = {
    cluster_name        = local.cluster_name
    endpoint            = element(concat(aws_eks_cluster.this.*.endpoint, [""]), 0)
    cluster_auth_base64 = element(concat(aws_eks_cluster.this[*].certificate_authority[0].data, [""]), 0)

    bootstrap_extra_args = ""
    kubelet_extra_args   = ""
  }
}
