# 1. Web Security Group (Public facing)
resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-web-sg"
  description = "Allow inbound HTTP and SSH"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "web_outbound" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 2. Internal Security Group (For DB & Cache)
resource "aws_security_group" "internal_sg" {
  name        = "${local.name_prefix}-internal-sg"
  description = "Allow traffic only from Web Tier"
  vpc_id      = aws_vpc.main.id
}

# Allow Postgres port from Web SG
resource "aws_vpc_security_group_ingress_rule" "internal_postgres" {
  security_group_id            = aws_security_group.internal_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

# Allow Redis port from Web SG
resource "aws_vpc_security_group_ingress_rule" "internal_redis" {
  security_group_id            = aws_security_group.internal_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id
  from_port                    = 6379
  ip_protocol                  = "tcp"
  to_port                      = 6379
}

# SSH Access from Web SG (Optional, good for Bastion host setups)
resource "aws_vpc_security_group_ingress_rule" "internal_ssh" {
  security_group_id            = aws_security_group.internal_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "internal_outbound" {
  security_group_id = aws_security_group.internal_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}