#
# Set constants
PROCESS_DIR=$(cd "$(dirname "$0")"; pwd)
PROCESS_NAME=$(basename "$0")

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}

#
# Log function
function log {
    # Set default loglevel to INFO
    if [ -z "$2" ]; then
        loglevel=INFO
        message=$1
    else
        loglevel=$(echo $1 | tr [a-z] [A-Z])
        message=$2
    fi

    # Log so stderr in case of ERROR or FATAL
    if [ "$loglevel" = "ERROR" -o "$loglevel" = "FATAL" ]; then
        printf "%s %-6s %s %s\n" "$(date)" "${loglevel}" "(${PROCESS_NAME})" "${message}" >&2
    else
        printf "%s %-6s %s %s\n" "$(date)" "${loglevel}" "(${PROCESS_NAME})" "${message}"
    fi
}

function echoerr { 
    echo "$@" 1>&2;
}

#
# Verify manifest, pass JSON as first argument
function verifyJSON {
    if jq -e . >/dev/null 2>&1 <<<"$1"; then
        log "Parsed manifest successfully."
    else
        log ERROR "Failed to parse JSON, exit!"
        log WARN "Exit process with error code 900."
        exit 900
    fi
}

function getDeploynmentId {
    echo $1 | jq -r '.id'
}

function createInfraDir {
    if [ ! -d ./infra ]; then
       mkdir -p ./infra
    fi
}