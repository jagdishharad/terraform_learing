output "endpoint" {
  value = module.eks.endpoint
}

output "version" {
  value = module.eks.version
}

output "name" {
  value = module.eks.name
}

output "subnet_ids" {
  value = module.eks.subnet_ids
}

output "vpc_id" {
  value = module.eks.vpc_id
}

output "amd_ami_id" {
  value = module.eks.amd_ami_id
}

output "arm_ami_id" {
  value = module.eks.arm_ami_id
}

output "ml_cpu_ami_id" {
  value = module.eks.ml_cpu_ami_id
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "worker_security_group_id" {
  value = module.eks.worker_security_group_id
}

output "ondemand_group_instance_types" {
  value = module.eks.ondemand_group_instance_types
}

output "spot_group_instance_types" {
  value = module.eks.spot_group_instance_types
}

output "sys_group_instance_types" {
  value = module.eks.sys_group_instance_types
}

output "owner" {
  value = module.eks.owner
}

output "application" {
  value = module.eks.application
}
