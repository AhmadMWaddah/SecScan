#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
MODULE_DIR="${SCRIPT_DIR}/modules"

for lib_file in "${LIB_DIR}"/*.sh; do
    source "$lib_file"
done

set +e

run_all_modules() {
    local start_time end_time execution_time
    start_time=$(get_timestamp)

    module_run "secscan" "true" "true"

    end_time=$(get_timestamp)
    execution_time=$((end_time - start_time))

    if state_has_errors; then
        local log_file
        log_file=$(get_log_file)
        state_log_to_file "$log_file"
    fi

    print_scan_summary "${execution_time}" "1"
}

print_scan_summary() {
    local execution_time="$1"
    local total_selected="${2:-0}"

    # Get severity counts
    local critical_count
    local warning_count
    local info_count
    critical_count=$(state_get_finding_count "CRITICAL")
    warning_count=$(state_get_finding_count "WARNING")
    info_count=$(state_get_finding_count "INFO")
    local total_findings=$((critical_count + warning_count + info_count))

    print_header "SECURITY SCAN COMPLETED"

    echo "${BOLD}Tasks Executed:${RESET} ${total_selected}"
    echo "${BOLD}Total Execution Time:${RESET} $(format_duration "${execution_time}")"
    echo "${BOLD}Finished at:${RESET} $(date)"
    echo " "

    # Severity summary
    echo "${BOLD}Findings Summary:${RESET}"
    echo "  ${RED}${BOLD}Critical:${RESET} ${critical_count}"
    echo "  ${YELLOW}${BOLD}Warning:${RESET}  ${warning_count}"
    echo "  ${CYAN}${BOLD}Info:${RESET}     ${info_count}"
    echo "  ${BOLD}Total:${RESET}   ${total_findings}"
    echo " "

    # Action Required section
    if [[ $critical_count -gt 0 || $warning_count -gt 0 ]]; then
        print_action_required
        
        if [[ $critical_count -gt 0 ]]; then
            echo "${RED}${BOLD}Critical Findings:${RESET}"
            state_get_findings_by_severity "CRITICAL" | while IFS= read -r finding; do
                echo "  • ${finding}"
            done
            echo " "
        fi
        
        if [[ $warning_count -gt 0 ]]; then
            echo "${YELLOW}${BOLD}Warning Findings:${RESET}"
            state_get_findings_by_severity "WARNING" | while IFS= read -r finding; do
                echo "  • ${finding}"
            done
            echo " "
        fi
    fi

    # No Action Needed section
    if [[ $info_count -gt 0 ]]; then
        print_no_action
        echo "${CYAN}${BOLD}Informational Findings:${RESET}"
        state_get_findings_by_severity "INFO" | while IFS= read -r finding; do
            echo "  • ${finding}"
        done
        echo " "
    fi

    # Final status
    if [[ $total_findings -eq 0 ]]; then
        print_success "All security scans completed — system is clean!"
    elif [[ $critical_count -eq 0 && $warning_count -eq 0 ]]; then
        print_success "No action required — all findings are informational"
    else
        print_warning "Review findings above and take action where needed"
    fi
}

main() {
    init_colors
    run_all_modules
}

if [[ "${1:-}" == "help" || "${1:-}" == "-h" ]]; then
    init_colors
    echo " "
    echo "Usage: ./SecScan.sh"
    echo " "
    echo "This script runs all security scan tasks automatically:"
    echo "  1. rkhunter — rootkit and malware scan"
    echo "  2. chkrootkit — additional rootkit scan"
    echo " "
    exit 0
fi

main "$@"
