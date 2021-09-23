#!/usr/bin/env bash

#https://devopscube.com/create-kubernetes-jobs-cron-jobs/

cd /vagrant/tz-local/resource/jobs

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
AWS_REGION=$(prop 'config' 'region')
eks_domain=$(prop 'project' 'domain')
eks_project=$(prop 'project' 'project')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

## build docker image & push
sudo chown -Rf vagrant:vagrant /var/run/docker.sock

TAG_ID="latest"
DOCKER_NAME="${eks_project}-test-job"
REPO_HOST="${aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG="${DOCKER_NAME}:${TAG_ID}"
REPOSITORY_TAG="${REPO_HOST}/${IMAGE_TAG}"

REPO_IMAGE=$(aws ecr list-images --repository-name ${DOCKER_NAME})
if [[ $? != 0 ]]; then
  aws ecr create-repository \
      --repository-name ${DOCKER_NAME} \
      --image-tag-mutability IMMUTABLE
  sleep 3
fi

pushd `pwd`
cd dockerfile
docker build --no-cache -f Dockerfile -t ${REPOSITORY_TAG} .
docker image ls
#docker run ${aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DOCKER_NAME}

REPO_URL=$(aws ecr describe-repositories --repository-name "${DOCKER_NAME}" | jq '.repositories[].repositoryUri' | tr -d '"')
echo "REPO_URL: ${REPO_URL}"
aws ecr get-login-password --region ${AWS_REGION} \
  | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${REPOSITORY_TAG}
popd

## apply jobs
cp job.yaml job.yaml_bak
sed -i "s|REPOSITORY_TAG|${REPOSITORY_TAG}|g" job.yaml_bak
kubectl apply -f job.yaml_bak
kubectl get jobs
kubectl get po
#kubectl logs jobs/kubernetes-job-example -f
kubectl delete jobs/kubernetes-job-example

cp paral-job.yaml paral-job.yaml_bak
sed -i "s|REPOSITORY_TAG|${REPOSITORY_TAG}|g" paral-job.yaml_bak
kubectl apply -f paral-job.yaml_bak
kubectl get jobs
kubectl delete -f paral-job.yaml_bak

cp cron-job.yaml cron-job.yaml_bak
sed -i "s|REPOSITORY_TAG|${REPOSITORY_TAG}|g" cron-job.yaml_bak
kubectl apply -f cron-job.yaml_bak
kubectl get cronjobs
kubectl delete -f cron-job.yaml_bak

exit 0



