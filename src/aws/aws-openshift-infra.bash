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
TEMPLATE=/usr/share/misc/aws-openshift-infra-cloudformation.yml.sempl

#
# INIT logic
#
if [ "$ACTION" = "init" ]; then
    #
    # Get reference VpcId from Infra CloudFormation deployment
    infra_vpc_id=$(aws cloudformation describe-stacks \
    --region $MY_AWS_REGION \
    --stack-name ${MY_DEPLOYMENT_ID}-infra \
    --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
    --output text)
    log "Infra VPC ID set to $infra_vpc_id"

    infra_vpc_routetable_id=$(aws cloudformation describe-stacks \
    --region $MY_AWS_REGION \
    --stack-name ${MY_DEPLOYMENT_ID}-infra \
    --query 'Stacks[0].Outputs[?OutputKey==`VpcRouteTable`].OutputValue' \
    --output text)
    log "Infra VPC RouteTable ID set to $infra_vpc_routetable_id"

    #
    # Get machine sizing
    for machine in master infra worker; do
        declare -x ${machine}_node_count=$(getAwsInstanceCount "$MANIFEST_JSON" openshift-${machine})
        declare -x ${machine}_node_type=$(getAwsInstanceType "$MANIFEST_JSON" openshift-${machine})
        declare -x ${machine}_node_data_volume_size=$(getAwsInstanceDataVolumeSize "$MANIFEST_JSON" openshift-${machine})
        declare -x ${machine}_node_log_volume_size=$(getAwsInstanceLogVolumeSize "$MANIFEST_JSON" openshift-${machine})
    done

    #
    # Merge into template (for number of machines)
    log "Merging infra manifest settings into OpenShift Cloudformation template..."
    sempl -o $TEMPLATE > aws-openshift-infra-cloudformation.yml

    #
    # Initialise infra
    STACK_NAME=${MY_DEPLOYMENT_ID}-openshift

    #
    # ${machine}_node_count is picked up in template
    result="$(aws cloudformation create-stack \
        --region $MY_AWS_REGION \
        --stack-name $STACK_NAME \
        --template-body file://aws-openshift-infra-cloudformation.yml \
        --parameters \
            ParameterKey=InfraVPC,ParameterValue=${infra_vpc_id} \
            ParameterKey=InfraVPCRouteTable,ParameterValue=${infra_vpc_routetable_id} \
            ParameterKey=AvailabilityZone,ParameterValue=${MY_AWS_ZONE} \
            ParameterKey=KeyName,ParameterValue=${MY_PEM_KEY_NAME} \
            ParameterKey=DeploymentId,ParameterValue=${MY_DEPLOYMENT_ID} \
            ParameterKey=OpenshiftMasterInstanceType,ParameterValue=${master_node_type} \
            ParameterKey=OpenshiftInfraInstanceType,ParameterValue=${infra_node_type} \
            ParameterKey=OpenshiftWorkerInstanceType,ParameterValue=${worker_node_type} \
            ParameterKey=OpenshiftMasterDataVolumeSize,ParameterValue=${master_node_data_volume_size} \
            ParameterKey=OpenshiftInfraDataVolumeSize,ParameterValue=${infra_node_data_volume_size} \
            ParameterKey=OpenshiftWorkerDataVolumeSize,ParameterValue=${worker_node_data_volume_size} \
            ParameterKey=OpenshiftMasterLogVolumeSize,ParameterValue=${master_node_log_volume_size} \
            ParameterKey=OpenshiftInfraLogVolumeSize,ParameterValue=${infra_node_log_volume_size} \
            ParameterKey=OpenshiftWorkerLogVolumeSize,ParameterValue=${worker_node_log_volume_size} \
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
    # Delete CloudFormation stack
    deleteCloudFormationStack ${MY_DEPLOYMENT_ID}-openshift
fi