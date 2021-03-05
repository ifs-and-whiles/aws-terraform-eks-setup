# Create VPC/Subnet/Security Group/Network ACL

locals {
  availability_zones_count = length(var.availability_zones)

  nat_gateways_count = var.nat_gateway_for_each_subnet ? local.availability_zones_count : 1

  cidr_new_bits = 4

  private_cidrs = [for az in tolist(var.availability_zones):
    cidrsubnet(var.vpc_cidr, local.cidr_new_bits, index(var.availability_zones, az) + local.subnet_netnum_factor.private)]

  public_cidrs = [for az in tolist(var.availability_zones):
    cidrsubnet(var.vpc_cidr, local.cidr_new_bits, index(var.availability_zones, az) + local.subnet_netnum_factor.public)]

  subnet_netnum_factor = {
    public  = 0
    private = local.availability_zones_count
  }
  
}

# create the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy 
  enable_dns_support   = var.dns_support 
  enable_dns_hostnames = var.dns_host_names
  tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-vpc"
 }

} 

# Create the Internet Gateway
resource "aws_internet_gateway" "vpc-internet-gateway" {
 vpc_id = aws_vpc.vpc.id
 tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-vpc-internet-gateway"
 }
}


# Create Public Elastic IP addresses for NAT gateways 
resource "aws_eip" "nat" {
  count = local.nat_gateways_count
  vpc = true
  tags = {
      environment = var.environment_tag,
      context = var.context_tag,
      Name = "${var.environment_tag}-${var.context_tag}-vpc-${var.availability_zones[count.index]}"
  }
}


/*
  NAT setup
*/

resource "aws_nat_gateway" "nat" {
  count         = local.nat_gateways_count

  subnet_id     = local.nat_gateways_count == 1 ? aws_subnet.public[0].id : aws_subnet.public[count.index].id

  allocation_id = aws_eip.nat[count.index].id
  tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-vpc-nat-gateway"
  }
}

/*
  END NAT setup
*/


/*
  Subnets setup
*/

# create the Public Subnets

resource "aws_subnet" "public" {
  count                   = local.availability_zones_count 
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[count.index]
  tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-vpc-subnet-public-${var.availability_zones[count.index]}",
    "kubernetes.io/cluster/${var.environment_tag}-${var.context_tag}-cluster" = "shared",
    "kubernetes.io/role/elb" = 1
    Tier = "public"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.vpc-internet-gateway.id
    }

    tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-route-table-public-subnet"
    }
}

resource "aws_route_table_association" "public" {
    count = local.availability_zones_count
    subnet_id =  aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}


# create the Private Subnet

resource "aws_subnet" "private" {
  count                   = local.availability_zones_count 
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[count.index]

  tags = {
    environment = var.environment_tag,
    context = var.context_tag,
    Name = "${var.environment_tag}-${var.context_tag}-vpc-subnet-private-${var.availability_zones[count.index]}",
    "kubernetes.io/role/internal-elb" = 1,
    "kubernetes.io/cluster/${var.environment_tag}-${var.context_tag}-cluster" = "shared"
    Tier = "private"
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.vpc.id
    count = local.nat_gateways_count
    tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-route-table-private-subnet"
    }
}

resource "aws_route" "private" {
  count = local.nat_gateways_count

  route_table_id         = local.nat_gateways_count == 1 ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_gateways_count == 1 ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private" {
    count = local.availability_zones_count
    subnet_id =  aws_subnet.private[count.index].id
    route_table_id = local.nat_gateways_count == 1 ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}


/*
  End Subnets setup
*/

