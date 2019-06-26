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
initAWSInfraConfig

# Set template
TEMPLATE=/usr/share/misc/aws-channel-middelware-infra-cloudformation.yml.sempl

# Set workspace dir
WS_DIR=$INFRA_DIR/channel-middleware

#
# INIT logic
#
if [ "$ACTION" = "init" -a ! -f $WS_DIR/success ]; then
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

    log MOCK "Creating CloudFormation stack $result"
    # waitForStackCreate $STACK_NAME
    
    #
    # Success flag
    touch $WS_DIR/success
fi

#
# DESTROY logic
#
if [ "$ACTION" = "destroy" ]; then
    #
    # Delete CloudFormation stack
    deleteCloudFormationStack  ${MY_DEPLOYMENT_ID}-channel-middleware
fi