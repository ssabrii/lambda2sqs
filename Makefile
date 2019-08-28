PROJECT = $(shell basename $(CURDIR))
STACK_NAME ?= $(PROJECT)
AWS_REGION = ap-southeast-1
DEPLOY_S3_PREFIX = lambda2sns

.PHONY: deps clean build test deploy

# https://blog.deleu.dev/leveraging-aws-sqs-retry-mechanism-lambda/

deps:
	GO111MODULE=on go mod tidy

build: deps
	GOOS=linux GOARCH=amd64 go build -o lambda2sns .

test:
	go test ./...

logs:
	sam logs -n alambda_simple -t

rtlogs:
	sam logs -n alambda_simple_retry -t

destroy:
	aws cloudformation delete-stack \
		--stack-name $(STACK_NAME)

dev: build
	sam validate --template template.yaml
	sam package --template-file template.yaml --s3-bucket dev-media-unee-t --s3-prefix $(DEPLOY_S3_PREFIX) --output-template-file packaged.yaml
	AWS_PROFILE=uneet-dev sam deploy --template-file ./packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM

demo: build
	AWS_PROFILE=uneet-demo aws s3 ls s3://demo-media-unee-t
	AWS_PROFILE=uneet-demo sam package --template-file template.yaml --s3-bucket demo-media-unee-t --s3-prefix $(DEPLOY_S3_PREFIX) --output-template-file packaged.yaml
	AWS_PROFILE=uneet-demo sam deploy --template-file ./packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --parameter-overrides DefaultSecurityGroup=sg-6f66d316 PrivateSubnets=subnet-0bdef9ce0d0e2f596,subnet-091e5c7d98cd80c0d,subnet-0fbf1eb8af1ca56e3

prod: build
	AWS_PROFILE=uneet-prod sam package --template-file template.yaml --s3-bucket prod-media-unee-t --s3-prefix $(DEPLOY_S3_PREFIX) --output-template-file packaged.yaml
	AWS_PROFILE=uneet-prod sam deploy --template-file ./packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --parameter-overrides DefaultSecurityGroup=sg-9f5b5ef8 PrivateSubnets=subnet-0df289b6d96447a84,subnet-0e41c71ad02ee7e99,subnet-01cb9ee064743ac56

lint:
	cfn-lint template.yaml
