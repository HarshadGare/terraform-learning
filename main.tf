provider "aws" {
    region = "ap-south-1" 
}

resource "aws_instance" "example"{
    ami = "ami-0c1a7f89451184c8b"
    instance_type = "t2.micro" 
    vpc_security_group_ids = [aws_security_group.instance.id]     // <PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
    tags = {
        Name = "terraform-example"
    }
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
}

resource "aws_security_group" "instance"{
    name = "terraform-example-instance"
    ingress = [
        {
            description = "tcp from VPC"
            from_port = var.server_port
            to_port = var.server_port
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["0.0.0.0/0"]
            prefix_list_ids = []
            security_groups = []
            self = false
        }
    ]
}

variable "server_port" {
 description = "The port the server will use for HTTP requests"
 type = number
 default = 8080
}

output "public_ip" {
 value = aws_instance.example.public_ip
 description = "The public IP address of the web server"
}

resource "aws_launch_configuration" "example"{
    image_id = "ami-0c1a7f89451184c8b"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    /* 
        Every Terraform resource supports several lifecycle settings that configure how that resource is created, updated, and/or deleted. 
    */
    lifecycle {
         create_before_destroy = true
    }             
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids            // data.<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
    min_size = 2
    max_size = 10
    tag  {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }     
}

/*
A data source represents a piece of read-only information that is fetched
from the provider (in this case, AWS) every time you run Terraform.
Adding a data source to your Terraform configurations does not create
anything new; it’s just a way to query the provider’s APIs for data and to
make that data available to the rest of your Terraform code. Each Terraform
provider exposes a variety of data sources.

data "<PROVIDER>_<TYPE>" "<NAME>" {
 [CONFIG ...]
}
*/
data "aws_vpc" "default" {
 default = true
}
data "aws_subnet_ids" "default" {
 vpc_id = data.aws_vpc.default.id
}