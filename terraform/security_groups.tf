# ============================================================================
# セキュリティグループ
# ----------------------------------------------------------------------------
# 通信フロー：
#   インターネット → ALB(80/443) → ECS Backend(3000), Frontend(3000)
#   ECS → RDS(5432), Redis(6379)
# ============================================================================

# ----- ALB：80/443 をインターネットから受ける -----
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-sg-alb"
  description = "ALB ingress from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.alb_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-alb"
  }
}

# ----- ECS タスク：ALB からのみ受ける -----
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name_prefix}-sg-ecs"
  description = "ECS tasks accept traffic only from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From ALB to backend (port 3000)"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-ecs"
  }
}

# ----- RDS：ECS タスクからのみ受ける -----
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-sg-rds"
  description = "RDS accepts traffic only from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From ECS tasks to PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-rds"
  }
}

# ----- ElastiCache Redis：ECS タスクからのみ受ける -----
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-sg-redis"
  description = "Redis accepts traffic only from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From ECS tasks to Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-sg-redis"
  }
}
