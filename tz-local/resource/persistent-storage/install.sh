#https://aws.amazon.com/ko/premiumsupport/knowledge-center/eks-persistent-storage/

#bash /vagrant/tz-local/resource/persistent-storage/install.sh
cd /vagrant/tz-local/resource/persistent-storage

function prop {
	grep "${2}" "/home/vagrant/.aws/${1}" | head -n 1 | cut -d '=' -f2 | sed 's/ //g'
}
AWS_REGION=$(prop 'config' 'region')
eks_domain=$(prop 'project' 'domain')
eks_project=$(prop 'project' 'project')
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

aws iam create-policy \
    --policy-name AmazonEKS_EBS_CSI_Driver_Policy-${eks_project} \
    --policy-document file://example-iam-policy.json

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster ${eks_project} \
    --attach-policy-arn arn:aws:iam::${aws_account_id}:policy/AmazonEKS_EBS_CSI_Driver_Policy-${eks_project} \
    --approve \
    --override-existing-serviceaccounts

aws cloudformation describe-stacks \
    --stack-name eksctl-${eks_project}-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa \
    --query='Stacks[].Outputs[?OutputKey==`Role1`].OutputValue' \
    --output text

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm uninstall aws-ebs-csi-driver --namespace kube-system
helm upgrade -install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --set enableVolumeResizing=true \
  --set enableVolumeSnapshot=true \
  --set serviceAccount.controller.create=false \
  --set serviceAccount.controller.name=ebs-csi-controller-sa

exit 0

#### test ####
kubectl apply -f specs/
kubectl describe storageclass ebs-sc
#kubectl get pods --watch
sleep 30

kubectl describe pv $(kubectl get pv | grep ebs-sc | awk '{print $1}')
kubectl exec -it app -- cat /data/out.txt
kubectl delete -f specs/


