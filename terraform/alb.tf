# ============================================================================
# Application Load Balancer
# ----------------------------------------------------------------------------
# 受け口は HTTP(80) のみ（最小構成のため）。本番では ACM 証明書 + HTTPS(443) を
# 推奨。
#
# パスベースルーティング:
#   /api/*        → backend ターゲットグループ（Rails）
#   それ以外       → frontend ターゲットグループ（Next.js）
# ============================================================================

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false # dev のみ
  idle_timeout               = 60

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

# ----- バックエンド用 Target Group -----
resource "aws_lb_target_group" "backend" {
  name        = "${local.name_prefix}-tg-backend"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip" # Fargate は IP モード必須
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/up"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  deregistration_delay = 30
}

# ----- フロントエンド用 Target Group -----
resource "aws_lb_target_group" "frontend" {
  name        = "${local.name_prefix}-tg-frontend"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200,304"
  }

  deregistration_delay = 30
}

# ----- HTTP リスナー -----
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # デフォルトはフロントエンドへ
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# /api/* と /up はバックエンドへ
resource "aws_lb_listener_rule" "api_to_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*", "/up"]
    }
  }
}
