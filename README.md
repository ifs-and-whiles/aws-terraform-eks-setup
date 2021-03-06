# Introduction
The repository demonstrates AWS EKS cluster, PostgreSQL RDS database and S3 bucket setup using Terraform. Terraform state is stored on AWS S3.

Setup based on [Public and private subnets configuration](https://docs.aws.amazon.com/eks/latest/userguide/create-public-private-vpc.html). 

> Public and private subnets – This VPC has at least two public and two private subnets. One public and one private subnet are deployed to the same Availability Zone. 
  The other public and private subnets are deployed to a second Availability Zone in the same Region. 
  We recommend this option for all production deployments. 
  This option allows you to deploy your nodes to private subnets and allows Kubernetes to deploy load balancers to the public subnets that can load balance traffic to pods running on nodes in the private subnets.
  
>  Public IP addresses are automatically assigned to resources deployed to one of the public subnets, but public IP addresses are not assigned to any resources deployed to the private subnets. 
  The nodes in private subnets can communicate with the cluster and other AWS services, and pods can communicate outbound to the internet through a NAT gateway that is deployed in each Availability Zone. 
  A security group is deployed that denies all inbound traffic and allows all outbound traffic. 
  The subnets are tagged so that Kubernetes is able to deploy load balancers to them.
>
> -- <cite>https://docs.aws.amazon.com/eks/latest/userguide/create-public-private-vpc.html</cite>


### Before you start

- [Install terraform](https://releases.hashicorp.com/terraform/0.11.13/)
- [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html)
- [AWS iam authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
- Configure AWS credential in order to connect to S3 from Terraform. You can configure backend.tf file and pass credentials directly. 


### Setup
```
$ git clone https://github.com/ifs-and-whiles/aws-terraform-eks-setup.git
$ cd aws-terraform-eks-setup
```

#### Initialize Terraform

The terraform init command is used to initialize a working directory containing Terraform configuration files.

```
$ terraform init
```

#### Configure variables

In order to define cluster settings please modify variables.tf file.

#### Terraform Plan

The terraform plan command is used to create an execution plan. 
This command is a convenient way to check whether the execution plan for a set of changes matches your expectations without making any changes to real resources or to the state. 

```
$ terraform plan
```

#### Apply changes

The terraform apply command is used to apply the changes required to reach the desired state of the configuration, or the pre-determined set of actions generated by a terraform plan execution plan.

```
$ terraform apply
```

#### Configure kubectl
```
$ aws eks --region <AWS-REGION> update-kubeconfig --name <CLUSTER-NAME>
```
**Note:-** If AWS CLI and AWS iam authenticator setup correctly, above command should setup kubeconfig file in ~/.kube/config in your system.

#### Verify eks connection

You should be able to connect to your eks cluster via kubectl
