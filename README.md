# tz-eks-main

## Prep)
``` 
    # buy a domain and register it Route53 first (Optional)
    ex) topzone.me

    # Install docker in ubuntu
    sudo apt update && apt install docker.io docker-compose -y
    sudo chown -Rf ubuntu:ubuntu /var/run/docker.sock

    -. checkout codes
       git clone https://dooheehong@github.com/topzone8713/tz-eks-main.git
       cd tz-eks-main && git checkout -b devops origin/topzone-k8s

    -. copy resources like this,
        tz-ek-main/resources
            .auto.tfvars        # terraform variables file
            config              # aws config
            credentials         # aws credentials
            project             # change your project name, it'll be a eks cluster name.
    
    - ex)
    - .auto.tfvars
        account_id = "596627550572"         # AWS account
        tzcorp_zone_id = "Z0041899D9V07I4RJKFD"   # domain to use
        cluster_name = "topzone-k8s"        
        region = "ap-northeast-2"           
        environment = "prod"
        VCP_BCLASS = "10.20"
        instance_type = "t3.large"
        k8s_config_path = "/root/.kube/config"
        
    - config
        [default]
        region = ap-northeast-2
        output = json
        
        [profile topzone-k8s]
        region = ap-northeast-2
        output = json    
        
    - credentials
        [default]
        aws_access_key_id = xxxxxx
        aws_secret_access_key = xxxxxx
        
        [topzone-k8s]
        aws_access_key_id = xxxxxx
        aws_secret_access_key = xxxxxx
        
    - project
        project=topzone-k8s
        aws_account_id=xxxxxx
        domain=topzone.me
        argocd_id=admin
        admin_password=DevOps!323
        basic_password=Soqn!323
        github_id=topzone8713
        github_token=xxxxxx
        argocd_google_client_id=xxxxxx
        argocd_google_client_secret=xxxxxx
        docker_url=index.docker.io
        dockerhub_id=topzone8713
        dockerhub_password=xxxxxx
      
```

## Run Provisioning)
```
    -. run.
        export docker_user="topzone8713"
        bash bootstrap.sh
        
    -. output
        ssh-key)
            terraform-aws-eks/workspace/base/topzone-k8s
            terraform-aws-eks/workspace/base/topzone-k8s.pub
        k8s config)        
            terraform-aws-eks/workspace/base/kubeconfig_topzone-k8s
    
    -. into docker env.
        tz_project=topzone-k8s
        docker exec -it `docker ps | grep docker-${tz_project} | awk '{print $1}'` bash
        root@8971909b818a:/# base
        root@8971909b818a:/topzone/terraform-aws-eks/workspace/base# tplan
```

## Manual settings
``` 
    1) vault unseal
    It should be done quickly with resources/unseal.txt before each pod destorys.
     
    # vault operator unseal
    #echo k -n vault exec -ti vault-0 -- vault operator unseal
    #k -n vault exec -ti vault-0 -- vault operator unseal # ... Unseal Key 1
    #k -n vault exec -ti vault-0 -- vault operator unseal # ... Unseal Key 2,3,4,5
    #
    #echo k -n vault exec -ti vault-1 -- vault operator unseal
    #k -n vault exec -ti vault-1 -- vault operator unseal # ... Unseal Key 1
    #k -n vault exec -ti vault-1 -- vault operator unseal # ... Unseal Key 2,3,4,5
    #
    #echo k -n vault exec -ti vault-2 -- vault operator unseal
    #k -n vault exec -ti vault-2 -- vault operator unseal # ... Unseal Key 1
    #k -n vault exec -ti vault-2 -- vault operator unseal # ... Unseal Key 2,3,4,5
    
    bash /topzone/tz-local/resource/vault/helm/install.sh
    bash /topzone/tz-local/resource/vault/data/vault_user.sh
    bash /topzone/tz-local/resource/vault/vault-injection/install.sh
    bash /topzone/tz-local/resource/vault/vault-injection/update.sh
    
    2) Jenkins settings
    
        #kubectl -n jenkins cp jenkins-0:/var/jenkins_home/jobs/devops-crawler/config.xml /topzone/tz-local/resource/jenkins/jobs/config.xml
        
        # k8s settings
        https://jenkins.default.${eks_project}.${eks_domain}/manage/configureClouds/
          Kubernetes
            Jenkins URL: http://jenkins.jenkins.svc.cluster.local
          WebSocket: check
          Pod Labels
            Key: jenkins
            Value: slave
        
        ## google oauth2
        client auth info > OAuth 2.0 client ID
          web application
          authorized redirection URI: https://jenkins.default.${eks_project}.${eks_domain}/securityRealm/finishLogin
        
        https://jenkins.default.${eks_project}.${eks_domain}/manage/configureSecurity/
          Disable remember me: check
          Security Realm: Login with Google
          Client Id: xxxxx
          client_secret: xxxxx
```

## Destroy
``` 
    -. remove all
        export docker_user="topzone8713"
        bash bootstrap.sh remove
        
    -. remove VPC remainders
        After it's done, check VPC and S3 again!
        
        https://ap-northeast-2.console.aws.amazon.com/vpcconsole/home?region=ap-northeast-2#vpcs:
        delete topzone-k8s-vpc
``` 
