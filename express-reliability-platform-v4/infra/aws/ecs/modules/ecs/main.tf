resource "aws_ecs_cluster" "this" { name = "${var.name}-cluster" }

resource "aws_security_group" "alb" {
  name = "${var.name}-alb-sg"
  vpc_id = var.vpc_id
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_lb" "this" {
  name = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = var.public_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response { content_type="text/plain" message_body="ALB is up. Add ECS services in next iteration." status_code="200" }
  }
}
