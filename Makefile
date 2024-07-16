APP_NAME = docker-lambda
APP_VERSION = 0.0.1

ENV ?= dev

AWS_ECR_PROFILE ?= $(AWS_PROFILE)
AWS_ECR_ACCOUNT_ID ?= $(AWS_ACCOUNT_ID)
AWS_ECR_REGION ?= eu-south-2
AWS_ECR_REPO = $(APP_NAME)-repo-$(ENV)

TAG ?= $(ENV)

include .env
export $(shell sed 's/=.*//' .env)

.PHONY : docker/build docker/push docker/run docker/test

terraform/init-ecr:
	cd terraform && terraform init
	cd terraform && terraform apply -target=aws_ecr_repository.lambda_repo -var="profile=$(AWS_ECR_PROFILE)" -var="env_name=$(ENV)" -auto-approve

docker/login :
	aws ecr-public get-login-password --region us-east-1 --profile $(AWS_ECR_PROFILE) | docker login --username AWS --password-stdin public.ecr.aws

docker/build :
	cd image && docker build --platform linux/amd64 -t $(APP_NAME):$(APP_VERSION) .

docker/push : docker/build
	cd image && aws ecr get-login-password --region $(AWS_ECR_REGION) --profile $(AWS_ECR_PROFILE) | docker login --username AWS --password-stdin $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com
	cd image && docker tag $(APP_NAME):$(APP_VERSION) $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(ENV)
	cd image && docker push $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)

terraform/apply:
	cd terraform && terraform apply -var="profile=$(AWS_ECR_PROFILE)" -var="env_name=$(ENV)" -auto-approve

docker/run :
	docker run -p 9000:8080 $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)


docker/local-test :
	curl -XPOST 'http://localhost:9000/2015-03-31/functions/function/invocations' -d '{}'

ecr/rm :
	@IMAGES=$$(aws ecr list-images --repository-name $(AWS_ECR_REPO) --region $(AWS_ECR_REGION) --profile $(AWS_ECR_PROFILE) --query 'imageIds[*]' --output json); \
	echo "IMAGES: $$IMAGES"; \
	IMAGE_IDS=$$(echo $$IMAGES | jq -c '. | map({imageDigest: .imageDigest})'); \
	echo "IMAGE_IDS: $$IMAGE_IDS"; \
	if [ "$$IMAGE_IDS" != "[]" ]; then \
		aws ecr batch-delete-image --repository-name $(AWS_ECR_REPO) --image-ids "$$IMAGE_IDS" --region $(AWS_ECR_REGION) --profile $(AWS_ECR_PROFILE) --no-cli-pager; \
	fi

deploy : terraform/init-ecr docker/login docker/build docker/push terraform/apply

test: 
	aws lambda invoke --function-name arn:aws:lambda:$(AWS_ECR_REGION):$(AWS_ECR_ACCOUNT_ID):function:docker_lambda_function-$(ENV) --payload '{}' response.json --profile $(AWS_ECR_PROFILE) --region $(AWS_ECR_REGION) --no-cli-pager
	cat response.json

destroy : ecr/rm
	cd terraform && terraform destroy -var="profile=$(AWS_ECR_PROFILE)" -auto-approve

