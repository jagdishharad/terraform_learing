resource "aws_launch_template" "system" {
  count                  = length(local.system_ngp)
  name_prefix            = "${format("ng-%s-sys-%02s-", local.cluster_type, count.index+1)}"
  update_default_version = true

  image_id = local.system_ngp[count.index].arch == var.cpu_architecture.arm64 ? data.aws_ami.graviton_eks_worker.id : data.aws_ami.eks_worker.id

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
      volume_size           = local.system_ngp[count.index].arch == var.cpu_architecture.arm64 ? local.graviton_data_volume[0].ebs.volume_size : local.data_volume[0].ebs.volume_size
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
        "Name"                                        = "${local.cluster_name}-system-node"
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
      condition     = local.system_ngp[count.index].arch == var.cpu_architecture.arm64 || local.system_ngp[count.index].arch == var.cpu_architecture.amd64
      error_message = "Invalid CPU architecture specified. Allowed CPU architectures are '${var.cpu_architecture.arm64}' or '${var.cpu_architecture.amd64}'."
    }    
  }
}

resource "aws_eks_node_group" "system-group" {
  count                   = length(local.system_ngp)
  cluster_name            = aws_eks_cluster.this.name
  node_group_name         = "${format("ng-%s-sys-%02s", local.cluster_type, count.index+1)}"
  node_role_arn           = local.worker_iam_role_arn
  subnet_ids              = data.aws_subnets.eks.ids

  capacity_type           = "ON_DEMAND"
  instance_types          = local.system_ngp[count.index].instance_types

  scaling_config {
    desired_size          = local.system_ngp[count.index].desired_capacity
    max_size              = local.system_ngp[count.index].max_capacity
    min_size              = local.system_ngp[count.index].min_capacity
  }
  
  force_update_version = "${local.system_ngp[count.index].force_update_version}"
  update_config {
    max_unavailable_percentage = "${local.system_ngp[count.index].max_unavailable_percentage}"
  }

  timeouts {
    create =  var.ng_timeouts.create
    delete =  var.ng_timeouts.delete
	  update =  var.ng_timeouts.update
  }
  
  launch_template {
    id                    = aws_launch_template.system[count.index].id
    version               = aws_launch_template.system[count.index].default_version
  }

  labels = merge(local.system_labels, lookup(local.system_ngp[count.index], "labels", {}))

  

  tags =  merge(local.selected_tags, lookup(local.system_ngp[count.index], "tags", {}))
  
  taint {
    key     = "type"
    value   = "system"
    effect  = "NO_SCHEDULE"
  }

  dynamic "taint" {
    for_each = lookup(local.system_ngp[count.index], "taints", {})
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }


  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]
  }
}
