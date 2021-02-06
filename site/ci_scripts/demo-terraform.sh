 #!/bin/bash

if [ $1 == "dev" ];then
    suffix="-dev"
    folder="dev"
fi


# get terraform scripts from S3
# create ECS & ECR

echo "Job Terraform plan *******<><><><><><><><><><><><>**********"
echo $IMAGE_NAME$suffix
aws s3 cp s3://$S3_BUCKET_NAME/TERRAFORM_INFRA "TERRAFORM_INFRA" --recursive --exclude ".sh" --exclude ".md"
cd $TERRAFORM_DIR/$folder
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
terraform init -backend-config=app-prod.config

# plan
if [ $1 == "dev" ] && [ $2 != "destroy" ];then
    terraform plan -var-file=production.tfvars -out "planfile_dev"
    echo "Terraform Plan >> done"
fi

# destroy
if [ $2 == "destroy" ];then
    terraform destroy -var-file=production.tfvars --auto-approve
    echo "Terraform Destroy Plan >> done"
    exit 0
fi

# apply
terraform apply -var-file=production.tfvars --auto-approve
echo "Terraform Apply >> done"
