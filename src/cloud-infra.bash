#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

# Initialise the cloud infra module (generic interface)
initModule $@

INFRA_PROVIDER=$(echo $MANIFEST_JSON | jq -r '.["infra-provider"]')

if [ -f "/usr/bin/${INFRA_PROVIDER}-cloud-infra" ]; then
    log "Starting $ACTION cycle for infra provider $INFRA_PROVIDER"
else
    log ERROR "Cloud infra provider $INFRA_PROVIDER not (yet) supported."
    log WARN "Exit process with error code 103."
    exit 103
fi

# Invoke the infra provider
/usr/bin/${INFRA_PROVIDER}-cloud-infra --manifest=$MANIFEST --config-data=$INFRA_DIR --action=$ACTION