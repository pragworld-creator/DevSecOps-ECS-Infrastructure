# resource "aws_ecr_repository" "my_project_repo" {
#   name                 = "my-ecr-repo"
#   image_tag_mutability = "IMMUTABLE"
#   force_delete         = true

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   encryption_configuration {
#     encryption_type = "KMS"
#     # kms_key       = if you have any, otherwise not important
#   }

#   tags = {
#     Environment = "dev"
#     Project     = "anything-you-name-here"
#   }
# }


# # This time I have created repository through AWS CLI instead of this ecr.tf file configuration - 
# # aws ecr create-repository --repository-name my-ecr-repo --region eu-west-1

# # Command used to authenticate Docker to AWS ECR - 
# # aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-1.amazonaws.com
