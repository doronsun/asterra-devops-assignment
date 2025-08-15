resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+[]{}:?,.<>"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.name_prefix}/prod/db_password"
  type        = "SecureString"
  value       = random_password.db_password.result
  description = "DB password for appuser"
}

resource "aws_db_subnet_group" "pg_subnets" {
  name = "${var.name_prefix}-pg-subnets"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  tags = { Name = "${var.name_prefix}-pg-subnets" }
}

resource "aws_db_instance" "pg" {
  identifier        = "${var.name_prefix}-pg"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "geodb"
  username = "appuser"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.pg_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true

  copy_tags_to_snapshot = true
  deletion_protection   = false
  skip_final_snapshot   = true

  tags = { Name = "${var.name_prefix}-pg" }
}

output "rds_endpoint" { value = aws_db_instance.pg.address }
output "rds_port" { value = aws_db_instance.pg.port }
