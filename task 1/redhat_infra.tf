provider "aws"{
	region = "ap-south-1"
	}
resource "aws_security_group" "allow_http1" {
	name = "allow_http1"
	
	ingress{
		description = "allowing tcp for http port:80"
		from_port = 81
		to_port = 81
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress{
		description = "allowing ssh"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
	
	tags = {
		Name = "allow_http81_and_ssh"
	}
}

resource "aws_instance" "web_infra"{
	ami = "ami-005956c5f0f757d37"
	instance_type = "t2.micro"
	security_groups = ["allow_http1"]
	key_name = "mykey111"
	tags = {
		Name = "webos"
	}
}

output "ip_output" {
    value = aws_instance.web_infra.public_ip
}

resource "null_resource" "config_docker" {
    provisioner "remote-exec" {
        inline = [
            "sudo yum -y install httpd",
            "sudo service httpd start",
            "sudo yum -y install docker",
            "sudo service docker start",
            "sudo docker pull vimal13/apache-webserver-php",
            "sudo docker run -dit --name webos -p 81:80 -v /web:/var/www/html vimal13/apache-webserver-php"
        ]
        connection {
            type = "ssh"
            user = "ec2-user"
            private_key = file("/home/eric/Downloads/mykey111.pem")
            host = "${aws_instance.web_infra.public_ip}"
        }
    }
    depends_on = [null_resource.to_deploy_backup]
}

resource "aws_ebs_volume" "web_infra_ebs"{
	availability_zone = aws_instance.web_infra.availability_zone
	size = 1

	tags = {
		Name = "webos_ebs"
	}
}

resource "aws_volume_attachment" "web_vol_attach" {
	device_name = "/dev/sdg"
	volume_id = aws_ebs_volume.web_infra_ebs.id
	instance_id = aws_instance.web_infra.id
	force_detach = true
}

resource "null_resource" "to_deploy_backup" {
	provisioner "remote-exec" {
		inline = [
			"sudo mkfs.ext4 /dev/sdg",
            "sudo mkdir /web",
			"sudo mount /dev/xvdg /web",
			"sudo rm -rf /web/*",
			"sudo yum -y install git",
			"sudo git clone https://github.com/sourabh-burnwal/hybrid_cloud_training /web"
		]
		connection {
			type = "ssh"
			user = "ec2-user"
			private_key = file("/home/eric/Downloads/mykey111.pem")
			host = "${aws_instance.web_infra.public_ip}"
		}
	}
}

resource "aws_s3_bucket" "image_source" {
    bucket = "mywebimages01"
    acl = "public-read"
    region = "ap-south-1"
    tags = {
        Name = "bucket for web"
    }
}
