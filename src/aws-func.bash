#
# Set constants

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