
#!/bin/bash

# Fail the script if any command returns a non-zero value
set -e

# Slurp in some functions...
source /usr/share/misc/func.bash

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

log "Reading and validating infra manifest..."
MANIFEST_JSON=$(cat $MANIFEST)
verifyJSON "$MANIFEST_JSON"

INFRA_PROVIDER=$(echo $MANIFEST_JSON | jq -r '.["infra-provider"]')

if [ -f "/usr/bin/${INFRA_PROVIDER}-init-cloud-infra" ]; then
    log "Configuring for infra provider $INFRA_PROVIDER"
else
    log ERROR "Infra provider $INFRA_PROVIDER not supported."
    log WARN "Exit process with error code 103."
    exit 103
fi

# Invoke the infra provider
/usr/bin/${INFRA_PROVIDER}-init-cloud-infra --manifest=$MANIFEST --config-data=$INFRA_DIR