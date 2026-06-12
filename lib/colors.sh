#!/bin/bash

init_colors() {
    if [[ -t 1 ]] && command -v tput &>/dev/null && [[ -n "${TERM:-}" ]]; then
        readonly BOLD=$(tput bold 2>/dev/null || printf '')
        readonly GREEN=$(tput setaf 2 2>/dev/null || printf '')
        readonly RED=$(tput setaf 1 2>/dev/null || printf '')
        readonly BLUE=$(tput setaf 4 2>/dev/null || printf '')
        readonly CYAN=$(tput setaf 6 2>/dev/null || printf '')
        readonly MAGENTA=$(tput setaf 5 2>/dev/null || printf '')
        readonly YELLOW=$(tput setaf 3 2>/dev/null || printf '')
        readonly RESET=$(tput sgr0 2>/dev/null || printf '')
    else
        readonly BOLD=''
        readonly GREEN=''
        readonly RED=''
        readonly BLUE=''
        readonly CYAN=''
        readonly MAGENTA=''
        readonly YELLOW=''
        readonly RESET=''
    fi
}