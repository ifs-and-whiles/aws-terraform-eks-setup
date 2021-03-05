resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "${var.environment_tag}-${var.context_tag}-db-subnet-group"
  subnet_ids = aws_subnet.private.*.id

  tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-db-subnet-group"
 }
}

resource "aws_security_group" "db-security-group" {
  name        = "${var.environment_tag}-${var.context_tag}-db-security-group"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Access from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.private_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-db-security-group"
  }
}

resource "aws_db_instance" "postgreSQL" {
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "12.3"
  instance_class        = "${var.rds_instance_class}"
  name                  = "${title(var.environment_tag)}${title(var.context_tag)}Db"
  username              = var.rds_user_name
  password              = var.rds_password
  availability_zone     = var.rds_availability_zone
  copy_tags_to_snapshot = true
  db_subnet_group_name  = aws_db_subnet_group.db-subnet-group.name
  identifier            = "${var.environment_tag}-${var.context_tag}-db"
  port                  = 5432
  publicly_accessible   = false
  skip_final_snapshot   = true
  vpc_security_group_ids= [aws_security_group.db-security-group.id]
  tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-db"
  }
}

output "rds-address" {
  value = aws_db_instance.postgreSQL.address
}
