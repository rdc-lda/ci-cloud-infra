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
    # Init config
    MY_AWS_REGION=$(getAwsRegion "$MANIFEST_JSON")
    MY_AWS_ZONE=${MY_AWS_REGION}a
    MY_DEPLOYMENT_ID=$(getDeploynmentId "$MANIFEST_JSON")-$(uuidgen | awk -F- '{ print $NF }')
    MY_PEM_KEY=$INFRA_DIR/aws-keypair.pem

    # Persist to AWS Settings env
    echo MY_AWS_REGION=$MY_AWS_REGION > $MY_CLOUD_PROVIDER_SETTINGS
    echo MY_AWS_ZONE=$MY_AWS_ZONE >> $MY_CLOUD_PROVIDER_SETTINGS
    echo MY_DEPLOYMENT_ID=$MY_DEPLOYMENT_ID >> $MY_CLOUD_PROVIDER_SETTINGS
    echo MY_PEM_KEY=$MY_PEM_KEY >> $MY_CLOUD_PROVIDER_SETTINGS

    #
    # Generate pipeline keypair
    if [ ! -f $MY_PEM_KEY ]; then
        MY_PEM_KEY_NAME=${MY_DEPLOYMENT_ID}
        
        log "Generating PEM keypair with name $MY_PEM_KEY_NAME..."
        aws ec2 create-key-pair --key-name $MY_PEM_KEY_NAME --region $MY_AWS_REGION \
            --query 'KeyMaterial' --output text > $MY_PEM_KEY
        chmod 400 $MY_PEM_KEY

        # Persist to AWS Settings env
        echo MY_PEM_KEY_NAME=$MY_PEM_KEY_NAME >> $MY_CLOUD_PROVIDER_SETTINGS
    fi

    #
    # Define DNS entries
    MY_ROOT_DOMAIN=$(getDNSRootDomain "$MANIFEST_JSON")
    MY_DNS_ZONE="${MY_DEPLOYMENT_ID}.${MY_AWS_REGION}"

    # Persist to AWS Settings env
    echo MY_ROOT_DOMAIN=$MY_ROOT_DOMAIN >> $MY_CLOUD_PROVIDER_SETTINGS
    echo MY_DNS_ZONE=$MY_DNS_ZONE >> $MY_CLOUD_PROVIDER_SETTINGS

    # Get the root zone ID
    root_zone_hosted_id=$(aws route53 list-hosted-zones-by-name \
        --region $MY_AWS_REGION \
        --dns-name $MY_ROOT_DOMAIN \
        --max-items 1 \
        --query "HostedZones[].Id" \
        --output text | awk -F/ '{ print $NF }')
    log "Root zone ($MY_ROOT_DOMAIN) hosted ID set to $root_zone_hosted_id"

    #
    # Initialise base infra
    MY_STACK_NAME=${MY_DEPLOYMENT_ID}-infra
    result="$(aws cloudformation create-stack \
        --region $MY_AWS_REGION \
        --stack-name $MY_STACK_NAME \
        --template-body file:///usr/share/misc/aws-cloud-infra-cloudformation.yml \
        --parameters \
            ParameterKey=AvailabilityZone,ParameterValue=${MY_AWS_ZONE} \
            ParameterKey=KeyName,ParameterValue=${MY_PEM_KEY_NAME} \
            ParameterKey=DeploymentId,ParameterValue=${MY_DEPLOYMENT_ID} \
            ParameterKey=DomainName,ParameterValue=${MY_DNS_ZONE}.${MY_ROOT_DOMAIN} \
            ParameterKey=RootZoneHostedId,ParameterValue=${root_zone_hosted_id} \
        --capabilities CAPABILITY_IAM \
        --query 'StackId' --output text)"

    log "Creating CloudFormation stack $result"
    waitForStackCreate $MY_STACK_NAME
fi

#
# DESTROY logic
#
if [ "$ACTION" = "destroy" ]; then
    #
    # Init config
    initAWSInfraConfig

    #
    # Delete CloudFormation stack
    deleteCloudFormationStack ${MY_DEPLOYMENT_ID}-infra

    #
    # Delete keypair
    log "Deleting PEM keypair with name $MY_PEM_KEY_NAME..."
    aws ec2 delete-key-pair --key-name $MY_PEM_KEY_NAME --region $MY_AWS_REGION
fi