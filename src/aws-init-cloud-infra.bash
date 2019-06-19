#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash
source /usr/share/misc/aws-func.bash

#
# Usage function
function usage {
    echo "Usage: $0 --manifest=/path/to/infra-manifest.json --config-data=/path/to/config-dir"
}

# Set defaults
# Nothing

for i in "$@"; do
    case $i in
        -m=*|--manifest=*)
        MANIFEST="${i#*=}"
        shift # past argument=value
        ;;
        -c=*|--config-data=*)
        INFRA_DIR="${i#*=}"
        shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [ -z "$MANIFEST" -o ! -f "$MANIFEST" ]; then
    log ERROR "You need to specify a valid path to the infra manifest JSON file."
    log WARN "$(usage)"
    log WARN "Exit process with error code 102."
    exit 102
fi

if [ -z "$INFRA_DIR" -o ! -d "$INFRA_DIR" ]; then
    log ERROR "You need to specify a valid path to the config data directory (needs to exist)."
    log WARN "$(usage)"
    log WARN "Exit process with error code 103."
    exit 103
fi

if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" ]; then
    log ERROR "AWS Access or Secret keys not found in environment, exit."
    log WARN "Exit process with error code 200."
    exit 200
fi

# Read and verify the manifest
log "Reading and validating infra manifest..."
MANIFEST_JSON=$(cat $MANIFEST)
verifyJSON "$MANIFEST_JSON"

#
# Set initial deployment config
MY_AWS_SETTINGS=$INFRA_DIR/aws-settings.properties

if [ ! -f $MY_AWS_SETTINGS ]; then
    MY_AWS_REGION=$(getAwsRegion "$MANIFEST_JSON")
    MY_AWS_ZONE=${MY_AWS_REGION}a
    MY_DEPLOYMENT_ID=$(getDeploynmentId "$MANIFEST_JSON")
    MY_PEM_KEY=$INFRA_DIR/aws-keypair.pem

    echo MY_AWS_REGION=$MY_AWS_REGION > $MY_AWS_SETTINGS
    echo MY_AWS_ZONE=$MY_AWS_ZONE >> $MY_AWS_SETTINGS
    echo MY_DEPLOYMENT_ID=$MY_DEPLOYMENT_ID >> $MY_AWS_SETTINGS
    echo MY_PEM_KEY=$MY_PEM_KEY >> $MY_AWS_SETTINGS
fi 

#
# Source settings
source $MY_AWS_SETTINGS

#
# Generate pipeline keypair
if [ ! -f $MY_PEM_KEY ]; then
    MY_PEM_KEY_NAME=pipeline-${MY_DEPLOYMENT_ID}-${MY_AWS_REGION}
    
    log "Generating PEM keypair with name $MY_PEM_KEY_NAME..."
    aws ec2 create-key-pair --key-name $MY_PEM_KEY_NAME --region $MY_AWS_REGION \
        --query 'KeyMaterial' --output text > $MY_PEM_KEY
    chmod 400 $MY_PEM_KEY

    echo MY_PEM_KEY_NAME=pipeline-${MY_DEPLOYMENT_ID}-${MY_AWS_REGION} >> $MY_AWS_SETTINGS
fi

#
# Initialise base infra
STACK_NAME=${MY_DEPLOYMENT_ID}-infra
log "Creating Cloudformation stack $STACK_NAME"
aws cloudformation create-stack \
 --region $MY_AWS_REGION \
 --stack-name $STACK_NAME \
 --template-body file:///usr/share/misc/aws-cloud-infra-cloudformation.yml \
 --parameters \
   ParameterKey=AvailabilityZone,ParameterValue=${MY_AWS_ZONE} \
   ParameterKey=KeyName,ParameterValue=${MY_PEM_KEY_NAME} \
   ParameterKey=DeploymentId,ParameterValue=${MY_DEPLOYMENT_ID}  \
 --capabilities CAPABILITY_IAM

waitForStackCreate $STACK_NAME