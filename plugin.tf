resource "random_id" "random_id" {
  byte_length = 8
}


resource "local_file" "coredns_patch" {
  content              = local.coredns_patch
  filename             = "coredns-patch.yaml"
  file_permission      = "0600"
  directory_permission = "0600"
}


resource "null_resource" "patch_coredns" {
  provisioner "local-exec" {
    command = "kubectl patch deployment coredns --patch-file '${path.cwd}'/coredns-patch.yaml -n kube-system"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${path.cwd}/kubeconfig"
    }
  }
  depends_on = [
    aws_eks_cluster.this,
    local_file.kubeconfig
  ]
}

data "aws_iam_policy_document" "eks_ca_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ca" {
  assume_role_policy  = data.aws_iam_policy_document.eks_ca_assume_role_policy.json
  managed_policy_arns = [data.aws_iam_policy.eks_ca_policy.arn]
  name                = "eksautoscaling-${local.cluster_name}-${random_id.random_id.id}"
}

resource "null_resource" "delete_gp2_sc" {
  provisioner "local-exec" {
    command     = "kubectl delete storageclass gp2"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = "${path.cwd}/kubeconfig"
    }
  }
  depends_on = [
    aws_eks_cluster.this,
    local_file.kubeconfig
  ]
}

data "aws_iam_policy_document" "eks_ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ebs_csi" {
  assume_role_policy  = data.aws_iam_policy_document.eks_ebs_csi_assume_role_policy.json
  managed_policy_arns = [data.aws_iam_policy.eks_ebs_csi_policy.arn]
  name                = "eksebs-${local.cluster_name}-${random_id.random_id.id}"
}

data "aws_iam_policy_document" "eks_efs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.this.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_efs_csi" {
  assume_role_policy  = data.aws_iam_policy_document.eks_efs_csi_assume_role_policy.json
  managed_policy_arns = [data.aws_iam_policy.eks_efs_csi_policy.arn]
  name                = "eksefs-${local.cluster_name}-${random_id.random_id.id}"
}
