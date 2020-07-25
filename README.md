# hybrid-cloud-training
This repo contains all the projects submitted during hybrid multi cloud training

##### The projects are named as tasks. The goals are as follows:

###### - Task 1 :
    1. Create the key and security group which allow the port 80
    2. Launch EC2 instance
    3. In this Ec2 instance use the key and security group which we have created in step 1
    4. Launch one Volume (EBS) and mount that volume into /var/www/html
    5. Developer have uploded the code into github repo also the repo has some images
    6. Copy the github repo code into /var/www/html
    7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable
    8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html

###### - Task 2 :
    1. Create Security group which allow the port 80
    2. Launch EC2 instance
    3. In this Ec2 instance use the existing key or provided key and security group which we have created in step 1
    4. Launch one Volume using the EFS service and attach it in your vpc, then mount that volume into /var/www/html
    5. Developer have uploded the code into github repo also the repo has some images
    6. Copy the github repo code into /var/www/html
    7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable
    8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html

###### - Task 3 :
    1. Write a Infrastructure as code using terraform, which automatically create a VPC.
    2. In that VPC we have to create 2 subnets:
        a)  public  subnet [ Accessible for Public World! ] 
        b)  private subnet [ Restricted for Public World! ]
    3. Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.
    4. Create  a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.
    5. Launch an ec2 instance which has Wordpress setup already having the security group allowing  port 80 so that our client can connect to our wordpress site.
    Also attach the key to instance for further login into it.
    6. Launch an ec2 instance which has MYSQL setup already with security group allowing  port 3306 in private subnet so that our wordpress vm can connect with the same.
    Also attach the key with the same.

    Note: Wordpress instance has to be part of public subnet so that our client can connect our site. 
    mysql instance has to be part of private  subnet so that outside world can't connect to it.
    Don't forgot to add auto ip assign and auto dns name assignment option to be enabled.

###### - Task 4 :
    1.  Write an Infrastructure as code using terraform, which automatically create a VPC.
    2.  In that VPC we have to create 2 subnets:
        1.   public  subnet [ Accessible for Public World! ] 
        2.   private subnet [ Restricted for Public World! ]
    3. Create a public facing internet gateway for connect our VPC/Network to the internet world and attach this gateway to our VPC.
    4. Create  a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.
    5.  Create a NAT gateway for connect our VPC/Network to the internet world  and attach this gateway to our VPC in the public network
    6.  Update the routing table of the private subnet, so that to access the internet it uses the nat gateway created in the public subnet
    7.  Launch an ec2 instance which has Wordpress setup already having the security group allowing  port 80 sothat our client can connect to our wordpress site. Also attach the key to instance for further login into it.
    8.  Launch an ec2 instance which has MYSQL setup already with security group allowing  port 3306 in private subnet so that our wordpress vm can connect with the same. Also attach the key with the same.

    Note: Wordpress instance has to be part of public subnet so that our client can connect our site. 
    mysql instance has to be part of private  subnet so that outside world can't connect to it.
    Don't forgot to add auto ip assign and auto dns name assignment option to be enabled.
