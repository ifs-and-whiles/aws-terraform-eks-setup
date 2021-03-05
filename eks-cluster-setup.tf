/*
  Cluster setup
*/
resource "aws_eks_cluster" "eks-cluster" {
  name     = "${var.environment_tag}-${var.context_tag}-cluster"
  role_arn = aws_iam_role.cluster-role.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.private.*.id, aws_subnet.public.*.id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy
  ]



  tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-cluster"
    }
}

output "endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-cluster.certificate_authority[0].data
}

resource "aws_security_group_rule" "load_balancer_access_rule" {
  type              = "ingress"
  description     = "Access from load balancer"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  source_security_group_id = aws_security_group.cluster_load_balancer_security_group.id
  security_group_id = aws_eks_cluster.eks-cluster.vpc_config[0].cluster_security_group_id
}


resource "aws_security_group" "cluster_load_balancer_security_group" {
  name        = "${var.environment_tag}-${var.context_tag}-cluster-load-balancer-security-group"
  description = "Allow HTTP and HTTPS inbound traffic from the internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow ingress on port 443 from 0.0.0.0/0"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ingress on port 80 from 0.0.0.0/0"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
        Name = "${var.environment_tag}-${var.context_tag}-cluster-load-balancer-security-group"
    }
}

resource "aws_iam_role" "cluster-role" {
  name = "${var.environment_tag}-${var.context_tag}-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-cluster-role"
    }
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy"{
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    role       = aws_iam_role.cluster-role.name
}




/*
  End cluster setup
*/


/*
  Node group setup
*/

resource "aws_eks_node_group" "cluster-node-group" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "${var.environment_tag}-${var.context_tag}-cluster-node-group"
  node_role_arn   = aws_iam_role.cluster-node-group.arn
  subnet_ids      = aws_subnet.private.*.id
  disk_size       = 20
  instance_types  = ["${var.instance_type}"]
  ami_type        = "AL2_x86_64"


  scaling_config {
    desired_size = var.cluster_node_group_desired_size
    max_size     = var.cluster_node_group_max_size
    min_size     = var.cluster_node_group_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-node-group-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.cluster-node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.cluster-node-group-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-cluster-node-group"
    }
}

resource "aws_iam_role" "cluster-node-group" {
  name = "${var.environment_tag}-${var.context_tag}-cluster-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = {
        environment = var.environment_tag,
        context = var.context_tag,
        Name = "${var.environment_tag}-${var.context_tag}-cluster-node-group"
    }
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cluster-node-group.name
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cluster-node-group.name
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cluster-node-group.name
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonSQSFullAccessPolicy"{
    policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
    role       = aws_iam_role.cluster-node-group.name
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonSNSFullAccessPolicy"{
    policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
    role       = aws_iam_role.cluster-node-group.name
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonS3FullAccess"{
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    role       = aws_iam_role.cluster-node-group.name
}

resource "aws_iam_role_policy_attachment" "cluster-node-group-AmazonTextractFullAccess"{
    policy_arn = "arn:aws:iam::aws:policy/AmazonTextractFullAccess"
    role       = aws_iam_role.cluster-node-group.name
}

/*
  End node group setup
*/