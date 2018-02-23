variable "name" {
  description = "MQ Broker instance name"
}

variable "environment" {
}

variable "deployment_mode" {
}

variable "engine_type" {
  description = "The type of broker engine. Currently, Amazon MQ supports only ActiveMQ"
  default     = "ActiveMQ"
}

variable "engine_version" {
  description = "The version of the broker engine. Currently, Amazon MQ supports only 5.15.0"
  default     = "5.15.0"
}

variable "username" {
  description = "The username for the MQ Broker instance (if not specified, `var.name` will be used)"
  default     = ""
}

variable "password" {
  description = "MQ Password"
}

variable "console_access" {
  default = false
}

variable "monitoring_interval" {
  description = "Seconds between enhanced monitoring metric collection. 0 disables enhanced monitoring."
  default     = "0"
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits MQ Broker to send enhanced monitoring metrics to CloudWatch Logs. Required if monitoring_interval > 0."
  default     = ""
}

variable "apply_immediately" {
  description = "If false, apply changes during maintenance window"
  default     = true
}

variable "instance_type" {
  description = "Underlying instance type"
  default     = "mq.t2.micro"
}

variable "publicly_accessible" {
  description = "If true, the MQ Broker instance will be open to the internet"
  default     = false
}

variable "vpc_id" {
  description = "The VPC ID to use"
}

variable "ingress_allow_cidr_blocks" {
  description = "A list of CIDR blocks to allow traffic from"
  type        = "list"
  default     = []
}

variable "subnet_ids" {
  description = "A list of subnet IDs"
  type        = "list"
}

variable "security_groups" {
  description = "A list of security group IDs"
  type        = "list"
}

resource "aws_security_group" "main" {
  name        = "${var.name}-rds"
  description = "Allows traffic to MQ Broker from other security groups"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 61617
    to_port         = 61617
    protocol        = "TCP"
    security_groups = ["${var.security_groups}"]
  }

  ingress {
    from_port       = 5671
    to_port         = 5671
    protocol        = "TCP"
    security_groups = ["${var.security_groups}"]
  }

  ingress {
    from_port       = 61614
    to_port         = 61614
    protocol        = "TCP"
    security_groups = ["${var.security_groups}"]
  }

  ingress {
    from_port       = 61619
    to_port         = 61619
    protocol        = "TCP"
    security_groups = ["${var.security_groups}"]
  }

  ingress {
    from_port       = 61617
    to_port         = 61617
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
    Name = "MQ Broker (${var.name})"
  }
}

resource "aws_mq_broker" "main" {
  broker_name = "main"
  engine_type = "${var.engine_type}"
  engine_version = "${var.engine_version}"
  host_instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.main.id}"]
  subnet_ids = ["${var.subnet_ids}"]
  deployment_mode = "${var.deployment_mode}"
  user {
    username = "${var.username}"
    password = "${var.password}"
    console_access = "${var.console_access}"
  }
}
output "console_url" {
  value = "${aws_mq_broker.main.instances.0.console_url}"
}

output "ssl" {
  value = "${aws_mq_broker.main.instances.0.endpoints.0}"
}

output "amqp" {
  value = "${aws_mq_broker.main.instances.0.endpoints.1}"
}

output "stomp" {
  value = "${aws_mq_broker.main.instances.0.endpoints.2}"
}

output "mqtt" {
  value = "${aws_mq_broker.main.instances.0.endpoints.3}"
}

output "wss" {
  value = "${aws_mq_broker.main.instances.0.endpoints.4}"
}
