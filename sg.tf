resource "aws_security_group" "cluster" {
  name_prefix           = "${local.cluster_sg_name}-"
  description           = "EKS cluster security group."
  vpc_id                = local.input.vpc_id
  
  dynamic "ingress" {
    for_each = local.file_input.cluster_security_group.ingress
    content {
      cidr_blocks      = lookup(ingress.value, "allowed_cidr", null)
      description      = lookup(ingress.value, "description", null)
      from_port        = lookup(ingress.value, "port", null)
      to_port          = lookup(ingress.value, "port", null)
      protocol         = lookup(ingress.value, "protocol", null)
    }
  }
  tags                 = merge(
    local.selected_tags,
    {
      "Name"                                        = "${local.cluster_sg_name}"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
  )
}

resource "aws_security_group_rule" "cluster_egress" {
  description               = "Allow cluster egress access to the Internet."
  protocol                  = "-1"
  security_group_id         = local.cluster_security_group_id
  cidr_blocks               =  ["0.0.0.0/0"]
  from_port                 = 0
  to_port                   = 0
  type                      = "egress"
  depends_on = [
    aws_security_group.cluster,
  ]
}

resource "aws_security_group" "workers" {
  name_prefix = "${local.worker_sg_name}-"
  description = "Security group for all nodes in the cluster."
  vpc_id      = local.input.vpc_id
  tags = merge(
    local.selected_tags,
    {
      "Name"                                        = "${local.worker_sg_name}"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "workers_egress_internet" {
  description       = "Allow nodes all egress to the Internet."
  protocol          = "-1"
  security_group_id = local.worker_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "workers_ingress_self" {
  description              = "Allow node to communicate with each other."
  protocol                 = "-1"
  security_group_id        = local.worker_security_group_id
  source_security_group_id = local.worker_security_group_id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster" {
  description              = "Allow workers pods to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = local.worker_security_group_id
  source_security_group_id = local.cluster_security_group_id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_kubelet" {
  description              = "Allow workers Kubelets to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = local.worker_security_group_id
  source_security_group_id = local.cluster_security_group_id
  from_port                = 10250
  to_port                  = 10250
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id        = local.worker_security_group_id
  source_security_group_id = local.cluster_security_group_id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_primary" {
  description              = "Allow pods running on workers to receive communication from cluster primary security group (e.g. Fargate pods)."
  protocol                 = "all"
  security_group_id        = local.worker_security_group_id
  source_security_group_id = local.cluster_primary_security_group_id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_primary_ingress_workers" {
  description              = "Allow pods running on workers to send communication to cluster primary security group (e.g. Fargate pods)."
  protocol                 = "all"
  security_group_id        = local.cluster_primary_security_group_id
  source_security_group_id = local.worker_security_group_id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}
