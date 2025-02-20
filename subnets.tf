# Fetch available AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Public Subnets
resource "aws_subnet" "subnets_public" {
  count                   = var.total_public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, var.subnet_size, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}"
  }
}

# Create Private Subnets
resource "aws_subnet" "subnets_private" {
  count             = var.total_private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.subnet_size, count.index + var.total_public_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index + 1}"
  }
}
