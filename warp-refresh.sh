#!/bin/bash

# warp-refresh.sh - Mac version of WARP refresh script
# 
# This script assumes WARP to be in paused / disconnected mode.
# Since warp-cli no longer allows checking of auto-connect timeout value,
# the script now simply connects and immediately disconnects to refresh the value if the current status is disconnected.
# That means, this script intentionally does nothing should the user leaves the WARP in connected mode.

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
LOG_FILE="/tmp/${SCRIPT_NAME}.log"
MAX_LOG_LINES=100

# Function to write to log file with timestamp
write_to_log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$LOG_FILE"
}

# Function to check if WARP is disconnected
is_disconnected() {
    local status_output
    status_output=$(warp-cli status 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        write_to_log "ERROR: warp-cli command failed. Is Cloudflare WARP installed?"
        return 2
    fi
    
    # Extract status from the first line after "Status update: "
    local status
    status=$(echo "$status_output" | head -n1 | cut -d':' -f2 | xargs)
    
    if [[ "$status" == "Disconnected" ]]; then
        return 0  # true - is disconnected
    else
        return 1  # false - is connected or other state
    fi
}

# Function to connect and immediately disconnect WARP
connect_and_disconnect() {
    write_to_log "Executing warp-cli connect..."
    warp-cli connect >/dev/null 2>&1
    
    write_to_log "Executing warp-cli disconnect..."
    warp-cli disconnect >/dev/null 2>&1
}

# Function to trim log file to keep only the last MAX_LOG_LINES
trim_log_file() {
    if [[ -f "$LOG_FILE" ]]; then
        local line_count
        line_count=$(wc -l < "$LOG_FILE")
        
        if [[ $line_count -gt $MAX_LOG_LINES ]]; then
            local temp_file
            temp_file=$(mktemp)
            tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$temp_file"
            mv "$temp_file" "$LOG_FILE"
            write_to_log "Log file trimmed to $MAX_LOG_LINES lines"
        fi
    fi
}

# Main execution
main() {
    # Check if WARP is disconnected
    if is_disconnected; then
        write_to_log "WARP is currently disconnected, will perform connect-disconnect to refresh timeout..."
        connect_and_disconnect
        write_to_log "WARP auto-connect timeout refresh complete"
    else
        local exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            # Error already logged in is_disconnected function
            exit 1
        else
            write_to_log "WARP does not seem to be in disconnected state, not performing any action"
        fi
    fi
    
    # Trim log file to prevent it from growing too large
    trim_log_file
}

# Run main function
main "$@"
