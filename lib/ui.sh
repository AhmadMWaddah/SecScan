#!/bin/bash

print_header() {
    local message="$1"
    echo " "
    echo "${MAGENTA}${BOLD}=====================================================================${RESET}"
    echo "${MAGENTA}${BOLD}  ${message}${RESET}"
    echo "${MAGENTA}${BOLD}=====================================================================${RESET}"
    echo " "
}

print_status() {
    echo "${CYAN}${BOLD}[INFO]${RESET} $1"
}

print_success() {
    echo "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

print_error() {
    echo "${RED}${BOLD}[ERROR]${RESET} $1"
}

print_warning() {
    echo "${YELLOW}${BOLD}[WARNING]${RESET} $1"
}

print_critical() {
    echo "${RED}${BOLD}[CRITICAL]${RESET} $1"
}

print_info() {
    echo "${CYAN}${BOLD}[INFO]${RESET} $1"
}

print_action_required() {
    echo " "
    echo "${RED}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
    echo "${RED}${BOLD}  ACTION REQUIRED — Review and fix these findings${RESET}"
    echo "${RED}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
    echo " "
}

print_no_action() {
    echo " "
    echo "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
    echo "${GREEN}${BOLD}  NO ACTION NEEDED — Informational findings only${RESET}"
    echo "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${RESET}"
    echo " "
}

print_step() {
    local current="$1"
    local total="$2"
    local description="$3"
    echo "${BLUE}${BOLD}[${current}/${total}]${RESET} ${BOLD}${description}${RESET}"
}

print_command() {
    local command="$1"
    echo "${CYAN}Command:${RESET} ${command}"
}

print_separator() {
    echo "${CYAN}────────────────────────────────────────────────────────────────${RESET}"
}

print_final_summary() {
    local execution_time="$1"
    local total_selected="${2:-0}"

    print_header "MAINTENANCE PROCESS COMPLETED"

    echo "${BOLD}Tasks Executed:${RESET} ${total_selected}"
    echo "${BOLD}Total Execution Time:${RESET} $(format_duration "${execution_time}")"
    echo "${BOLD}Finished at:${RESET} $(date)"
    echo " "
    print_status "System maintenance process finished at $(date)"
}
