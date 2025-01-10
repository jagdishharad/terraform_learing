provider "kubernetes" {
  host                      = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate    = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                     = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name                  = "aws-auth"
    namespace             = "kube-system"
    labels                = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    mapRoles = yamlencode(local.configmap_roles)
    mapUsers = yamlencode(local.configmap_users)
  }
}

resource "local_file" "kubeconfig" {
  content              = local.kubeconfig
  filename             = "kubeconfig"
  file_permission      = "0600"
  directory_permission = "0600"
}
