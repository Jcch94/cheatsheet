# Example of deploying to aws ECR from a base docker image

This is an example code used to deploy to ECR from a base docker image. The goal is to first test if the streamlit demo site is running. Upon success , build a new docker image every time there is changes to the demo site , and only when the changes are commited in a merge request to master. This new image is then pushed to a ECR repository , if the repo does not exist, it will create it then add the image in. 

``` yaml
deploy-demo:
  stage: deploy 
  image: docker # Base image which gitlab Ci runs first
  services:
    - docker:dind # uses docker in docker service in order to build docker files
  variables:
    FULL_IMAGE_NAME: demosite-$IMAGE_NAME-$CI_PROJECT_ID
  before_script: 
    - apk update # for alpine linux based image, which docker is . 
    - apk upgrade
    - apk add curl bash # install curl and bash which is required for the below script
    - sh ci/install-aws_cli2.sh # Script to install AWS CLI for this docker image.
  script:
    - cd ci
    - bash deploy-demo.sh #run deploy -demo script 
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "master"' ## runs when commit is a merge request into master
      changes:
        - project/demo/* ## and only if there are any change to files inside project / demo 
      when: always
```
``` bash
#!/bin/bash


# build container
echo "building docker container"
cd ..
cd project/demo
docker build --tag $FULL_IMAGE_NAME . ## Creating docker image
docker run -d -p 8501:8501 --name $FULL_IMAGE_NAME $FULL_IMAGE_NAME ## running the docker image , which in this case is the streamlit app .

# check streamlit server has started
time_elapsed=1
while true; do
    echo "waiting streamlit server to start... $time_elapsed sec"
    content=$(curl -s -w "%{http_code}" http://docker:8501)
    statuscode="${content:(-3)}"

    if [ $statuscode -gt 299 ]
    then echo "streamlit Server Error: $statuscode"
         echo "Error Msg: $content"
         exit 1
    elif [[ $statuscode == "200" ]]
    then echo -e "streamlit Server Launched\n"
         break
    fi

    if [[ $time_elapsed == '10' ]]
    then docker logs $FULL_IMAGE_NAME
         exit 1
    fi

    sleep 1
    time_elapsed=$((time_elapsed + 1))
done

## Pushing image to AWS ECR

echo "Checking if repository exists. If it does not exist , creating repository.."
aws ecr describe-repositories --repository-names ${FULL_IMAGE_NAME} || aws ecr create-repository --repository-name ${FULL_IMAGE_NAME} # Check list of all repos in the ECR. 
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $DOCKER_REGISTRY # login to aws ECR 
docker images
docker tag ${FULL_IMAGE_NAME} $DOCKER_REGISTRY/$FULL_IMAGE_NAME #tag the image 
echo "Pushing Image to ${FULL_IMAGE_NAME} repository"
docker push $DOCKER_REGISTRY/$FULL_IMAGE_NAME:latest # push image to ECR
aws ecr describe-images --repository-name $FULL_IMAGE_NAME # describe the image to check if exists 

```