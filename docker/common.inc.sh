VM_ARCH="$(uname -m)"
VM_BUILD_DIR="/build"
VM_OUTPUT_DIR="/output"

function log_stage () {
    echo "$(tput setaf 2; tput bold)$@$(tput sgr0)"
}

function retry_command () {
    local attempts="$1"
    local delay_secs="$2"
    local attempt
    shift 2

    for (( attempt=1; attempt<=attempts; attempt++ )); do
        if "$@"; then
            return 0
        fi

        if (( attempt < attempts )); then
            echo "Command failed (attempt ${attempt}/${attempts}), retrying in ${delay_secs}s: $*" >&2
            sleep "$delay_secs"
        fi
    done

    echo "Command failed after ${attempts} attempts: $*" >&2
    return 1
}
