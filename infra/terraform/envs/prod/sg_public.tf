resource "aws_security_group" "app_public_sg" {
  name        = "${var.name_prefix}-app-public-sg"
  description = "Allow HTTP from the Internet; all egress"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-app-public-sg" }
}

output "app_public_sg_id" {
  value = aws_security_group.app_public_sg.id
}
