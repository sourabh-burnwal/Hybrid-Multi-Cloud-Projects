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


resource "aws_subnet" "bastion_subnet" {
    depends_on = [aws_vpc.my_vpc]
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "subnet-bastion"
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
  depends_on = [aws_security_group.for_bastion]
  name        = "mysql-sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
   from_port = 3306
   to_port = 3306
   protocol = "tcp"
   security_groups = ["${aws_security_group.for_wp.id}"]
  }
  
  ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
   security_groups = ["${aws_security_group.for_bastion.id}"]
  }
  
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   security_groups = ["${aws_security_group.for_wp.id}"]
  }
  
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   security_groups = ["${aws_security_group.for_bastion.id}"]
  }
  
}

resource "aws_security_group" "for_bastion" {
  depends_on = [aws_security_group.for_wp]
  name        = "bastion-sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
   from_port = 22
   to_port = 22
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_internet_gateway" "eric_ig" {
  depends_on = [aws_security_group.for_bastion]
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


resource "aws_eip" "eip_nat"{
    vpc = "true"
    depends_on = [aws_internet_gateway.eric_ig]
}


resource "aws_route_table" "bastion_rt" {
    depends_on = [aws_internet_gateway.eric_ig]
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.eric_ig.id
    }
    tags = {
        Name = "bastion-rt"
    }
}


resource "aws_route_table_association" "rt_b" {
  subnet_id      = aws_subnet.bastion_subnet.id
  route_table_id = aws_route_table.bastion_rt.id
  depends_on = [aws_route_table.bastion_rt]
}


resource "aws_nat_gateway" "bastion_nat" {
  depends_on = [aws_eip.eip_nat]
  allocation_id = "${aws_eip.eip_nat.id}"
  subnet_id     = "${aws_subnet.bastion_subnet.id}"
}


resource "aws_route_table" "mysql_rt" {
    depends_on = [aws_nat_gateway.bastion_nat]
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.bastion_nat.id
    }
    tags = {
        Name = "bastion-rt"
    }
}


resource "aws_route_table_association" "rt_c" {
  depends_on = [aws_route_table.mysql_rt]
  subnet_id      = aws_subnet.eric_subnet_private.id
  route_table_id = aws_route_table.mysql_rt.id
}


resource "aws_instance" "bastion_host" {
    depends_on = [aws_route_table_association.rt_c]
    ami           = "ami-0732b62d310b80e97"
    instance_type = "t2.micro"
    key_name       = "mykey111"
    vpc_security_group_ids = [ aws_security_group.for_bastion.id ]
    subnet_id = aws_subnet.bastion_subnet.id
}


resource "aws_instance"  "mysql_db" {
  depends_on = [aws_instance.bastion_host]
  ami = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.eric_subnet_private.id
  vpc_security_group_ids = ["${aws_security_group.for_mysql.id}"]
  key_name = "mykey111"
}


resource "aws_instance" "wordpress" {
    depends_on = [aws_instance.mysql_db]
    ami           = "ami-0979674e4a8c6ea0c"
    instance_type = "t2.micro"
    key_name       = "mykey111"
    vpc_security_group_ids = [ aws_security_group.for_wp.id ]
    subnet_id = aws_subnet.eric_subnet_public.id
    
}


output "WordPressIP" {
       value = "${aws_instance.wordpress.public_ip}"
}

output "bastionIP" {
       value = "${aws_instance.bastion_host.public_ip}"
}

output "mysql_privateIP" {
       value = "${aws_instance.mysql_db.private_ip}"
}
