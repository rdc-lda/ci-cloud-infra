#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash
source /usr/share/misc/aws-func.bash

# Initialise the cloud infra module (generic interface)
initModule $@

if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" ]; then
    log ERROR "AWS Access or Secret keys not found in environment, exit."
    log WARN "Exit process with error code 200."
    exit 200
fi

#
# Set cloud provider config path and file
MY_CLOUD_PROVIDER_SETTINGS=$INFRA_DIR/aws-settings.properties

#
# INIT logic
#
if [ "$ACTION" = "init" ]; then
    if [ ! -f $MY_CLOUD_PROVIDER_SETTINGS ]; then
        MY_AWS_REGION=$(getAwsRegion "$MANIFEST_JSON")
        MY_AWS_ZONE=${MY_AWS_REGION}a
        MY_DEPLOYMENT_ID=$(getDeploynmentId "$MANIFEST_JSON")-$(uuidgen | awk -F- '{ print $NF }')
        MY_PEM_KEY=$INFRA_DIR/aws-keypair.pem

        echo MY_AWS_REGION=$MY_AWS_REGION > $MY_CLOUD_PROVIDER_SETTINGS
        echo MY_AWS_ZONE=$MY_AWS_ZONE >> $MY_CLOUD_PROVIDER_SETTINGS
        echo MY_DEPLOYMENT_ID=$MY_DEPLOYMENT_ID >> $MY_CLOUD_PROVIDER_SETTINGS
        echo MY_PEM_KEY=$MY_PEM_KEY >> $MY_CLOUD_PROVIDER_SETTINGS
    fi 

    #
    # Generate pipeline keypair
    if [ ! -f $MY_PEM_KEY ]; then
        MY_PEM_KEY_NAME=${MY_DEPLOYMENT_ID}
        
        log "Generating PEM keypair with name $MY_PEM_KEY_NAME..."
        aws ec2 create-key-pair --key-name $MY_PEM_KEY_NAME --region $MY_AWS_REGION \
            --query 'KeyMaterial' --output text > $MY_PEM_KEY
        chmod 400 $MY_PEM_KEY

        echo MY_PEM_KEY_NAME=$MY_PEM_KEY_NAME >> $MY_CLOUD_PROVIDER_SETTINGS
    fi

    #
    # Initialise base infra
    STACK_NAME=${MY_DEPLOYMENT_ID}-infra
    result="$(aws cloudformation create-stack \
        --region $MY_AWS_REGION \
        --stack-name $STACK_NAME \
        --template-body file:///usr/share/misc/aws-cloud-infra-cloudformation.yml \
        --parameters \
            ParameterKey=AvailabilityZone,ParameterValue=${MY_AWS_ZONE} \
            ParameterKey=KeyName,ParameterValue=${MY_PEM_KEY_NAME} \
            ParameterKey=DeploymentId,ParameterValue=${MY_DEPLOYMENT_ID}  \
        --capabilities CAPABILITY_IAM \
        --query 'StackId' --output text)"

    log "Creating CloudFormation stack $result"
    waitForStackCreate $STACK_NAME
fi

#
# DESTROY logic
#
if [ "$ACTION" = "destroy" ]; then
    #
    # Source settings
    if [ -f $MY_CLOUD_PROVIDER_SETTINGS ]; then
        source $MY_CLOUD_PROVIDER_SETTINGS
    else
        log ERROR "Cloud Provider settings ($MY_CLOUD_PROVIDER_SETTINGS) not found in workspace, exit."
        log WARN "Exit process with error code 201."
        exit 201
    fi

    #
    # Remove CloudFormation template
    STACK_NAME=${MY_DEPLOYMENT_ID}-infra
    aws cloudformation delete-stack \
        --region $MY_AWS_REGION \
        --stack-name $STACK_NAME &> /dev/null

    log "Deleting CloudFormation stack $STACK_NAME"
    waitForStackDelete $STACK_NAME

    # Delete keypair
    log "Deleting PEM keypair with name $MY_PEM_KEY_NAME..."
    aws ec2 delete-key-pair --key-name $MY_PEM_KEY_NAME --region $MY_AWS_REGION
fi