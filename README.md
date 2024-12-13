# Multi-Tier AWS Infrastructure with Terraform

This Terraform project provisions a multi-tier AWS architecture, including a VPC, public and private subnets, a NAT gateway, security groups, an auto-scaling group, and an application load balancer.

## Features

- **VPC**: Custom Virtual Private Cloud with CIDR block.
- **Subnets**: Public and private subnets spread across availability zones.
- **Internet Gateway**: Provides internet connectivity for public subnets.
- **NAT Gateway**: Allows private subnets to access the internet securely.
- **Security Groups**: Configured for EC2 instances and load balancer with ingress and egress rules.
- **Auto Scaling Group**: Automatically scales EC2 instances.
- **Application Load Balancer**: Distributes incoming traffic across multiple instances.
- **Outputs**: Provides the DNS name of the load balancer.

## Prerequisites

- Terraform installed on your local machine.
- Access to an AWS account.
- AWS CLI configured with necessary credentials.

## Project Structure

```
.
├── main.tf          # Main Terraform configuration
├── variables.tf     # Input variable definitions
├── providers.tf     # Provider configuration
├── userdata.sh      # Script for initializing EC2 instances
└── outputs.tf       # Outputs for the project
```

## How to Use

1. **Clone the Repository**  
   Clone this repository to your local machine.

   ```bash
   git clone https://github.com/yourusername/your-repo.git
   cd your-repo
   ```

2. **Initialize Terraform**  
   Initialize the Terraform working directory.

   ```bash
   terraform init
   ```

3. **Set Variables**  
   Update the `variables.tf` file with appropriate values for your environment, such as VPC CIDR block, public and private subnet CIDRs, availability zones, and allowed SSH IP.

4. **Plan the Deployment**  
   Review the execution plan to verify the resources Terraform will create.

   ```bash
   terraform plan
   ```

5. **Apply the Configuration**  
   Apply the configuration to provision the infrastructure.

   ```bash
   terraform apply
   ```

   Confirm the action by typing `yes` when prompted.

6. **Access Outputs**  
   After successful deployment, the DNS name of the load balancer will be displayed in the output.

   ```plaintext
   load_balancer_dns = "your-load-balancer-dns-name"
   ```

7. **Clean Up**  
   To destroy the infrastructure and avoid costs, run:

   ```bash
   terraform destroy
   ```

## File Descriptions

- **main.tf**: Contains the core Terraform configuration for the AWS resources.
- **variables.tf**: Defines the input variables for dynamic configuration.
- **providers.tf**: Configures the AWS provider.
- **userdata.sh**: Initialization script for EC2 instances.
- **outputs.tf**: Defines outputs such as the load balancer DNS.

## Example Output

Once deployed, the application will be accessible via the load balancer DNS:

```plaintext
http://your-load-balancer-dns-name
```

## License

This project is licensed under the [MIT License](LICENSE).

---

Feel free to replace `yourusername` and `your-repo` with the actual GitHub repository details. Let me know if you need additional sections!
