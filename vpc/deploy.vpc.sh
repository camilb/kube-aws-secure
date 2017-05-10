#!/bin/sh
set -e

ROLE="kube-aws-vpc"
STACK_NAME="kube-aws-vpc"
STACK_FILE="vpc"
SERVICE_NAME_PREFIX="k8s"

STACK_PARAMS="ParameterKey=ServiceNamePrefix,ParameterValue=${SERVICE_NAME_PREFIX} ParameterKey=Role,ParameterValue=${ROLE}"
STACK_TAGS="Key=Role,Value=${ROLE}"

for TEMPLATE_FILE in *.yaml
do
    echo "### Validating -> ${TEMPLATE_FILE}"

    aws cloudformation validate-template \
            --template-body file://${TEMPLATE_FILE}

    echo
done

aws cloudformation create-stack \
    --stack-name kube-aws-vpc \
    --template-body file://./${TEMPLATE_FILE} \
    --parameters ${STACK_PARAMS} \
    --capabilities CAPABILITY_IAM
