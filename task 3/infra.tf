provider "aws" {
    region = "ap-south-1"
}



resource "aws_vpc" "my_vpc" {
    cidr_block  = "192.168.0.0/16"
    instance_tenancy = "default"
    
    tags = {
        Name = "eric-vpc"
    }
}



resource "aws_subnet" "eric_subnet_private" {
    depends_on = [aws_vpc.my_vpc]
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "192.168.0.0/24"
    availability_zone = "ap-south-1b"
    tags = {
        Name = "subnet-private"
    }
}



resource "aws_subnet" "eric_subnet_public" {
    depends_on = [aws_vpc.my_vpc]
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "subnet-public"
    }
}



resource "aws_security_group" "for_wp" {
  depends_on = [aws_vpc.my_vpc]
  name        = "wp-sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wp-sg"
  }
}



resource "aws_security_group" "for_mysql" {
  depends_on = [aws_security_group.for_wp]
  name        = "mysql-sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
   from_port = 3306
   to_port = 3306
   protocol = "tcp"
   security_groups = ["${aws_security_group.for_wp.id}"]
  }
  
  ingress {
   from_port = 8888
   to_port = 8888
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   security_groups = ["${aws_security_group.for_wp.id}"]
  }
}



resource "aws_internet_gateway" "eric_ig" {
  depends_on = [aws_vpc.my_vpc]
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "eric-ig"
  }
}



resource "aws_route_table" "wp_rt" {
  depends_on = [aws_internet_gateway.eric_ig]
  vpc_id = aws_vpc.my_vpc.id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eric_ig.id
  }
  tags = {
    Name = "wp-rt"
  }
}



resource "aws_route_table_association" "rt_a" {
  subnet_id      = aws_subnet.eric_subnet_public.id
  route_table_id = aws_route_table.wp_rt.id
}



resource "aws_instance"  "mysql_db" {
  depends_on = [aws_route_table.wp_rt]
  ami = "ami-092615e9c8a81d118"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.eric_subnet_private.id
  vpc_security_group_ids = ["${aws_security_group.for_mysql.id}"]
  key_name = "mykey111"
  user_data = <<-EOF
        #!/bin/bash
        sudo docker run -dit -p 8888:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=wpdb -e MYSQL_USER=eric -e MYSQL_PASSWORD=password mysql:5.6
  
    EOF
}



resource "aws_instance" "wordpress" {
    depends_on = [aws_instance.mysql_db]
    ami           = "ami-092615e9c8a81d118"
    instance_type = "t2.micro"
    key_name       = "mykey111"
    vpc_security_group_ids = [ aws_security_group.for_wp.id ]
    subnet_id = aws_subnet.eric_subnet_public.id
}




resource "null_resource" "start_wordpress"{
    provisioner "remote-exec" {
        inline = [
            "sudo su << EOF",
            "sudo docker run -dit -e WORDPRESS_DB_HOST=${aws_instance.mysql_db.private_ip}:8888 -e WORDPRESS_DB_USER=eric -e WORDPRESS_DB_PASSWORD=password -e WORDPRESS_DB_NAME=wpdb -p 80:80 --name wp wordpress:4.8-apache",
            "sudo sleep 120",
            "sudo docker start wp"
        EOF
        ]
        
        connection {
            type     = "ssh"
            user     = "ec2-user"
            private_key = file("/home/eric/Downloads/mykey111.pem")
            host     = "${aws_instance.wordpress.public_ip}" 
        }
    }
    depends_on = [aws_instance.wordpress]
}

output "WordPressIP" {
       value = "${aws_instance.wordpress.public_ip}"
}



