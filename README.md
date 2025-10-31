# tz-eks-main

## Overview
This repository provisions and manages an Amazon EKS environment for the Topzone infrastructure. It relies on Docker-based tooling, Terraform configurations, and supporting automation scripts contained in this project.

## Prerequisites
- Registered Route53 hosted zone for your domain (optional but recommended)
- AWS account credentials with permissions to create EKS clusters and networking resources
- Ubuntu host (or compatible environment) with Docker and Docker Compose installed
- Terraform and kubectl available inside the provided Docker environment

### Install Docker on Ubuntu
```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo chown -Rf ubuntu:ubuntu /var/run/docker.sock
```

## Clone the Repository
```bash
git clone https://github.com/topzone8713/tz-eks-main.git
cd tz-eks-main
git checkout -b devops origin/topzone-k8s
```

## Prepare Resource Files
Copy the `resources` directory into the project so it resembles the structure below. Adjust the values to match your environment.

```
tz-eks-main/
└── resources/
    ├── .auto.tfvars       # Terraform variables
    ├── config             # AWS CLI config
    ├── credentials        # AWS CLI credentials
    └── project            # Project metadata (cluster naming and credentials)
```

### Example `.auto.tfvars`
```hcl
account_id      = "000000000000"
tzcorp_zone_id  = "Z0EXAMPLEZONEID"
cluster_name    = "topzone-k8s"
region          = "ap-northeast-2"
environment     = "prod"
VCP_BCLASS      = "10.20"
instance_type   = "t3.large"
k8s_config_path = "/root/.kube/config"
```

### Example `config`
```ini
[default]
region = ap-northeast-2
output = json

[profile topzone-k8s]
region = ap-northeast-2
output = json
```

### Example `credentials`
```ini
[default]
aws_access_key_id = <your_access_key_id>
aws_secret_access_key = <your_secret_access_key>

[topzone-k8s]
aws_access_key_id = <your_access_key_id>
aws_secret_access_key = <your_secret_access_key>
```

### Example `project`
```ini
project=topzone-k8s
aws_account_id=<your_account_id>
domain=topzone.me
argocd_id=admin
admin_password=<your_admin_password>
basic_password=<your_basic_password>
github_id=topzone8713
github_token=<your_github_token>
argocd_google_client_id=<your_google_client_id>
argocd_google_client_secret=<your_google_client_secret>
docker_url=index.docker.io
dockerhub_id=topzone8713
dockerhub_password=<your_dockerhub_password>
```

> **Security Note:** Replace sample values with your own secrets and store all sensitive data securely.

## Provisioning Workflow
1. Set the Docker user:
   ```bash
   export docker_user="topzone8713"
   ```
2. Run the bootstrap script:
   ```bash
   bash bootstrap.sh
   ```
3. After the script completes, collect the generated artifacts:
   - SSH key pair: `terraform-aws-eks/workspace/base/topzone-k8s(.pub)`
   - Kubernetes config: `terraform-aws-eks/workspace/base/kubeconfig_topzone-k8s`

### Enter the Docker Environment
```bash
tz_project=topzone-k8s
docker exec -it $(docker ps | grep "docker-${tz_project}" | awk '{print $1}') bash
```

Inside the container you can run Terraform helpers such as:
```bash
base
tplan
```

## Manual Configuration

### Vault Unseal
Unseal Vault pods promptly using the keys from `resources/unseal.txt`.

```bash
# vault operator unseal
k -n vault exec -ti vault-0 -- vault operator unseal
k -n vault exec -ti vault-0 -- vault operator unseal
k -n vault exec -ti vault-0 -- vault operator unseal

k -n vault exec -ti vault-1 -- vault operator unseal
k -n vault exec -ti vault-1 -- vault operator unseal
k -n vault exec -ti vault-1 -- vault operator unseal

k -n vault exec -ti vault-2 -- vault operator unseal
k -n vault exec -ti vault-2 -- vault operator unseal
k -n vault exec -ti vault-2 -- vault operator unseal

bash /topzone/tz-local/resource/vault/helm/install.sh
bash /topzone/tz-local/resource/vault/data/vault_user.sh
bash /topzone/tz-local/resource/vault/vault-injection/install.sh
bash /topzone/tz-local/resource/vault/vault-injection/update.sh
```

### Jenkins Configuration
1. (Optional) Back up existing job configuration:
   ```bash
   kubectl -n jenkins cp jenkins-0:/var/jenkins_home/jobs/devops-crawler/config.xml /topzone/tz-local/resource/jenkins/jobs/config.xml
   ```
2. Configure Kubernetes cloud in Jenkins:
   - URL: `https://jenkins.default.${eks_project}.${eks_domain}/manage/configureClouds/`
   - Jenkins URL: `http://jenkins.jenkins.svc.cluster.local`
   - Enable WebSocket connection
   - Pod label key/value: `jenkins=slave`
3. Configure Google OAuth2:
   - Client authentication → OAuth 2.0 client ID (Web application)
   - Redirect URI: `https://jenkins.default.${eks_project}.${eks_domain}/securityRealm/finishLogin`
4. Security settings:
   - URL: `https://jenkins.default.${eks_project}.${eks_domain}/manage/configureSecurity/`
   - Disable “Remember me”
   - Security Realm: Login with Google (use your client ID and secret)

## Cleanup
1. Remove all deployed resources:
   ```bash
   export docker_user="topzone8713"
   bash bootstrap.sh remove
   ```
2. Verify AWS resources are deleted. In particular, remove any residual VPC or S3 assets such as `topzone-k8s-vpc` via the AWS Console.

## Additional Tips
- Keep Terraform state and generated credentials in a secure location.
- Rotate sensitive values regularly and avoid committing secrets to version control.
