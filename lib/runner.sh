#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_DIR="${SCRIPT_DIR}/modules"
CONFIG_DIR="${SCRIPT_DIR}/config"
LOG_DIR="${SCRIPT_DIR}/logs"

module_load() {
    local module_name="$1"
    local module_file="${MODULE_DIR}/${module_name}.sh"

    if [[ ! -f "$module_file" ]]; then
        print_error "Module not found: $module_name"
        return 1
    fi

    source "$module_file"
}

module_validate() {
    local module_name="$1"
    module_load "$module_name"

    local validate_func="${module_name}_validate"
    if type "$validate_func" &>/dev/null; then
        "$validate_func"
        return $?
    fi
    return 0
}

module_run() {
    local module_name="$1"
    shift
    module_load "$module_name"

    local run_func="${module_name}_run"
    if type "$run_func" &>/dev/null; then
        "$run_func" "$@"
        return $?
    else
        print_error "Module $module_name has no run function"
        return 1
    fi
}

config_read() {
    local config_name="$1"
    local config_file="${CONFIG_DIR}/${config_name}.txt"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    grep -v '^#' "$config_file" | grep -v '^[[:space:]]*$'
}

config_get_packages() {
    local config_name="$1"
    config_read "$config_name"
}

get_log_file() {
    local date_str
    date_str=$(get_date)
    echo "${LOG_DIR}/${date_str}.log"
}