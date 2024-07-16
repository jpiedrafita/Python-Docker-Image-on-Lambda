# Deploying a Docker image in a Lambda Function using Terraform

Deploy infrastructure:
```sh
make deploy
```

Destroy infrastructure:
```sh
make destroy
```

# Considerations

The deploy and destroy processed are composed by smaller steps because some dependencies within the process.

- ```terraform apply``` won't work as the Lambda function requires the image to be available in the ECR repo in the first place. On teh other hand, the image cannot be pushed to an ECR repo that does not exist yet.
- ```make terraform/init-ect``` will initialize the ECR repo before the build process.
- ```make docker/login``` will authnticate docker with the ecr public registry to allow the usage of the AWS Python image from ECT taht is used in the [Dockerfile](/image/Dockerfile).
- ```make docker/build``` will build the image using the environment env variable as tag. The ```--platform linux/amd64``` flag is required if the build process is done from an ARM64 architecture.
- ```make docker/push```will push the image to the ECR repo created before.
- ```make terraform/apply``` will create the rest of the infrastructure as the image for the Lambda function is already available at this point. This step will create the Lambda function and a role.
- ```make test``` allows to test the remote function using cli.

Expected result:
```sh
❯ make test
aws lambda invoke --function-name arn:aws:lambda:eu-south-2:751684495047:function:docker_lambda_function-dev --payload '{}' response.json --profile chorche --region eu-south-2 --no-cli-pager
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
cat response.json
{"statusCode": 200, "body": {"message": "Hello from Lambda!", "array": [[3, 5, 9], [3, 9, 7], [6, 5, 5]]}}
```
- ```make ecr/rm``` will remove all the images in the remore ECR repo . The command ```make destroy``` depends on this one, as terraform cannot destroy a non-empty repo

# Local Test
Once the image is built, use ```make docker/run``` to run the container and ```docker lcoal-test``` to test the application.
