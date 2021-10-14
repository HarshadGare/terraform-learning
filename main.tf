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