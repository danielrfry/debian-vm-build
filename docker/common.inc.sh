VM_ARCH="$(uname -m)"
VM_BUILD_DIR="/build"
VM_OUTPUT_DIR="/output"

function log_stage () {
    echo "$(tput setaf 2; tput bold)$@$(tput sgr0)"
}
