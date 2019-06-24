#
# Set constants

function initAWSInfraModule {
    if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" ]; then
        log ERROR "AWS Access or Secret keys not found in environment, exit."
        log WARN "Exit process with error code 200."
        exit 200
    fi

    #
    # Set cloud provider config path and file
    MY_CLOUD_PROVIDER_SETTINGS=$INFRA_DIR/aws-settings.properties
}

function initAWSInfraConfig {
    #
    # Source settings
    if [ -f $MY_CLOUD_PROVIDER_SETTINGS ]; then
        source $MY_CLOUD_PROVIDER_SETTINGS
    else
        log ERROR "Cloud Provider settings ($MY_CLOUD_PROVIDER_SETTINGS) not found in workspace, exit."
        log WARN "Exit process with error code 201."
        exit 201
    fi
}

function deleteCloudFormationStack {
    #
    # Remove CloudFormation template
    STACK_NAME=$1
    set +e
    aws cloudformation delete-stack \
        --region $MY_AWS_REGION \
        --stack-name $STACK_NAME &> /dev/null
    set -e

    log "Deleting CloudFormation stack $STACK_NAME"
    waitForStackDelete $STACK_NAME
}

#
# Pass JSON and instance name
function getAwsInstanceCount {
    echo $1 | jq -r '.["aws-settings"].instances | .["'$2'"].count'
}

function getAwsInstanceType {
    echo $1 | jq -r '.["aws-settings"].instances | .["'$2'"].type'
}

function getAwsInstanceDataVolumeSize {
    echo $1 | jq -r '.["aws-settings"].instances | .["'$2'"] | .["data-volume-size"]'
}

function getAwsInstanceLogVolumeSize {
    echo $1 | jq -r '.["aws-settings"].instances | .["'$2'"] | .["log-volume-size"]'
}

function getAwsRegion {
    echo $1 | jq -r '.["aws-settings"].region'
}

function waitForStackCreate {
    set +e
    while [ true ]; do
        status=$(aws cloudformation describe-stacks \
        --region $MY_AWS_REGION \
        --stack-name $1 \
        --query "Stacks[][StackStatus]" \
        --output text)

        if [ "$status" = "CREATE_COMPLETE" ]; then
            log "CloudFormation stack $1 created successfully."
            break
        fi

        if [ "$status" = "ROLLBACK_COMPLETE" ]; then
            log ERROR "An error occured during CloudFormation create stage for $1!"
            log ERROR "Check the AWS Console, correct issue and delete the failed stack before retry"
            exit 1
        else
            log "CloudFormation stack $1 create in progres..."
            sleep 5
        fi

    done
    set -e
}

function waitForStackDelete {
    set +e
    while [ true ]; do   
        aws cloudformation describe-stacks \
        --region $MY_AWS_REGION \
        --stack-name $1 \
        --query "Stacks[][StackStatus]" &> /dev/null

        if [ ! "$?" = "0" ]; then
            log "CloudFormation stack $1 deleted successfully."
            break
        else
            log "CloudFormation stack $1 delete in progres..."
            sleep 5
        fi
    done
    set -e
}