# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "task_exec" {
  name = "${var.prefix}-role-task-exection"
  assume_role_policy = file("${path.module}/policy_document/assume_ecs_task.json")
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "task_exec" {
  name = "${var.prefix}-policy-task-exection"
  policy = templatefile("${path.module}/policy_document/iam_ecs_task.json",{
    secret_arn = aws_secretsmanager_secret.dockerhub.arn
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "task_exec" {
  role = aws_iam_role.task_exec.name
  policy_arn = aws_iam_policy.task_exec.arn
}

resource "aws_iam_role_policy_attachment" "managed_task_exec" {
  role = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
resource "aws_cloudwatch_log_group" "task" {
  name = "${var.prefix}-logs"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition
resource "aws_ecs_task_definition" "dvwa" {
  family = "${var.prefix}-task-definition"

  requires_compatibilities = [ "FARGATE" ]
  network_mode = "awsvpc"
  cpu = "1024"
  memory = "2048"
  execution_role_arn = aws_iam_role.task_exec.arn

  container_definitions = templatefile("${path.module}/task_definition/dvwa.json",{
    region = data.aws_region.current.name
    log_group_name = aws_cloudwatch_log_group.task.name
    log_stream_prefix = "${var.prefix}-app"
    secret_arn = aws_secretsmanager_secret.dockerhub.arn
  })

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http
data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "ecs" {
  name        = "${var.prefix}-ecs"
  description = "${var.prefix}-ecs"
  vpc_id      = module.vpc.vpc_id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "ecs_http_ingress" {
  security_group_id = aws_security_group.ecs.id
  type = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["${chomp(data.http.ifconfig.response_body)}/32"]
}

resource "aws_security_group_rule" "ecs_any_egress" {
  security_group_id = aws_security_group.ecs.id
  type = "egress"
  description = "Allow to Any"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service
resource "aws_ecs_service" "service" {
  name = "${var.prefix}-service"
  cluster = aws_ecs_cluster.cluster.id
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.dvwa.arn
  desired_count = 1

  network_configuration {
    security_groups = [ aws_security_group.ecs.id ]
    subnets = module.vpc.public_subnets
    assign_public_ip = true
  }
}