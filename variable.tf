variable "aws_acnt_id" {}

variable "cluster_service_ipv4_cidr" {
  description = "service ipv4 cidr for the kubernetes cluster"
  type        = string
  default     = "10.100.0.0/16"
}

variable "cluster_create_timeout" {
  description = "Timeout value when creating the EKS cluster."
  type        = string
  default     = "30m"
}

variable "cluster_delete_timeout" {
  description = "Timeout value when deleting the EKS cluster."
  type        = string
  default     = "15m"
}

variable "wait_for_cluster_cmd" {
  description = "Custom local-exec command to execute for determining if the eks cluster is healthy. Cluster endpoint will be available as an environment variable called ENDPOINT"
  type        = string
  default     = "for i in `seq 1 60`; do if `command -v wget > /dev/null`; then wget --no-check-certificate -O - -q $ENDPOINT/healthz >/dev/null && exit 0 || true; else curl -k -s $ENDPOINT/healthz >/dev/null && exit 0 || true;fi; sleep 5; done; echo TIMEOUT && exit 1"
}

variable "wait_for_cluster_interpreter" {
  description = "Custom local-exec command line interpreter for the command to determining if the eks cluster is healthy."
  type        = list(string)
  default     = ["/bin/sh", "-c"]
}

variable "iam_path" {
  description = "If provided, all IAM roles will be created on this path."
  type        = string
  default     = "/"
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "associate_public_ip_address" {
  description = "Indicates whether or not to associate public ip address to worker nodes."
  type        = bool
  default     = false
}

variable "addons_version" {
  default = {
    1.27 = {
      "vpc-cni" = "v1.12.6-eksbuild.1" 
    }
    1.28 = {
      "vpc-cni" = "v1.14.1-eksbuild.1" 
    }
    1.29 = {
      "vpc-cni" = "v1.18.0-eksbuild.1" 
    }
  }
}

variable "autoschedule_allowed_envs" {
  description = "allowed environments for schedule autoscaling."
  type        = list(string)
  default     = [ "dev", "qa", "low" ]
}

variable "ami_account_id" {
  description = "AWS AMI account ID for worker nodes"
  type        = string
  default     = "997735487345"
}



variable "volume_type" {
  description = "volume type"
  type        = string
  default     = "gp3"
}

variable "log_group_class" {
  description = "CloudWatch Log group Log class"
  type = string
  default = "INFREQUENT_ACCESS"
}

variable "capacity_type" {
  description = "Capacity type for self managed node groups"
  type = object({
    spot      = string
    ondemand  = string
  })
  default = {
    spot      = "SPOT"
    ondemand  = "ON_DEMAND"
  }
}

variable "node_group_type" {
  description = "Node group type for worker node groups"
  type = object({
    app = string
    ml  = string
  })
  default = {
    app = "APP"
    ml = "ML"
  }
}

variable "cpu_architecture" {
  description = "CPU Architectures for self managed node groups"
  type = object({
    arm64 = string
    amd64 = string 
  })
  default = {
    arm64 = "arm64"
    amd64 = "x86_64"
  }
}


variable "ng_timeouts"{
  description = "Timeouts for self managed node groups"
  type = object({
    create  = string
    delete  = string
    update  = string
  })
  default = {
    create = "60m"
    delete = "60m"
    update = "5h"
  }
}
