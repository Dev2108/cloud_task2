

resource "aws_security_group" "allow_ssh" {
  name        = "my_SG"
  description = "SSH ,HTTP and NFS"
ingress {
		description = "SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [ "0.0.0.0/0" ]
	}
  
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
		description = "NFS"
		from_port   = 2049
		to_port     = 2049
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
    Name = "my_SG"
  }
}



resource "aws_instance" "thor" {
 

    ami = "ami-0447a12f28fddb066"
    instance_type = "t2.micro"
     key_name  ="mykey1"
     availability_zone="ap-south-1a"
     security_groups = ["my_SG"]
     

    connection {
      type  = "ssh"
       user = "ec2-user"
      private_key = file("C:/Users/Prashant/Downloads/mykey1.pem")
       host = aws_instance.thor.public_ip
   }


 provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
 
    ]
  }

  tags = {
          Name = "task2os"
  }
}
// Launching a EFS Storage
resource "aws_efs_file_system" "mynfs" {
	depends_on =  [ aws_security_group.allow_ssh , aws_instance.thor ] 
	creation_token = "nfs"




	tags = {
		Name = "mynfs"
	}

}

// Mounting the EFS volume onto the VPC's Subnet


resource "aws_efs_mount_target" "tg" {
	depends_on =  [ aws_efs_file_system.mynfs,] 
	file_system_id = aws_efs_file_system.mynfs.id
	subnet_id      = aws_instance.thor.subnet_id
	security_groups = ["${aws_security_group.allow_ssh.id}"]
}

output "task-instance-ip" {
	value = aws_instance.thor.public_ip
}




//Connect to instance again
resource "null_resource" "reconnect"  {


	depends_on = [ aws_efs_mount_target.tg,]

	connection {
		type     = "ssh"
		user     = "ec2-user"
		private_key = file("C:/Users/Prashant/Downloads/mykey1.pem") 
		host     = aws_instance.thor.public_ip
	}	
	
// Mounting the EFS on the folder and pulling the code from github
 provisioner "remote-exec" {
      inline = [
        "sudo echo ${aws_efs_file_system.mynfs.dns_name}:/var/www/html efs defaults,_netdev 0 0 >> sudo /etc/fstab",
        "sudo mount  ${aws_efs_file_system.mynfs.dns_name}:/  /var/www/html",
           "sudo rm -rf /var/www/html/*",
		"sudo git clone https://github.com/Dev2108/cloud_task2.git  /var/www/html/"
    ]
  }
}


