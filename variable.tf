###################### Subnets #################################

variable "subnets_value" {
    type = map(object({
        cidr_block = string
        availability_zone = string
    }))

    default = {
        subnet-1 = {cidr_block = "10.0.1.0/24" , availability_zone = "ap-south-1a"}
        subnet-2 = {cidr_block = "10.0.2.0/24" , availability_zone = "ap-south-1b"}
}
}




###################### Subnets #################################