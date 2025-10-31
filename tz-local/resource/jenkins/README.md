# tz-jenkins

## Overview
This document outlines how to configure Jenkins running on the Topzone EKS cluster, register required credentials, enable notifications, and deploy the sample `tz-devops-admin` pipeline.

## Access Jenkins
- Primary URL: `https://jenkins.default.topzone-k8s.topzone.me`
- Administrative credentials are created during platform provisioning.

## Configure the Kubernetes Plugin
1. Open `https://jenkins.default.topzone-k8s.topzone.me/configureClouds/`.
2. Configure the cloud details:
   - Name: `topzone-k8s`
   - Kubernetes URL: `https://kubernetes.default`
   - Kubernetes Namespace: `jenkins`
   - Jenkins URL: `http://jenkins.jenkins.svc.cluster.local`
   - Jenkins tunnel: `jenkins-agent:50000`
3. Click **Test Connection** to validate access.

## Register Credentials
Create credentials in `http://jenkins.default.topzone-k8s.topzone.me/credentials/store/system/domain/_/newCredentials`.

### GitHub
- **ID:** `github-token`
  - Kind: Username with password
  - Username: Your GitHub username or email (for example `topzone8713@gmail.com`)
  - Password: GitHub personal access token (`https://github.com/settings/tokens`)

- **ID:** `GITHUP_TOKEN`
  - Kind: Secret text
  - Secret: GitHub personal access token

### AWS
- **ID:** `jenkins-aws-secret-key-id`
  - Kind: Secret text
  - Secret: AWS access key ID for deployment

- **ID:** `jenkins-aws-secret-access-key`
  - Kind: Secret text
  - Secret: AWS secret access key

## Configure Email Notifications
Navigate to `http://localhost:53053/manage/configure` (update the host if Jenkins is exposed differently).

- **Git Plugin**
  - Global Config user.name: `<your_git_username>`
  - Global Config user.email: `<your_git_email>`

- **E-mail Notification**
  - SMTP Server: `smtp.gmail.com`
  - Use SMTP Authentication: enabled
  - Username: `topzone8713@gmail.com`
  - Password: Google App Password
  - Use SSL: disabled
  - Use TLS: enabled
  - SMTP Port: `587`
  - Send a test email to confirm connectivity.

- **Extended E-mail Notification**
  - SMTP Server: `smtp.gmail.com`
  - SMTP Port: `587`
  - Credentials: `gmail-smtp`
  - Use SSL: disabled
  - Use TLS: enabled

## Build the Demo Application
1. Fork `https://github.com/topzone8713/tz-devops-admin.git` to your GitHub organization if needed.
2. Create a new Jenkins pipeline job:
   - Name: `tz-devops-admin`
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/<your_org>/tz-devops-admin.git`
   - Credentials: `github-token`
   - Branch: `devops`
   - Script Path: `k8s/Jenkinsfile`

### Jenkinsfile Environment Variables
Ensure `k8s/Jenkinsfile` defines environment variables similar to:

```groovy
environment {
    GITHUP_ID           = "topzone8713"
    GIT_URL             = "https://github.com/${GITHUP_ID}/tz-devops-admin.git"
    GIT_BRANCH          = "devops"
    GIT_COMMITTER_EMAIL = "topzone8713@gmail.com"
    ACCOUNT_ID          = "084828581538"
    AWS_DEFAULT_REGION  = "ap-northeast-2"
    DOMAIN              = "topzone.me"
    CLUSTER_NAME        = "topzone-k8s"
}
```

## Additional Recommendations
- Rotate GitHub and AWS credentials regularly and update Jenkins stored secrets.
- Restrict credential scope to the minimum necessary jobs whenever possible.

