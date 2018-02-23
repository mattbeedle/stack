variable "name" {
  description = "The name will be used to prefix and tag the resources, e.g mycache"
}
variable "engine" {
  description = "Elasticache engine: memcached, redis, etc"
  default     = "redis"
}

variable "engine_version" {
  description = "Engine version"
  default     = "3.2.10"
}
variable "environment" {
  description = "The environment tag, e.g prod"
}

variable "vpc_id" {
  description = "The VPC ID to use"
}

variable "zone_id" {
  description = "The Route53 Zone ID where the DNS record will be created"
}

variable "security_groups" {
  description = "A list of security group IDs"
  type        = "list"
}

variable "subnet_ids" {
  description = "A list of subnet IDs"
  type        = "list"
}

variable "instance_type" {
  description = "The type of instances that the elasticache cluster will be running on"
  default     = "cache.t2.micro"
}

variable "instance_count" {
  description = "How many instances will be provisioned in the elasticache cluster"
  default     = 1
}

variable "dns_name" {
  description = "Route53 record name for the elasticache database, defaults to the name if not set"
  default     = ""
}

variable "port" {
  description = "The port at which the database listens for incoming connections"
  default     = 6379
}

resource "aws_security_group" "main" {
  name        = "${var.name}-elasticache-cluster"
  description = "Allows traffic to elasticache from other security groups"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = "${var.port}"
    to_port         = "${var.port}"
    protocol        = "TCP"
    security_groups = ["${var.security_groups}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "Elasticache cluster (${var.name})"
    Environment = "${var.environment}"
  }
}

resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.name}"
  description = "Elasticache cluster subnet group"
  subnet_ids  = ["${var.subnet_ids}"]
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.name}"
  engine               = "${var.engine}"
  engine_version = "${var.engine_version}"
  node_type            = "${var.instance_type}"
  port                 = "${var.port}"
  num_cache_nodes      = 1
  #parameter_group_name = "${var.name}"
  security_group_ids = ["${aws_security_group.main.id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.main.name}"
}


resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name    = "${coalesce(var.dns_name, var.name)}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_elasticache_cluster.main.cache_nodes.0.address}"]
}

// The cluster identifier.
output "id" {
  value = "${aws_elasticache_cluster.main.id}"
}
