# AWS Infrastructure with Terraform

This project sets up a comprehensive AWS infrastructure using Terraform, including a VPC with public and private subnets, NAT Gateway, security groups, and an S3 bucket for Terraform state management with GitHub Actions OIDC provider integration.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or later)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions

## Project Structure

```
.
├── main.tf              # Main Terraform configuration (AWS provider, S3 bucket)
├── backend.tf           # S3 backend configuration
├── variables.tf         # Input variables
├── outputs.tf           # Outputs of the infrastructure
├── vpc.tf               # VPC resource
├── subnets.tf           # Public and private subnets
├── internet_gateway.tf  # Internet Gateway for public subnets
├── nat_gateway.tf       # NAT Gateway for private subnets
├── route_tables.tf      # Route tables for public and private subnets
├── security_groups.tf   # Security groups for bastion and internal resources
├── oidc_provider.tf     # GitHub Actions OIDC provider configuration
├── roles.tf             # IAM role for GitHub Actions
└── README.md            # This file
```

## Backend Configuration

The project uses an S3 backend for storing Terraform state. The backend configuration is in `backend.tf`, but it's intended to be overridden during initialization.

Create a `dev-backend-config.tfvars` file (or a name of your choice) with your backend settings.

Example `dev-backend-config.tfvars`:

```hcl
bucket       = "my-terraform-state-bucket"
key          = "dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

Then initialize Terraform:

```bash
terraform init -backend-config="dev-backend-config.tfvars"
```

## Components

### Networking

- **VPC**: Creates a Virtual Private Cloud (VPC) to host the infrastructure.
- **Subnets**:
  - **Public Subnets**: For resources that need to be accessible from the internet, like load balancers or bastion hosts.
  - **Private Subnets**: For resources that shouldn't be directly accessible from the internet, like application servers or databases.
- **Internet Gateway**: Provides internet access to the public subnets.
- **NAT Gateway**: Allows resources in the private subnets to access the internet for updates and patches, without being exposed to incoming connections.
- **Route Tables**: Manages routing for public and private subnets.

### Security

- **Security Groups**:
  - **Bastion SG**: A security group for a bastion host, allowing SSH access from a trusted IP range.
  - **Internal SG**: A security group allowing traffic within the VPC, for communication between internal resources.
- **GitHub Actions OIDC Provider**: Sets up an OpenID Connect provider for GitHub Actions, enabling secure, passwordless authentication from GitHub workflows to AWS.
- **IAM Role**: Creates an IAM role for GitHub Actions with necessary permissions to manage the infrastructure resources.

### State Management

- **S3 Bucket for Terraform State**: An S3 bucket is created to store the Terraform state file remotely. It has versioning enabled to keep a history of state files and is protected from accidental deletion.

## Usage

1.  Create a `dev-backend-config.tfvars` file as described in the Backend Configuration section.
2.  Initialize Terraform:
    ```bash
    terraform init -backend-config="dev-backend-config.tfvars"
    ```
3.  Create a `terraform.tfvars` file with your configuration:
    ```hcl
    project_name                 = "my-awesome-project"
    aws_region                   = "us-east-1"
    s3_bucket_name               = "my-terraform-state-bucket-unique-name"
    environment                  = "dev"
    ```
4.  Review the planned changes:
    ```bash
    terraform plan
    ```
5.  Apply the configuration:
    ```bash
    terraform apply
    ```

## Kubernetes Cluster Setup

### Bastion Host

- A Bastion host is deployed in a public subnet for secure SSH access to private resources.
- SSH access is restricted to your IP via the Bastion security group.

### k3s Master and Worker Nodes

- Two Ubuntu EC2 instances are deployed in private subnets: one as the k3s master, one as the worker.
- Both nodes use a security group that allows necessary intra-cluster and Bastion access.

### Installing k3s

1. **SSH to the Bastion host:**
   ```sh
   ssh -i <your-key.pem> ec2-user@<bastion-public-ip>
   ```
2. **From the Bastion, SSH to the master node:**
   ```sh
   ssh ubuntu@<k3s-master-private-ip>
   ```
3. **On the master node, install k3s:**
   ```sh
   curl -sfL https://get.k3s.io | sh -
   sudo k3s kubectl get nodes
   ```
4. **Get the join token:**
   ```sh
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```
5. **SSH to the worker node (from Bastion):**
   ```sh
   ssh ubuntu@<k3s-worker-private-ip>
   ```
6. **Join the worker to the cluster:**
   ```sh
   curl -sfL https://get.k3s.io | K3S_URL="https://<master-private-ip>:6443" K3S_TOKEN="<token>" sh -
   ```

## Accessing the Cluster from Your Local Machine

1. **Copy kubeconfig from master to Bastion:**
   ```sh
   ssh ubuntu@<k3s-master-private-ip> 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/k3s.yaml
   ```
2. **Copy kubeconfig from Bastion to your local machine:**
   ```sh
   scp -i <your-key.pem> ec2-user@<bastion-public-ip>:~/k3s.yaml .
   ```
3. **Edit `k3s.yaml` on your local machine:**
   - Change the `server:` line to:
     ```
     server: https://localhost:6443
     ```
4. **Set up SSH port forwarding:**
   ```sh
   ssh -i <your-key.pem> -L 6443:<k3s-master-private-ip>:6443 ec2-user@<bastion-public-ip>
   ```
5. **Use kubectl locally:**
   ```sh
   export KUBECONFIG=./k3s.yaml
   kubectl get nodes
   ```

## Deploying a Simple Workload

1. **Deploy the nginx pod:**
   ```sh
   kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
   ```
2. **Verify the pod is running:**
   ```sh
   kubectl get all --all-namespaces
   ```
   - You should see a pod named `nginx` in the output.
