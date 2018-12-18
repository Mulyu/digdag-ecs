provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "mulyu-terraform"
    key = "digdag-ecs"
    region = "ap-northeast-1"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "digdag-ecs"
}

resource "aws_s3_bucket" "main" {
  bucket = "digdag-ecs"
}

data "aws_iam_policy_document" "exec-assume-role" {
  statement {
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "task-assume-role" {
  statement {
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "exec-role" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task-role" {
  statement {
    actions = [
      "logs:*",
      "s3:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "exec-role" {
  name = "digdag-ecs-exec"
  assume_role_policy = "${data.aws_iam_policy_document.exec-assume-role.json}"
}

resource "aws_iam_role_policy" "exec-role-attach" {
  policy = "${data.aws_iam_policy_document.exec-role.json}"
  role = "${aws_iam_role.exec-role.name}"
}

resource "aws_iam_role" "task-role" {
  name = "digdag-ecs-task"
  assume_role_policy = "${data.aws_iam_policy_document.task-assume-role.json}"
}

resource "aws_iam_role_policy" "task-role-attach" {
  policy = "${data.aws_iam_policy_document.task-role.json}"
  role = "${aws_iam_role.task-role.name}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "main" {
  cidr_block = "10.10.10.0/24"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "main" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
}

resource "aws_route_table_association" "main" {
  route_table_id = "${aws_route_table.main.id}"
  subnet_id = "${aws_subnet.main.id}"
}

resource "aws_cloudwatch_log_group" "main" {
  name = "example"
}