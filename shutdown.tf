resource "aws_autoscaling_schedule" "system_start_schedule" {
  for_each               = local.system_schedule_node_groups
  scheduled_action_name  = "start-${aws_eks_node_group.system-group[each.key].node_group_name}"
  autoscaling_group_name = aws_eks_node_group.system-group[each.key].resources[0].autoscaling_groups[0].name
  min_size               = each.value.min_capacity
  max_size               = each.value.max_capacity
  desired_capacity       = each.value.desired_capacity
  time_zone              = "${local.input.time_zone}"
  recurrence             = each.value.shutdown_options.start_time
  depends_on = [
    aws_eks_node_group.system-group
  ]
}

resource "aws_autoscaling_schedule" "system_stop_schedule" {
  for_each               = local.system_schedule_node_groups
  scheduled_action_name  = "stop-${aws_eks_node_group.system-group[each.key].node_group_name}"
  autoscaling_group_name = aws_eks_node_group.system-group[each.key].resources[0].autoscaling_groups[0].name
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  time_zone              = "${local.input.time_zone}"
  recurrence             = each.value.shutdown_options.stop_time
  depends_on = [
    aws_eks_node_group.system-group
  ]
}


resource "aws_autoscaling_schedule" "ondemand_start_schedule" {
  for_each               = local.od_schedule_node_groups
  scheduled_action_name  = "start-${aws_eks_node_group.ondemand-group[each.key].node_group_name}"
  autoscaling_group_name = aws_eks_node_group.ondemand-group[each.key].resources[0].autoscaling_groups[0].name
  min_size               = each.value.min_capacity
  max_size               = each.value.max_capacity
  desired_capacity       = each.value.desired_capacity
  time_zone              = "${local.input.time_zone}"
  recurrence             = each.value.shutdown_options.start_time
  depends_on = [
    aws_eks_node_group.ondemand-group
  ]
}

resource "aws_autoscaling_schedule" "ondemand_stop_schedule" {
  for_each               = local.od_schedule_node_groups
  scheduled_action_name  = "stop-${aws_eks_node_group.ondemand-group[each.key].node_group_name}"
  autoscaling_group_name = aws_eks_node_group.ondemand-group[each.key].resources[0].autoscaling_groups[0].name
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  time_zone              = "${local.input.time_zone}"
  recurrence             = each.value.shutdown_options.stop_time
  depends_on = [
    aws_eks_node_group.ondemand-group
  ]
}


resource "aws_autoscaling_schedule" "spot_start_schedule" {
  for_each               = local.sp_schedule_node_groups
  scheduled_action_name  = "start-${aws_eks_node_group.spot-group[each.key].node_group_name}"
  autoscaling_group_name = aws_eks_node_group.spot-group[each.key].resources[0].autoscaling_groups[0].name
  min_size               = each.value.min_capacity
  max_size               = each.value.max_capacity
  desired_capacity       = each.value.desired_capacity
  time_zone              = "${local.input.time_zone}"
  recurrence             = each.value.shutdown_options.start_time
  depends_on = [
    aws_eks_node_group.spot-group
  ]
}

resource "aws_autoscaling_schedule" "spot_stop_schedule" {
  for_each               = local.sp_schedule_node_groups
  scheduled_action_name  = "stop-${aws_eks_node_group.spot-group[each.key].node_group_name}"
  autoscaling_group_name = aws_eks_node_group.spot-group[each.key].resources[0].autoscaling_groups[0].name
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  time_zone              = "${local.input.time_zone}"
  recurrence             = each.value.shutdown_options.stop_time
  depends_on = [
    aws_eks_node_group.spot-group
  ]
}
