#!/bin/bash

if [ $1 == "dev" ];then
    suffix="-dev"
fi


# build container
echo "building docker container"
cd ../project/demo

#docker build --tag $FULL_IMAGE_NAME .
docker build -t $DOCKER_REGISTRY/$ECS_CLUSTER_NAME-$IMAGE_NAME$suffix:v1 .
docker run -d -p $DEMOSITE_DOCKER_CONTAINER_PORT:$DEMOSITE_DOCKER_CONTAINER_PORT $DOCKER_REGISTRY/$ECS_CLUSTER_NAME-$IMAGE_NAME$suffix:v1

# check streamlit server has started
time_elapsed=1
while true; do
    echo "waiting streamlit server to start... $time_elapsed sec"
    content=$(curl -s -w "%{http_code}" http://docker:$DEMOSITE_DOCKER_CONTAINER_PORT)
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
    then docker logs $DOCKER_REGISTRY/$ECS_CLUSTER_NAME-$IMAGE_NAME$suffix:v1
         exit 1
    fi

    sleep 1
    time_elapsed=$((time_elapsed + 1))
done

echo "Ping test done..."
aws ecr get-login-password | docker login --username AWS --password-stdin $DOCKER_REGISTRY
docker push $DOCKER_REGISTRY/$ECS_CLUSTER_NAME-$IMAGE_NAME$suffix:v1
#  below command not required,if you want to use the change domain name from dsldemo.site to dsldemo-site. as service names doesnt accept dot character
aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $IMAGE_NAME$suffix --force-new-deployment --region $AWS_DEFAULT_REGION
