#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash
source /usr/share/misc/aws-func.bash

# Initialise the cloud infra module (generic interface)
initInfraModule $@

# Initialise the AWS infra module (generic interface)
initAWSInfraModule

#
# INIT logic
#
if [ "$ACTION" = "init" ]; then
    #
    # Initialise infra
    STACK_NAME=${MY_DEPLOYMENT_ID}-channel-middleware
    # result="$(aws cloudformation create-stack \
    #     --region $MY_AWS_REGION \
    #     --stack-name $STACK_NAME \
    #     --template-body file:///usr/share/misc/aws-cloud-infra-cloudformation.yml \
    #     --parameters \
    #         ParameterKey=AvailabilityZone,ParameterValue=${MY_AWS_ZONE} \
    #         ParameterKey=KeyName,ParameterValue=${MY_PEM_KEY_NAME} \
    #         ParameterKey=DeploymentId,ParameterValue=${MY_DEPLOYMENT_ID}  \
    #     --capabilities CAPABILITY_IAM \
    #     --query 'StackId' --output text)"

    log "Creating CloudFormation stack $result"
    # waitForStackCreate $STACK_NAME
fi

#
# DESTROY logic
#
if [ "$ACTION" = "destroy" ]; then
    #
    # Remove CloudFormation template
    STACK_NAME=${MY_DEPLOYMENT_ID}-channel-middleware
    # aws cloudformation delete-stack \
    #     --region $MY_AWS_REGION \
    #     --stack-name $STACK_NAME &> /dev/null

    log "Deleting CloudFormation stack $STACK_NAME"
    # waitForStackDelete $STACK_NAME
fi