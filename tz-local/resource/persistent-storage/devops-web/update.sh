#https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-persistent-storage/

#bash /vagrant/tz-local/resource/persistent-storage/devops-web/update.sh

cd /vagrant/tz-local/resource/persistent-storage/devops-web

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
AWS_REGION=$(prop 'config' 'region')
eks_project=$(prop 'project' 'project')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

cp -Rf k8s-dev.yaml k8s-dev.yaml_bak
sed -i "s/eks_project/${eks_project}/g" k8s-dev.yaml_bak
sed -i "s/aws_account_id/${aws_account_id}/g" k8s-dev.yaml_bak

kubectl -n devops-dev delete -f storageclass.yaml
kubectl -n devops-dev delete -f claim.yaml
kubectl -n devops-dev delete -f k8s-dev.yaml_bak

kubectl -n devops-dev apply -f storageclass.yaml
kubectl -n devops-dev apply -f claim.yaml
kubectl -n devops-dev apply -f k8s-dev.yaml_bak

sleep 20

#kubectl describe pv $(kubectl get pv | grep ebs-sc-devops-web | awk '{print $1}')
kubectl describe pv $(kubectl get pv | grep ebs-sc-devops-web | awk '{print $1}') | grep VolumeHandle | awk '{print $2}'

#kubectl -n devops-dev apply -f pod.yaml
kubectl -n devops-dev delete -f k8s-dev.yaml_bak

kubectl -n devops-dev exec -it pod/$(kubectl get pods -n devops-dev | grep devops-web | awk '{print $1}') -- chmod -Rf 777 /home/ubuntu/devopsWeb/assets/compiled


