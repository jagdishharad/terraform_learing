resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 90
  log_group_class   = local.input.log_group_class
}

resource "aws_eks_cluster" "this" {
  name                      = local.cluster_name
  enabled_cluster_log_types = ["api", "audit","authenticator","controllerManager","scheduler"]
  role_arn                  = local.cluster_iam_role_arn
  version                   = local.input.cluster_version
  tags                      = local.selected_tags
  
  vpc_config {
    security_group_ids      = compact([local.cluster_security_group_id])
    subnet_ids              = data.aws_subnets.eks.ids
    endpoint_private_access = local.input.cluster_endpoint_private_access
    endpoint_public_access  = local.input.cluster_endpoint_public_access
  }

  kubernetes_network_config {
    service_ipv4_cidr       = local.input.cluster_service_ipv4_cidr
  }

  timeouts {
    create                  = local.input.cluster_create_timeout
    delete                  = local.input.cluster_delete_timeout
  }

  encryption_config {
    provider {
      key_arn               = data.aws_kms_key.eks.arn
    }
    resources               = ["secrets"]
  }

  depends_on = [
    aws_security_group.cluster,
    aws_cloudwatch_log_group.this
  ]
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_eks_addon" "eks_cni_addon" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = local.vpc_cni_version
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
}
