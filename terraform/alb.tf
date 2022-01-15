# Main specification for the ALB.
resource "aws_lb" "swapi_apollo_federation_alb" {
  name               = "swapi-apollo-federation-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "swapi-apollo-federation-alb"
    enabled = true
  }
}

# Target group for ALB is the Apollo Federation Gateway Lambda.
# Target groups allow us to create an abstraction layer between the load balancer and our servers. 
# Which is necessary for our ALB to work.
resource "aws_lb_target_group" "gateway_lambda" {
  name        = "swapi-apollo-federation-alb-tg"
  target_type = "lambda"
}

# After the load balancer is created in the given network we’ll need to setup a listener 
# to tell it what types of requests we want to listen to.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.swapi_apollo_federation_alb.arn
  port              = "443" // Allowing traffic for HTTPS, meaning port 443.
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway_lambda.arn
  }
}

# Interpreting listeners as external to the load balancer and listener rules internal. 
# With listeners traffic can hit your ALB, but without rules it cannot be processed or forwarded etc.
resource "aws_lb_listener_rule" "static" {
  listener_arn = "${aws_lb_listener.http.arn}"
  priority     = 100
# Forwarding all traffic on the /static route to our “target group”.
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.gateway_lambda.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/static/*"]
  }
}

# Attaching the Lambda function to the target group.
resource "aws_lambda_permission" "with_lb" {
  statement_id  = "AllowExecutionFromlb"
  action        = "lambda:InvokeFunction"
  function_name = "swapi-apollo-federation-gateway-dev-lambda"
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.gateway_lambda.arn
}


resource "aws_lb_target_group_attachment" "lambda_attachment" {
  target_group_arn = aws_lb_target_group.gateway_lambda.arn
  target_id        = ""
  depends_on       = [aws_lambda_permission.with_lb]
}
