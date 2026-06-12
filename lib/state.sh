#!/bin/bash

declare -A STATE_VERSIONS=()
declare -a STATE_ERRORS=()
declare -a STATE_FAILED_PACKAGES=()
declare -a STATE_SEVERITY_CRITICAL=()
declare -a STATE_SEVERITY_WARNING=()
declare -a STATE_SEVERITY_INFO=()

state_set_version() {
    local package="$1"
    local version="$2"
    STATE_VERSIONS["$package"]="$version"
}

state_get_version() {
    local package="$1"
    echo "${STATE_VERSIONS[$package]}"
}

state_add_error() {
    local error="$1"
    STATE_ERRORS+=("$(get_datetime): $error")
}

state_add_failed_package() {
    local package="$1"
    STATE_FAILED_PACKAGES+=("$package")
}

state_has_errors() {
    [[ ${#STATE_ERRORS[@]} -gt 0 ]] || [[ ${#STATE_FAILED_PACKAGES[@]} -gt 0 ]]
}

state_get_errors() {
    printf '%s\n' "${STATE_ERRORS[@]}"
}

state_get_failed_packages() {
    printf '%s\n' "${STATE_FAILED_PACKAGES[@]}"
}

state_add_finding() {
    local severity="$1"
    local message="$2"
    local remediation="$3"
    local entry="$(get_datetime): ${message} | Remediation: ${remediation}"
    
    case "${severity}" in
        CRITICAL) STATE_SEVERITY_CRITICAL+=("$entry") ;;
        WARNING)  STATE_SEVERITY_WARNING+=("$entry") ;;
        INFO)     STATE_SEVERITY_INFO+=("$entry") ;;
    esac
}

state_get_findings_by_severity() {
    local severity="$1"
    case "${severity}" in
        CRITICAL) printf '%s\n' "${STATE_SEVERITY_CRITICAL[@]}" ;;
        WARNING)  printf '%s\n' "${STATE_SEVERITY_WARNING[@]}" ;;
        INFO)     printf '%s\n' "${STATE_SEVERITY_INFO[@]}" ;;
    esac
}

state_get_finding_count() {
    local severity="$1"
    case "${severity}" in
        CRITICAL) echo "${#STATE_SEVERITY_CRITICAL[@]}" ;;
        WARNING)  echo "${#STATE_SEVERITY_WARNING[@]}" ;;
        INFO)     echo "${#STATE_SEVERITY_INFO[@]}" ;;
    esac
}

state_log_to_file() {
    local log_file="$1"
    {
        echo "=== Maintenance Run - $(get_datetime) ==="
        if [[ ${#STATE_ERRORS[@]} -gt 0 ]]; then
            echo "Errors:"
            for err in "${STATE_ERRORS[@]}"; do
                echo "  $err"
            done
        fi
        if [[ ${#STATE_FAILED_PACKAGES[@]} -gt 0 ]]; then
            echo "Failed Packages:"
            for pkg in "${STATE_FAILED_PACKAGES[@]}"; do
                echo "  $pkg"
            done
        fi
        if [[ ${#STATE_SEVERITY_CRITICAL[@]} -gt 0 ]]; then
            echo "Critical Findings:"
            for finding in "${STATE_SEVERITY_CRITICAL[@]}"; do
                echo "  $finding"
            done
        fi
        if [[ ${#STATE_SEVERITY_WARNING[@]} -gt 0 ]]; then
            echo "Warning Findings:"
            for finding in "${STATE_SEVERITY_WARNING[@]}"; do
                echo "  $finding"
            done
        fi
        if [[ ${#STATE_SEVERITY_INFO[@]} -gt 0 ]]; then
            echo "Informational Findings:"
            for finding in "${STATE_SEVERITY_INFO[@]}"; do
                echo "  $finding"
            done
        fi
        echo ""
    } >> "$log_file"
}

state_clear() {
    unset STATE_VERSIONS
    unset STATE_ERRORS
    unset STATE_FAILED_PACKAGES
    unset STATE_SEVERITY_CRITICAL
    unset STATE_SEVERITY_WARNING
    unset STATE_SEVERITY_INFO
    declare -A STATE_VERSIONS=()
    declare -a STATE_ERRORS=()
    declare -a STATE_FAILED_PACKAGES=()
    declare -a STATE_SEVERITY_CRITICAL=()
    declare -a STATE_SEVERITY_WARNING=()
    declare -a STATE_SEVERITY_INFO=()
}
