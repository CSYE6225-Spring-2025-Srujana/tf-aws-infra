# Create a public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Create a route to the internet for the public route table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_assoc" {
  count          = var.total_public_subnets
  subnet_id      = element(aws_subnet.subnets_public[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

# Create a private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_assoc" {
  count          = var.total_private_subnets
  subnet_id      = element(aws_subnet.subnets_private[*].id, count.index)
  route_table_id = aws_route_table.private_rt.id
}
