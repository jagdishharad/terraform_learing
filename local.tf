locals {
  account_id                        = data.aws_caller_identity.current.account_id
  cluster_iam_role_arn              = data.aws_iam_role.cluster_role.arn
  worker_iam_role_arn               = data.aws_iam_role.worker_role.arn
  cluster_security_group_id         = aws_security_group.cluster.id
  worker_security_group_id          = aws_security_group.workers.id
  cluster_primary_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  cluster_id                        = aws_eks_cluster.this.id
  
  ec2_principal                     = "ec2.${data.aws_partition.current.dns_suffix}"
  eks_principal                     = "eks.${data.aws_partition.current.dns_suffix}"

  file_input                        = yamldecode(file("input.yaml"))
  environment                       = local.file_input.tags.environment
  use_case                          = local.file_input.tags.use_case
  cluster_number                    = local.file_input.tags.cluster_number
  cluster_name                      = "${local.environment}-${local.use_case}-${local.file_input.required.awsRegion}-eks-${local.cluster_type}-${format("%02s", local.cluster_number)}"
  cluster_type                      = "${lookup(local.file_input, "cluster_type", "caas")}"
  cluster_sg_name                   = "${local.cluster_name}-cluster-sg"
  worker_sg_name                    = "${local.cluster_name}-worker-sg"
  
  selected_tags = merge(tomap({
    terraform         = "true",
    region            = local.file_input.required.awsRegion,
    "cluster name"    = local.cluster_name,
    "cluster type"    = local.cluster_type
    }),
    local.input.tags,
  )

  system_labels = tomap({
    type  = "system"
  })

  configmap_worker_role = [{
      rolearn  = replace(local.worker_iam_role_arn, replace(var.iam_path, "/^//", ""), "")
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  configmap_input_roles = [
    for role in local.file_input.cluster_auth.roles : {
      rolearn  = data.aws_iam_role.aws_roles[role["rolename"]].arn
      username = role["rolename"]
      groups   = role["groups"]
    }
  ]

  configmap_roles = concat(local.configmap_worker_role, local.configmap_input_roles)

  configmap_users = [
    for user in concat(local.file_input.cluster_auth.users) : {
      userarn  = data.aws_iam_user.aws_users[user["username"]].arn
      username = user["username"]
      groups   = user["groups"]
    }
  ]

  input_defaults = {
    cluster_create_timeout          = var.cluster_create_timeout
    cluster_delete_timeout          = var.cluster_delete_timeout
    cluster_service_ipv4_cidr       = var.cluster_service_ipv4_cidr
    cluster_endpoint_public_access  = var.cluster_endpoint_public_access
    cluster_endpoint_private_access = var.cluster_endpoint_private_access
    associate_public_ip_address     = var.associate_public_ip_address
    ami_account_id                  = var.ami_account_id
    volume_type                     = var.volume_type
    log_group_class                 = var.log_group_class
  }

  input = merge(local.input_defaults, local.file_input)

  kubeconfig = templatefile("${path.module}/templates/kubeconfig.tpl", {
    kubeconfig_name      = aws_eks_cluster.this.arn
    endpoint             = aws_eks_cluster.this.endpoint
    cluster_auth_base64  = aws_eks_cluster.this.certificate_authority[0].data
    region               = "${local.input.required.awsRegion}"
    cluster_name         = aws_eks_cluster.this.name
    role_arn             = "arn:aws:iam::${var.aws_acnt_id}:role/eks-${local.environment}-iamrole"
  })

  coredns_patch = templatefile("${path.module}/templates/coredns_patch.tpl", {})

  system_ngp    = [ for v in local.input.system_node_groups : v ]

  spot_ngp      = [ for v in local.input.node_groups : v if v.capacity_type == "SPOT" ]

  ondemand_ngp  = [ for v in local.input.node_groups : v if v.capacity_type == "ON_DEMAND" ]

  system_schedule_node_groups = {
    for idx, val in local.system_ngp : 
      idx => val 
      if val.shutdown_options.enabled && contains(var.autoschedule_allowed_envs, local.environment)
  }

  od_schedule_node_groups = {
    for idx, val in local.ondemand_ngp : 
      idx => val 
      if val.shutdown_options.enabled && contains(var.autoschedule_allowed_envs, local.environment)
  }

  sp_schedule_node_groups = {
    for idx, val in local.spot_ngp : 
      idx => val 
      if val.shutdown_options.enabled && contains(var.autoschedule_allowed_envs, local.environment)
  }


  vpc_cni_version = var.addons_version[tonumber(local.input.cluster_version)]["vpc-cni"]


  root_volume           = [ for v in data.aws_ami.eks_worker.block_device_mappings : v if v.device_name == "/dev/xvda" ]
  
  data_volume           = [ for v in data.aws_ami.eks_worker.block_device_mappings : v if v.device_name == "/dev/sdf" ]
  graviton_data_volume  = [ for v in data.aws_ami.graviton_eks_worker.block_device_mappings : v if v.device_name == "/dev/sdf" ]
  ml_cpu_data_volume    = [ for v in data.aws_ami.ml_cpu_eks_worker.block_device_mappings : v if v.device_name == "/dev/sdf" ]

}
