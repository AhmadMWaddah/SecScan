#!/bin/bash

get_timestamp() {
    date +%s
}

format_duration() {
    local seconds="$1"
    echo "${seconds} seconds"
}

get_date() {
    date +%Y-%m-%d
}

get_datetime() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Default threshold for wtmp deletion filtering (in days)
SECSCAN_WTMP_THRESHOLD_DAYS=30

get_wtmp_threshold() {
    echo "${SECSCAN_WTMP_THRESHOLD_DAYS}"
}

days_since_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi
    local file_mod_time
    file_mod_time=$(stat -c %Y "$file" 2>/dev/null || echo "0")
    local current_time
    current_time=$(date +%s)
    local diff_seconds=$((current_time - file_mod_time))
    local diff_days=$((diff_seconds / 86400))
    echo "${diff_days}"
}

isolder_than_days() {
    local file="$1"
    local days="$2"
    local file_age
    file_age=$(days_since_file "$file")
    if [[ "$file_age" -ge "$days" ]]; then
        return 0  # true - file is older than threshold
    else
        return 1  # false - file is newer than threshold
    fi
}
