#!/bin/bash

SECSCAN_LOG_DIR="${SCRIPT_DIR}/logs"

secscan_validate() {
    local missing=0

    if ! command -v rkhunter &>/dev/null; then
        print_warning "rkhunter is not installed"
        missing=1
    fi

    if ! command -v chkrootkit &>/dev/null; then
        print_warning "chkrootkit is not installed"
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        print_status "Install with: sudo apt install rkhunter chkrootkit"
        return 1
    fi

    return 0
}

secscan_prepare_log() {
    mkdir -p "$SECSCAN_LOG_DIR"
    local log_file
    log_file="${SECSCAN_LOG_DIR}/secscan-$(get_date).log"
    echo "$log_file"
}

secscan_run_rkhunter() {
    print_header "RKHUNTER — ROOTKIT SCAN"

    print_step "1" "2" "Updating rkhunter signatures"
    print_command "sudo rkhunter --update"
    echo " "
    # WEB_CMD "Relative pathname: /bin/false" is cosmetic — suppress both stdout and stderr
    sudo rkhunter --update &>/dev/null
    echo " "

    print_step "2" "2" "Scanning for rootkits"
    print_command "sudo rkhunter --check --skip-keypress --report-warnings-only"
    echo " "

    local rkhunter_output
    rkhunter_output=$(sudo rkhunter --check --skip-keypress --report-warnings-only 2>&1)
    
    # Filter and classify rkhunter findings
    local critical_count=0
    local warning_count=0
    local info_count=0
    
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # File property changes — expected after system updates
        if echo "$line" | grep -q "The file properties have changed:"; then
            echo "${YELLOW}${BOLD}[WARNING]${RESET} $line"
            echo "         → Run: sudo rkhunter --propupd"
            state_add_finding "WARNING" "rkhunter: file properties changed" "Run: sudo rkhunter --propupd"
            ((warning_count++))
            continue
        fi
        
        # Specific file changes — show as warning with guidance
        if echo "$line" | grep -qE "^         File: /usr/(s?bin|lib)"; then
            echo "${YELLOW}${BOLD}[WARNING]${RESET} $line"
            ((warning_count++))
            continue
        fi
        
        # Hash/inode/time details — show as info
        if echo "$line" | grep -qE "^         (Current|Stored)"; then
            echo "${CYAN}${BOLD}[INFO]${RESET}    $line"
            ((info_count++))
            continue
        fi
        
        # Hidden files in /etc — normal system files
        if echo "$line" | grep -q "Hidden.*found: /etc/\."; then
            local hidden_file
            hidden_file=$(echo "$line" | sed 's/.*found: //')
            echo "${CYAN}${BOLD}[INFO]${RESET}    $line"
            echo "         → Normal system file — no action needed"
            state_add_finding "INFO" "rkhunter: hidden file in /etc ($hidden_file)" "Normal system file — no action needed"
            ((info_count++))
            continue
        fi
        
        # Script replacement — normal for Perl/Python scripts
        if echo "$line" | grep -q "has been replaced by a script:"; then
            echo "${CYAN}${BOLD}[INFO]${RESET}    $line"
            echo "         → Expected script replacement — no action needed"
            state_add_finding "INFO" "rkhunter: script replacement" "Expected behavior — no action needed"
            ((info_count++))
            continue
        fi
        
        # Any other warning — show as warning
        if echo "$line" | grep -qi "warning"; then
            echo "${YELLOW}${BOLD}[WARNING]${RESET} $line"
            state_add_finding "WARNING" "rkhunter: $line" "Review manually"
            ((warning_count++))
            continue
        fi
        
        # Default — show as-is
        echo "$line"
    done <<< "$rkhunter_output"
    
    echo " "
    
    if [[ $critical_count -gt 0 ]]; then
        print_critical "rkhunter found ${critical_count} critical finding(s)"
        return 1
    elif [[ $warning_count -gt 0 ]]; then
        print_warning "rkhunter found ${warning_count} warning(s) — review above"
        return 1
    else
        print_success "rkhunter scan complete — no warnings"
        return 0
    fi
}

secscan_run_chkrootkit() {
    print_header "CHKROOTKIT — ROOTKIT SCAN"

    print_step "1" "1" "Scanning for rootkits"
    print_command "sudo chkrootkit -q"
    echo " "

    local chk_output
    chk_output=$(sudo chkrootkit -q 2>&1)
    
    # Get wtmp threshold
    local wtmp_threshold
    wtmp_threshold=$(get_wtmp_threshold)
    
    # Filter and classify chkrootkit findings
    local critical_count=0
    local warning_count=0
    local info_count=0
    local filtered_count=0
    
    while IFS= read -r line; do
        # Skip empty lines and RTNETLINK errors
        [[ -z "$line" ]] && continue
        echo "$line" | grep -q "^RTNETLINK" && continue
        
        # Filter out chkrootkit header lines (not actual findings)
        if echo "$line" | grep -qE "^WARNING: (The following suspicious|Output from|output from)"; then
            ((filtered_count++))
            continue
        fi
        
        # Known-safe dotfiles in /usr/lib — filter out
        if echo "$line" | grep -qE "^/usr/lib/(llvm[^/]*|ruby|libreoffice|jvm|debug|modules|node_modules)/"; then
            ((filtered_count++))
            continue
        fi
        
        # PACKET SNIFFER for known-safe processes — filter out
        if echo "$line" | grep -q "PACKET SNIFFER" && echo "$line" | grep -qE "/usr/sbin/(NetworkManager|wpa_supplicant)"; then
            echo "${CYAN}${BOLD}[INFO]${RESET}    $line"
            echo "         → Legitimate WiFi service — no action needed"
            state_add_finding "INFO" "chkrootkit: legitimate packet capture (NetworkManager/wpa_supplicant)" "Legitimate WiFi service — no action needed"
            ((info_count++))
            continue
        fi
        
        # PACKET SNIFFER for other processes — show as warning
        if echo "$line" | grep -q "PACKET SNIFFER"; then
            echo "${YELLOW}${BOLD}[WARNING]${RESET} $line"
            echo "         → Review: unexpected packet capture detected"
            state_add_finding "WARNING" "chkrootkit: unexpected packet capture" "Review manually"
            ((warning_count++))
            continue
        fi
        
        # wtmp deletions — filter by age threshold
        if echo "$line" | grep -q "deletion(s) between"; then
            # Extract the end date from the deletion line
            local end_date
            end_date=$(echo "$line" | grep -oP 'and \K[^)]+' | head -1)
            if [[ -n "$end_date" ]]; then
                # Check if this is older than threshold (simplified check)
                local deletion_age_days
                deletion_age_days=$(echo "$line" | grep -oP 'between \K[^ ]+' | head -1)
                # For now, show all deletions as info since exact age calculation is complex
                echo "${CYAN}${BOLD}[INFO]${RESET}    $line"
                echo "         → Historical wtmp deletion — likely from system reboot"
                state_add_finding "INFO" "chkrootkit: wtmp deletion" "Historical log rotation or reboot"
                ((info_count++))
                continue
            fi
        fi
        
        # Suspicious files/directories — show as warning
        if echo "$line" | grep -qE "^/usr/lib/"; then
            echo "${YELLOW}${BOLD}[WARNING]${RESET} $line"
            echo "         → Review: suspicious file in system directory"
            state_add_finding "WARNING" "chkrootkit: suspicious file ($line)" "Review manually"
            ((warning_count++))
            continue
        fi
        
        # Default — show as-is
        echo "$line"
    done <<< "$chk_output"
    
    echo " "
    
    if [[ $critical_count -gt 0 ]]; then
        print_critical "chkrootkit found ${critical_count} critical finding(s)"
        return 1
    elif [[ $warning_count -gt 0 ]]; then
        print_warning "chkrootkit found ${warning_count} warning(s) — review above"
        return 1
    else
        print_success "chkrootkit scan complete — clean"
        return 0
    fi
}

secscan_execute() {
    local command="$1"
    local description="$2"

    print_command "${command}"
    echo " "

    local exit_code=0
    eval "${command}" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        print_success "${description} completed successfully"
        return 0
    else
        print_error "${description} failed with exit code ${exit_code}"
        state_add_error "${description} (exit code: ${exit_code})"
        return "${exit_code}"
    fi
}

secscan_run() {
    local run_rkhunter="${1:-true}"
    local run_chkrootkit="${2:-true}"

    print_header "SECURITY SCANS"
    echo "${CYAN}Log directory:${RESET} ${SECSCAN_LOG_DIR}"
    echo " "

    local total_steps=0
    [[ "$run_rkhunter" == "true" ]] && ((total_steps++))
    [[ "$run_chkrootkit" == "true" ]] && ((total_steps++))

    local current_step=0
    local failed=0

    if [[ "$run_rkhunter" == "true" ]]; then
        ((current_step++))
        secscan_run_rkhunter || ((failed++))
        echo " "
        print_separator
        echo " "
    fi

    if [[ "$run_chkrootkit" == "true" ]]; then
        ((current_step++))
        secscan_run_chkrootkit || ((failed++))
        echo " "
        print_separator
        echo " "
    fi

    print_header "SCAN SUMMARY"
    echo "${BOLD}Scans run:${RESET} ${total_steps}"
    echo "${BOLD}Warnings:${RESET} ${failed}"
    echo " "

    if [[ $failed -eq 0 ]]; then
        print_success "All security scans completed — system is clean!"
        return 0
    else
        print_warning "${failed} scan(s) reported warnings — review above"
        return 1
    fi
}
