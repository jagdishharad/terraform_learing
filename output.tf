output "endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "version" {
  value = aws_eks_cluster.this.version
}

output "name" {
  value = aws_eks_cluster.this.name
}

output "subnet_ids" {
  value = aws_eks_cluster.this.vpc_config[0].subnet_ids
}

output "vpc_id" {
  value = aws_eks_cluster.this.vpc_config[0].vpc_id
}

output "amd_ami_id" {
  value = data.aws_ami.eks_worker.id
}

output "arm_ami_id" {
  value = data.aws_ami.graviton_eks_worker.id
}

output "ml_cpu_ami_id" {
  value = data.aws_ami.ml_cpu_eks_worker.id
}

output "cluster_security_group_id" {
  value = aws_security_group.cluster.id
}

output "worker_security_group_id" {
  value = aws_security_group.workers.id
}

output "ondemand_group_instance_types" {
  value = aws_eks_node_group.ondemand-group[*].instance_types
}

output "spot_group_instance_types" {
  value = aws_eks_node_group.spot-group[*].instance_types
}

output "sys_group_instance_types" {
  value = aws_eks_node_group.system-group[*].instance_types
}

output "owner" {
  value = local.file_input.tags.owner
}

output "application" {
  value = local.file_input.tags.application
}
