#https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-persistent-storage/

cd /vagrant/tz-local/resource/persistent-storage

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
AWS_REGION=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

VOLUME_ID=$(kubectl describe pv $(kubectl get pv | grep prometheus-grafana | \
  awk '{print $1}') | grep VolumeID | awk '{print $2}' | rev | cut -d"/" -f1  | rev)
echo ${VOLUME_ID}

PV_ID=$(kubectl describe pv $(kubectl get pv | grep prometheus-grafana | \
  awk '{print $1}') | grep 'Name:' | awk '{print $2}')
echo ${PV_ID}

aws ec2 create-snapshot --volume-id ${VOLUME_ID} \
  --description 'prometheus-grafana backup' \
  --tag-specifications 'ResourceType=snapshot,Tags=[{Key=team,Value=DevOps},{Key=name,Value=prometheus-grafana}]'

aws ec2 create-volume \
    --volume-type io1 \
    --iops 1000 \
    --snapshot-id snap-066877671789bd71b \
    --availability-zone us-east-1a

#aws ec2 create-volume \
#    --volume-type gp2 \
#    --size 1 \
#    --snapshot-id snap-0c84c7f9eeb983a8e \
#    --availability-zone ap-northeast-2b

kubectl patch pvc data-consul-consul-server-0 -n consul \
  --patch 'spec:\n awsElasticBlockStore:\n  volumeID: aws://ap-northeast-2b/vol-0b6807e8d57e7da65'

