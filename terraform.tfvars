
aws_region                               = "us-east-1"
ami_id                                   = "ami-0b09ffb6d8b58ca91"
key_name                                 = "test01"
environment                              = "dev"
asg_min_size                             = 1
asg_max_size                             = 8
asg_desired_capacity                     = 2
on_demand_percentage_above_base_capacity = 40
cpu_target_value                         = 50
spot_max_price                           = ".06"
instance_type_p1                         = "t3.small"
instance_type_p2                         = "t3a.small"
instance_type_p3                         = "t3.medium"
instance_type_p4                         = "t3a.medium"