resource "aws_instance" "web_instance" {
  ami             = "ami-0c55b159cbfafe1f0"       # Amazon Linux 2 AMI ID
  instance_type   = "t2.micro"                    # Instance type
  key_name        = "class"               # Your actual key pair name
  security_groups = ["default"]          # Use the existing security group by its name or ID
  tags = {                                        # Tags for instance identification
    Name = "WebServer"                            # Name tag for the instance
  }

  root_block_device {                             # Configure root block storage
    volume_size = 8                               # Size of root volume (8 GB)
    volume_type = "gp2"                           # General-purpose SSD
  }
}