###################### VPC #################################

output "vpc-id" {
    value = aws_vpc.terraform_vpc.id
  
}

###################### IG #################################

output "ig-id" {
    value = aws_internet_gateway.igw.id
  
}

###################### Subnets #################################

output "subnet_ids" {
  value = { for k, v in aws_subnet.subnets : k => v.id }
}

###################### SG #################################

output "sg-id" {
    value = aws_security_group.SG.id
  
}

###################### Instances #################################

output "instance_ids" {
    value = { for k, v in aws_instance.instances : k => v.id}
  
}

###################### Target Group #################################

output "TG-ID" {
    value = aws_lb_target_group.TG.id
  
}

###################### alb ################################

output "alb-dns" {
    value = aws_lb.alb.dns_name
  
}