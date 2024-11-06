# Terraform을 사용하여 Kubernetes 기반 AWS 인프라 구성하기 (업데이트)

이번 글에서는 Terraform을 사용하여 AWS 인프라를 자동으로 프로비저닝하고 Kubernetes 클러스터를 구축하는 방법을 설명합니다. 새로 추가된 `lb2.tf_ori` 파일을 포함하여 모든 Terraform 구성 파일들에서 생성되는 주요 자원들을 하나씩 살펴보겠습니다.

---

## 1. 데이터 소스

- **`aws_availability_zones (available)`**  
  - **설명**: AWS 계정에서 사용 가능한 가용 영역(Availability Zones)을 조회합니다. 이 정보는 VPC 및 서브넷 구성 시 활용됩니다.

- **`aws_caller_identity (current)`**, **`aws_region (current)`**  
  - **설명**: 현재 AWS 계정과 사용자, 그리고 리전 정보를 가져옵니다. IAM 및 리소스 정책 설정 시 사용됩니다.

- **`aws_eks_cluster (cluster)`**, **`aws_eks_cluster_auth (cluster)`**  
  - **설명**: EKS 클러스터의 정보를 가져옵니다. 클러스터 접근과 인증 설정에 사용됩니다.

- **`aws_vpc (selected)`**  
  - **설명**: 선택된 VPC에 대한 정보를 가져옵니다.

---

## 2. 상태 관리용 리소스

- **`aws_s3_bucket (tfstate)`**  
  - **설명**: Terraform의 상태 파일을 저장하는 S3 버킷을 생성합니다. 이 버킷은 인프라 상태 관리에 사용됩니다.

- **`aws_s3_bucket_versioning (tfstate)`**  
  - **설명**: S3 버킷의 버전 관리를 활성화하여 Terraform 상태 파일의 버전을 추적할 수 있도록 합니다.

- **`aws_dynamodb_table (terraform_state_lock)`**  
  - **설명**: Terraform의 상태 잠금을 위한 DynamoDB 테이블을 생성합니다. 이를 통해 여러 사용자가 동시에 Terraform 상태를 변경하는 것을 방지할 수 있습니다.

---

## 3. 네트워킹 리소스

- **`vpc (모듈)`**  
  - **설명**: VPC 모듈을 사용하여 공용 및 사설 서브넷을 포함한 가상 사설 네트워크를 생성합니다. 네트워크에는 NAT 게이트웨이, 인터넷 게이트웨이, 라우팅 테이블 등이 포함됩니다.

---

## 4. IAM 및 보안 리소스

- **`aws_iam_policy (cert_manager_policy)`**, **`aws_iam_role_policy_attachment (eks-main-ecr-policy)`**  
  - **설명**: 인증서 관리자와 ECR 접근을 위한 IAM 정책 및 정책 연결을 생성합니다.

- **`iam_ecr_policy (모듈)`**, **`cert_manager_irsa (모듈)`**  
  - **설명**: IAM 관련 설정을 위한 추가 모듈입니다. ECR과 인증서 관리에 필요한 IAM 역할 및 정책을 구성합니다.

- **`aws_kms_key (eks-main-vault-kms)`**, **`aws_kms_alias (eks-main-vault-kms)`**  
  - **설명**: EKS 클러스터에서 사용하는 KMS 키와 별칭을 생성합니다.

---

## 5. SSH 키 페어

- **`aws_key_pair (main)`**  
  - **설명**: EC2 인스턴스에 SSH를 통해 접근하기 위한 키 페어를 생성합니다.

---

## 6. 보안 그룹

- **`aws_security_group (worker_group_devops)`**, **`aws_security_group (all_worker_mgmt)`**  
  - **설명**: 워커 그룹을 위한 보안 그룹을 설정합니다.

---

## 7. 컨테이너 레지스트리

- **`aws_ecr_repository (devops-crawler)`**  
  - **설명**: Docker 이미지를 저장할 수 있는 ECR 리포지토리를 생성합니다.

---

## 8. EKS 클러스터 및 추가 설정

- **`eks (모듈)`**  
  - **설명**: Amazon EKS를 통해 Kubernetes 클러스터를 생성합니다.

- **`kubernetes_service_account (this)`**, **`kubernetes_cluster_role (this)`**, **`kubernetes_cluster_role_binding (this)`**  
  - **설명**: Kubernetes 서비스 계정, 클러스터 역할, 클러스터 역할 바인딩을 구성합니다.

- **`helm_release (alb_controller)`**  
  - **설명**: ALB(Ingress) 컨트롤러를 배포합니다.

# 생성 순서

## 1. 데이터 소스

- `aws_availability_zones`
- `aws_caller_identity`
- `aws_region`
- `aws_eks_cluster`
- `aws_eks_cluster_auth`
- `aws_vpc`

---

## 2. 상태 관리용 리소스

- `aws_s3_bucket`
- `aws_s3_bucket_versioning`
- `aws_dynamodb_table`

---

## 3. 네트워킹 리소스

- `vpc`

---

## 4. IAM 및 보안 리소스

- `aws_iam_policy`
- `aws_iam_role_policy_attachment`
- `iam_ecr_policy`
- `cert_manager_irsa`
- `aws_kms_key`
- `aws_kms_alias`

---

## 5. SSH 키 페어

- `aws_key_pair`

---

## 6. 보안 그룹

- `aws_security_group`

---

## 7. 컨테이너 레지스트리

- `aws_ecr_repository`

---

## 8. EKS 클러스터 및 추가 설정

- `eks`
- `kubernetes_service_account`
- `kubernetes_cluster_role`
- `kubernetes_cluster_role_binding`
- `helm_release`
