#!/usr/bin/env bash

#https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html
#https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html

aws codecommit create-repository --repository-name eksworkshop-app

aws iam create-user \
  --user-name git-user

aws iam attach-user-policy \
  --user-name git-user \
  --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser

aws iam create-service-specific-credential \
  --user-name git-user --service-name codecommit.amazonaws.com \
  | tee /tmp/gituser_output.json

GIT_USERNAME=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceUserName')
GIT_PASSWORD=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServicePassword')
CREDENTIAL_ID=$(cat /tmp/gituser_output.json | jq -r '.ServiceSpecificCredential.ServiceSpecificCredentialId')

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
AWS_REGION=$(prop 'config' 'region')

sudo pip install git-remote-codecommit
git clone codecommit::${AWS_REGION}://eksworkshop-app
cd eksworkshop-app

cat << EOF > server.go

package main

import (
    "fmt"
    "net/http"
)

func helloWorld(w http.ResponseWriter, r *http.Request){
    fmt.Fprintf(w, "Hello World")
}

func main() {
    http.HandleFunc("/", helloWorld)
    http.ListenAndServe(":8080", nil)
}
EOF

cat << EOF > server_test.go
package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func Test_helloWorld(t *testing.T) {
	req, err := http.NewRequest("GET", "http://domain.com/", nil)
	if err != nil {
		t.Fatal(err)
	}

	res := httptest.NewRecorder()
	helloWorld(res, req)

	exp := "Hello World"
	act := res.Body.String()
	if exp != act {
		t.Fatalf("Expected! %s got %s", exp, act)
	}
}

EOF

cat << EOF > Jenkinsfile

pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: golang
    image: golang:1.13
    command:
    - cat
    tty: true
"""
    }
  }
  stages {
    stage('Run tests') {
      steps {
        container('golang') {
          sh 'go test'
        }
      }
    }
    stage('Build') {
        steps {
            container('golang') {
              sh 'go build -o eksworkshop-app'
              archiveArtifacts "eksworkshop-app"
            }

        }
    }

  }
}

EOF

git add --all && git commit -m "Initial commit." && git push
cd ~/environment

eks_project=$(prop 'project' 'project')

OIDC_URL=$(aws eks describe-cluster --name ${eks_project} --query "cluster.identity.oidc.issuer" --output text)
#https://oidc.eks.us-west-1.amazonaws.com/id/D2AD1FB30DDA8F40F7E6824EB856308D
aws iam list-open-id-connect-providers | grep ${OIDC_URL##*/}
eksctl utils associate-iam-oidc-provider --cluster ${eks_project} --approve

eksctl create iamserviceaccount \
    --name jenkins \
    --namespace default \
    --cluster ${eks_project} \
    --attach-policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser \
    --approve \
    --override-existing-serviceaccounts

cat << EOF > values.yaml
---
master:
  additionalPlugins:
    - aws-codecommit-jobs:0.3.0
  resources:
    requests:
      cpu: "1024m"
      memory: "4Gi"
    limits:
      cpu: "4096m"
      memory: "8Gi"
  javaOpts: "-Xms4000m -Xmx4000m"
  servicePort: 80
  serviceType: LoadBalancer
agent:
  Enabled: false
rbac:
  create: true
serviceAccount:
  create: false
  name: "jenkins"
EOF

helm install cicd stable/jenkins -f values.yaml

export SERVICE_IP=$(kubectl get svc --namespace default cicd-jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP/login

printf $(kubectl get secret --namespace default cicd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo




kubectl get secret $(kubectl get sa jenkins -n cloudbees-core -o jsonpath={.secrets[0].name}) -n cloudbees-core -o jsonpath={.data.token} | base64 --decode
kubectl get secret $(kubectl get sa jenkins -n cloudbees-core -o jsonpath={.secrets[0].name}) -n cloudbees-core -o jsonpath={.data.'ca\.crt'} | base64 --decode







aws-device-farm




