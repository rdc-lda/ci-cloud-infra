#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

# Initialise the cloud infra module (generic interface)
initInfraModule $@

# Get name of the module
MODULE=$(basename $0)

INFRA_PROVIDER=$(echo $MANIFEST_JSON | jq -r '.["infra-provider"]')

if [ -f "/usr/bin/${INFRA_PROVIDER}-$MODULE" ]; then
    log "Starting $ACTION cycle for provider $INFRA_PROVIDER"
else
    log ERROR "Provider for $INFRA_PROVIDER not (yet) supported."
    log WARN "Exit process with error code 103."
    exit 103
fi

# Invoke the infra provider
/usr/bin/${INFRA_PROVIDER}-$MODULE --manifest=$MANIFEST --config-data=$INFRA_DIR --action=$ACTION