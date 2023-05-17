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
  value = length(aws_instance.sample) > 0 ? "ssh -i ~/.ssh/aws/ec2-playground ubuntu@${aws_instance.sample[0].public_ip}" : null
}

# Erro ao subir pela primeira vez pois a máquina spot não foi iniciada ainda
# output "sample_spot_ssh_command_line" {
#   value = length(aws_spot_instance_request.sample_spot) > 0 ? "ssh -i ~/.ssh/aws/ec2-playground ubuntu@${aws_spot_instance_request.sample_spot[0].public_ip}" : null
# }
