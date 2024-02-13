resource "aws_launch_template" "ecs_lt" {
 name_prefix   = "ecs-template"
 image_id      = var.ami_id
 instance_type = var.instance_type

 key_name               = var.key_name
 vpc_security_group_ids = var.security_group
 iam_instance_profile {
   name = "ecsInstanceRole"
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

 user_data = filebase64("${path.module}/ecs.sh")
}
