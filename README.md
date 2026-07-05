<img width="1919" height="1199" alt="Screenshot 2026-07-06 043319" src="https://github.com/user-attachments/assets/14e3dcc4-9430-47b0-afa1-b3bd427b5c87" />


## DevSecOps Secure AWS-ECS Infrastructure

## Project Overview ----->

This project is a cloud based DevSecOps portfolio explaining an enterprise-grade AWS architecture. It is a web application which is highly available, fault-tolerant, and securely isolated compute environment provisioned entirely through Terraform (Infrastructure as Code).

The architecture describs an end-to-end secure Infrastructure, enforcing zero-trust networking, Principle of Least Privilege (PoLP) via IAM and many other AWS compliacnce practices.


## Architecture Design ------>

The infrastructure is designed with a strict physical separation of public incomming requests and private compute:
1. **The Network Foundation (VPC):** Custom `10.0.0.0/16` VPC spanning 2 Availability Zones.
2. **The Public Subnets:** Houses the Application Load Balancer (ALB) acting as the single point of public ingress.
3. **The Private Subnets:** Houses the AWS ECS cluster running on serverless Fargate. These subnets have no direct internet access.
4. **AWS PrivateLink:** VPC Endpoints established for Amazon ECR, S3 and CloudWatch, ensuring the container agent pulls images and pushes logs over the AWS secure private tunnel.


## Security & Identity Guardrails ------>

- **Security Group Chaining:** The ECS tasks ignore all network traffic except explicit HTTP requests originating directly from the ALB's Security Group. The VPC Endpoints strictly accept Port 443 traffic from the ECS Security Group.

- **Decoupled IAM Roles(Seperation Of Duties):** 
  - Task Execution Role: Grants the underlying ECS Agent permission to authenticate with ECR and stream to CloudWatch.
  - Task Role: Grants the actual container runtime permissions to interact with AWS services (ensuring logical separation of duties).

- **Immutable Supply Chain:** Amazon ECR is configured with image tag immutability to prevent accidental overwrites from other developers push.


## Technology Stack ----->

* Containerization: Docker, Nginx (Alpine)
* Cloud Orchestration: Amazon ECS, AWS Fargate
* Container Registry: Amazon ECR
* Infrastructure as Code (IaC): Terraform
* Networking: AWS VPC, ALB, NAT Gateway, AWS PrivateLink
* Frontend: HTML, CSS

## Important Points ----->

* This time I have created repository through AWS CLI instead of ecr.tf file configuration - aws ecr create-repository --repository-name my-ecr-repo --region eu-west-1
* Command used to authenticate Docker to AWS ECR - aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-1.amazonaws.com

