
aws_region                               = "us-east-1"
ami_id                                   = "ami-0b09ffb6d8b58ca91"
key_name                                 = "test01"
environment                              = "dev"
asg_min_size                             = 1
asg_max_size                             = 5
asg_desired_capacity                     = 2
on_demand_percentage_above_base_capacity = 40
cpu_target_value                         = 40
