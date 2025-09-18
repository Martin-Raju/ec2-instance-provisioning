
aws_region                               = "us-east-1"
ami_id                                   = "ami-0b09ffb6d8b58ca91"
key_name                                 = "test01"
environment                              = "dev"
asg_min_size                             = 1
asg_max_size                             = 4
asg_desired_capacity                     = 2
instance_types                           = ["t3.micro", "t3a.micro", "t2.micro", "t2a.micro", "t3.small", "t3a.small"]
default_instance_type                    = "t3.micro"
on_demand_percentage_above_base_capacity = 0
cpu_target_value                         = 50
