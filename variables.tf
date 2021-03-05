variable "region" {
     default = "eu-central-1"
}

variable "backend_bucket_name" {
    default = "test_bucket"
}

variable "availability_zones" {
    type = list
    default = [ "eu-central-1a", "eu-central-1b" ]
}


########### WORKER NODES ####################

variable "instance_type" {
     default = "t2.small"
}

variable "cluster_node_group_desired_size" {
    default = 2
}

variable "cluster_node_group_max_size" {
    default = 2
}

variable "cluster_node_group_min_size" {
    default = 1
}

########### WORKER NODES ##############

########### NETWORKING ####################

variable "nat_gateway_for_each_subnet" {
    default = false
}

variable "instance_tenancy" {
    default = "default"
}

variable "dns_support" {
    default = true
}

variable "dns_host_names" {
    default = true
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "20.0.0.0/16"
}

variable "environment_tag" {
    default = "dev"
}

variable "context_tag" {
    default = "test_app"
}

########### END NETWORKING ##############


########### S3 ######################

variable "s3_bucket_name"{
    default = "test_bucket_name"
}

########## END S3 ####################

########### RDS ######################

variable "rds_password" {
    default = "temporarypassword123"
}

variable "rds_user_name" {
    default = "test_user_name"
}

variable "rds_instance_class" {
    default = "db.t3.micro"
}

variable "rds_engine_version" {
    default = "12.3"
}

variable "rds_availability_zone" {
     default = "eu-central-1a"
}

########## END RDS ####################