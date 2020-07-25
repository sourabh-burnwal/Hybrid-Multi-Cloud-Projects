resource "aws_security_group" "allow_http" {
	name = "allow_http"
	
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


resource "aws_s3_bucket" "image_source" {
    bucket = "mywebimages01"
    acl = "public-read"
    region = "ap-south-1"
    tags = {
        Name = "bucket for web"
    }
}

locals{
    s3_origin_id = "yours3origin"
}

resource "aws_cloudfront_distribution" "webcloudfront" {
    origin {
        domain_name = "${aws_s3_bucket.image_source.bucket_regional_domain_name}"      
        origin_id   = "${local.s3_origin_id}"
    custom_origin_config {
        http_port = 81
        https_port = 81
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
    enabled = true
    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "${local.s3_origin_id}"
        forwarded_values {
            query_string = false
        cookies {
            forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}


resource "aws_instance" "web_infra"{
	ami = "ami-005956c5f0f757d37"
	instance_type = "t2.micro"
	security_groups = ["allow_http"]
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
            "sudo yum -y install amazon-efs-utils",
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

resource "aws_efs_file_system" "efs_fs" {
    tags = {
        Name = "my-efs"
    }
    depends_on = [null_resource.config_docker]
}

resource "aws_efs_mount_target" "alpha" {
    file_system_id = "${aws_efs_file_system.efs_fs.id}"
    subnet_id      = aws_instance.web_infra.subnet_id
    security_groups = ["sg-06824d8745dad1ccb - allow-all"]
    depends_on = [aws_efs_file_system.efs_fs]
}

resource "null_resource" "to_deploy_backup" {
	depends_on = aws_efs_mount_target.alpha
	provisioner "remote-exec" {
		inline = [
			"sudo echo ${aws_efs_file_system.efs_fs.dns_name}:/var/www/html  efs defaults,_netdev    0   0>> /etc/fstab",
			"sudo mount ${aws_efs_file_system.efs_fs.dns_name}:/ /var/www/html",
			"sudo rm -rf /var/www/html/*",
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
