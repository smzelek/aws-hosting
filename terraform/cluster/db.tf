resource "aws_db_subnet_group" "default" {
  name       = "db-subnet"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "db-subnet"
  }
}

resource "random_password" "master_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.master_password.result
}

resource "aws_db_instance" "default" {
  allocated_storage            = 20
  max_allocated_storage        = 1000
  apply_immediately            = true
  storage_type                 = "gp3"
  engine                       = "postgres"
  engine_version               = "16.3"
  instance_class               = "db.t4g.micro"
  identifier                   = "cluster-db"
  username                     = "postgres"
  password                     = random_password.master_password.result
  vpc_security_group_ids       = [aws_security_group.db_sg.id]
  db_subnet_group_name         = aws_db_subnet_group.default.name
  publicly_accessible          = false
  backup_retention_period      = 7
  backup_window                = "03:00-04:00"
  maintenance_window           = "mon:04:00-mon:04:30"
  skip_final_snapshot          = true
  performance_insights_enabled = true
  storage_encrypted            = true
  parameter_group_name         = "default.postgres16"
  copy_tags_to_snapshot        = true
  multi_az                     = false
}
