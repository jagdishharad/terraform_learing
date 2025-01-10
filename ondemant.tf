resource "aws_launch_template" "ondemand" {
  count                  = length(local.ondemand_ngp)
  name_prefix            = "${format("ng-%s-od-%02s-", local.cluster_type, count.index+1)}"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = local.root_volume[0].ebs.volume_size
      volume_type           = local.input.volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = data.aws_kms_key.ebs.arn
    }
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = local.ondemand_ngp[count.index].arch == var.cpu_architecture.amd64 ? local.ondemand_ngp[count.index].type == var.node_group_type.app ? local.data_volume[0].ebs.volume_size : local.ml_cpu_data_volume[0].ebs.volume_size : local.graviton_data_volume[0].ebs.volume_size
      volume_type           = local.input.volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = data.aws_kms_key.ebs.arn
    }
  }

  monitoring {
    enabled = false
  }

  network_interfaces {
    associate_public_ip_address = local.input.associate_public_ip_address
    delete_on_termination       = true
    security_groups             = [local.worker_security_group_id]
  }


  image_id =  local.ondemand_ngp[count.index].arch == var.cpu_architecture.amd64 ? local.ondemand_ngp[count.index].type == var.node_group_type.app ? data.aws_ami.eks_worker.id : data.aws_ami.ml_cpu_eks_worker.id : data.aws_ami.graviton_eks_worker.id

  user_data = base64encode(
    data.template_file.launch_template_userdata.rendered
  )

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 8
    instance_metadata_tags      = "disabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.selected_tags,
      {
        "Name"                                        = "${local.cluster_name}-worker-od-node"
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
      },
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags =  local.selected_tags
  }

  tags =  local.selected_tags

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = local.ondemand_ngp[count.index].arch == var.cpu_architecture.arm64 || local.ondemand_ngp[count.index].arch == var.cpu_architecture.amd64
      error_message = "Invalid CPU Architecture specified. Allowed CPU Architectures are '${var.cpu_architecture.arm64}' or '${var.cpu_architecture.amd64}'."
    }

    precondition {
      condition     = local.ondemand_ngp[count.index].type == var.node_group_type.app || local.ondemand_ngp[count.index].type == var.node_group_type.ml
      error_message = "Invalid worker node group type specified. Allowed worker node group types are '${var.node_group_type.app}' or '${var.node_group_type.ml}'."
    }

    precondition {
      condition     = ( local.ondemand_ngp[count.index].type == var.node_group_type.ml && local.ondemand_ngp[count.index].arch == var.cpu_architecture.amd64 ) || ( local.ondemand_ngp[count.index].type == var.node_group_type.app && ( local.ondemand_ngp[count.index].arch == var.cpu_architecture.amd64 || local.ondemand_ngp[count.index].arch == var.cpu_architecture.arm64 ) )
      error_message = "Invalid combination of node group type and node group CPU architecture. '${var.node_group_type.ml}' type node groups can only have '${var.cpu_architecture.amd64}' as CPU architecture, and '${var.node_group_type.app}' type node groups can have '${var.cpu_architecture.amd64}' or '${var.cpu_architecture.arm64}' as CPU architecture."
    }
  }
}

resource "aws_eks_node_group" "ondemand-group" {
  count                   = length(local.ondemand_ngp)
  
  cluster_name            = aws_eks_cluster.this.name
  node_group_name         = "${format("ng-%s-od-%02s", local.cluster_type, count.index+1)}"
  
  node_role_arn           = local.worker_iam_role_arn
  subnet_ids              = data.aws_subnets.eks.ids

  capacity_type           = local.ondemand_ngp[count.index].capacity_type
  instance_types          = local.ondemand_ngp[count.index].instance_types

  scaling_config {
    desired_size          = local.ondemand_ngp[count.index].desired_capacity
    max_size              = local.ondemand_ngp[count.index].max_capacity
    min_size              = local.ondemand_ngp[count.index].min_capacity
  }
  
  force_update_version = "${local.ondemand_ngp[count.index].force_update_version}"
  update_config {
    max_unavailable_percentage = "${local.ondemand_ngp[count.index].max_unavailable_percentage}"
  }

  timeouts {
    create =  var.ng_timeouts.create
    delete =  var.ng_timeouts.delete
	  update =  var.ng_timeouts.update
  }

  launch_template {
    id                    = aws_launch_template.ondemand[count.index].id
    version               = aws_launch_template.ondemand[count.index].default_version
  }

  labels = lookup(local.ondemand_ngp[count.index], "labels", {})

  tags =  merge(local.selected_tags, lookup(local.ondemand_ngp[count.index], "tags", {}))
  
  dynamic "taint" {
    for_each = lookup(local.ondemand_ngp[count.index], "taints", {})
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]

    precondition {
      condition     = local.ondemand_ngp[count.index].capacity_type == var.capacity_type.ondemand
      error_message = "Invalid node group capacity type specified. Allowed capacity type is '${var.capacity_type.ondemand}'."
    }

  }

  depends_on = [
    aws_eks_node_group.system-group,
  ]
}
