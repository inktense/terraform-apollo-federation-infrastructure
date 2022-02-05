# Main specification for the ALB.
resource "aws_lb" "swapi_apollo_federation_alb" {
  name               = "swapi-apollo-federation-alb"
  internal           = false
  load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [
      aws_default_subnet.default_az1.id,
      aws_default_subnet.default_az2.id,
  ]

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.bucket
#     prefix  = "swapi-apollo-federation-alb"
#     enabled = true
#   }
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
  port              = "80" // Allowing traffic for HTTP, meaning port 80.
  protocol          = "HTTP" // Choosing HTTP to not set up certificate 

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
    path_pattern {
      values = ["/static/*"]
    }
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
  target_id        = "arn:aws:lambda:eu-west-2:635567262396:function:swapi-apollo-federation-gateway-dev-lambda"
  depends_on       = [aws_lambda_permission.with_lb]
}


# Using the AWS defult provided VPC & subnets
resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-west-2a"

  tags = {
    Name = "Default subnet for eu-west-2a"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "eu-west-2b"

  tags = {
    Name = "Default subnet for eu-west-2b"
  }
}
#--------------------------------------------------------------
# Security Group
#--------------------------------------------------------------
resource "aws_security_group" "http" {
  name        = "allow_http"
  description = "Allow HTTP"

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
  }

  tags = {
    Name = "Allow HTTP"
  }
}
