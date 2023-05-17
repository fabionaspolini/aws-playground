output "ami_id" {
  value = data.aws_ami.ubuntu.id
}

output "ami_name" {
  value = data.aws_ami.ubuntu.name
}

output "ami_description" {
  value = data.aws_ami.ubuntu.description
}

output "sample_ssh_command_line" {
  value = "ssh -i ~/.ssh/aws/ec2-playground ubuntu@${aws_instance.sample.public_ip}"
}