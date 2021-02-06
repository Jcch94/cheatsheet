# Sample Terraform script

This is an example gitlab ci script which runs a whole terraform process, from creating ecs and ecr , to deploying a demo website via streamlit. The variables needed in env variables are :

1. IMAGE_NAME
2. AWS_ACCESS_KEY_ID
3. AWS_SECRET_ACCESS_KEY
4. AWS_DEFAULT_REGION

```yaml
variables:
  # ask cloud engineer
  DEMOSITE_DOCKER_CONTAINER_PORT: 8501
  DOCKER_REGISTRY: example.ap-southeast-1.amazonaws.com
  DOCKER_HOST: tcp://docker:2375
  S3_BUCKET_NAME: "examples3bucket"
  TERRAFORM_DIR: "TERRAFORM_INFRA"
  ECS_CLUSTER_NAME: "examplecluster"

demosite-staging-terraform-plan-apply:
  stage: staging-build
  image:
    name: zenika/terraform-aws-cli:latest
    entrypoint:
      - "/usr/bin/env"
      - "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  script:
    - bash ci/demo-terraform.sh dev
  only:
    refs:
      - master
    changes:
      - project/demo/*

demosite-staging-deploy:
  stage: staging-deploy
  image:
    name: amazon/aws-cli
    entrypoint: [""]
  services:
    - docker:dind
  before_script:
    - amazon-linux-extras install docker
  script:
    - cd ci
    - bash demo-deploy.sh dev
  only:
    refs:
      - master
    changes:
      - project/demo/*

demosite-prod-terraform-apply:
  stage: prod-build
  image:
    name: zenika/terraform-aws-cli:latest
    entrypoint:
      - "/usr/bin/env"
      - "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  script:
    - bash ci/demo-terraform.sh prod
    - bash ci/demo-terraform.sh dev destroy
  only:
    refs:
      - master
    changes:
      - project/demo/*
  when: manual

demosite-prod-deploy:
  stage: prod-deploy
  needs: ["demosite-prod-terraform-apply"]
  image:
    name: amazon/aws-cli
    entrypoint: [""]
  services:
    - docker:dind
  before_script:
    - amazon-linux-extras install docker
  script:
    - cd ci
    - bash demo-deploy.sh prod
  only:
    refs:
      - master
    changes:
      - project/demo/*
# ##############################################
```

## Stages

There are 3 main stages to terraform ci.

1. Plan
2. Apply
3. Destroy

## Common code for all 3 stages 

```bash
echo $IMAGE_NAME$suffix
aws s3 cp s3://$S3_BUCKET_NAME/TERRAFORM_INFRA "TERRAFORM_INFRA" --recursive --exclude ".sh" --exclude ".md" ## copies needed files from s3 bucket [terraform infra]
cd $TERRAFORM_DIR/$folder
## ******Creating relevant config files with variables populated by environment variables in gitlab **************
echo 'key="PROD/APP/'$IMAGE_NAME$suffix'.dsldemo.site.tfstate"' > app-prod.config 
echo 'bucket="terraform-fargate-cluster"' >> app-prod.config
echo 'region="ap-southeast-1"' >> app-prod.config
awk '!/ecs_service_name/' production.tfvars > tmpfile && mv tmpfile production.tfvars
awk '!/environment/' production.tfvars > tmpfile && mv tmpfile production.tfvars
awk '!/docker_container_port/' production.tfvars > tmpfile && mv tmpfile production.tfvars
echo "ecs_service_name = \"$IMAGE_NAME$suffix\"" >> production.tfvars
echo "environment = \"$folder\"" >> production.tfvars
echo "docker_container_port = $DEMOSITE_DOCKER_CONTAINER_PORT" >> production.tfvars
cat app-prod.config
cat production.tfvars
##*****************************************************************************************************************
terraform init -backend-config=app-prod.config ## initialise terraform with the config files
```

### Plan

```yaml
image:
  name: zenika/terraform-aws-cli:latest
  entrypoint:
    - "/usr/bin/env"
    - "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    - "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
    - "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
    
```

The image used is zenika/terraform-aws-cli, it has terraform with the latest aws-cli command line installed in it. This is to facilitate the creation of the ECR and ECS, which will both require login to be done.

```bash
terraform plan -var-file=production.tfvars -out "planfile_dev"
```

[//]: # (Add in more information after getting access to s3 bucket)  

### Apply  

```bash
terraform apply -var-file=production.tfvars --auto-approve
echo "Terraform Apply >> done"
```

This creates the relevant aws ecr and ecs services, as specified in the config files.  

### Destroy

```bash
terraform destroy -var-file=production.tfvars --auto-approve
    echo "Terraform Destroy Plan >> done"
    exit 0

```

This destroys the terraform infrastructure as specified in the config file, the aws ecr and ecs. 

## Deploying streamlit demosite

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin $DOCKER_REGISTRY
docker push $DOCKER_REGISTRY/$ECS_CLUSTER_NAME-$IMAGE_NAME$suffix:v1
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $IMAGE_NAME$suffix --force-new-deployment --region $AWS_DEFAULT_REGION
```

This is used to deploy a docker image, in this case the demosite, to the aws ecr and ecs.  

