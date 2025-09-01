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

# Use full path to warp-cli to avoid PATH issues with launchd
WARP_CLI="/usr/local/bin/warp-cli"

# Function to write to log file with timestamp
write_to_log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$LOG_FILE"
}

# Function to check if warp-cli is available
check_warp_cli() {
    if [[ ! -x "$WARP_CLI" ]]; then
        write_to_log "ERROR: warp-cli not found at $WARP_CLI. Is Cloudflare WARP installed?"
        return 1
    fi
    return 0
}

# Function to check if WARP is disconnected
is_disconnected() {
    local status_output
    local retry_count=0
    local max_retries=3
    
    # Check if warp-cli exists first
    if ! check_warp_cli; then
        return 2
    fi
    
    # Retry logic for warp-cli status command
    while [[ $retry_count -lt $max_retries ]]; do
        status_output=$("$WARP_CLI" status 2>/dev/null)
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            # Extract status from the first line after "Status update: "
            local status
            status=$(echo "$status_output" | head -n1 | cut -d':' -f2 | xargs)
            
            if [[ "$status" == "Disconnected" ]]; then
                return 0  # true - is disconnected
            else
                return 1  # false - is connected or other state
            fi
        else
            retry_count=$((retry_count + 1))
            if [[ $retry_count -lt $max_retries ]]; then
                write_to_log "WARNING: warp-cli status failed (attempt $retry_count/$max_retries), retrying in 2 seconds..."
                sleep 2
            else
                write_to_log "ERROR: warp-cli status failed after $max_retries attempts. WARP service may be temporarily unavailable."
                return 2
            fi
        fi
    done
}

# Function to connect and immediately disconnect WARP
connect_and_disconnect() {
    write_to_log "Executing warp-cli connect..."
    if "$WARP_CLI" connect >/dev/null 2>&1; then
        write_to_log "Connect command successful"
    else
        write_to_log "WARNING: Connect command failed, but continuing with disconnect"
    fi
    
    # Small delay to ensure connect command is processed
    sleep 1
    
    write_to_log "Executing warp-cli disconnect..."
    if "$WARP_CLI" disconnect >/dev/null 2>&1; then
        write_to_log "Disconnect command successful"
    else
        write_to_log "WARNING: Disconnect command failed"
    fi
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
    write_to_log "Script started"
    
    # Check if WARP is disconnected
    if is_disconnected; then
        write_to_log "WARP is currently disconnected, will perform connect-disconnect to refresh timeout..."
        connect_and_disconnect
        write_to_log "WARP auto-connect timeout refresh complete"
    else
        local exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            # Error already logged in is_disconnected function
            write_to_log "Script exiting due to warp-cli availability issues"
            exit 1
        else
            write_to_log "WARP does not seem to be in disconnected state, not performing any action"
        fi
    fi
    
    # Trim log file to prevent it from growing too large
    trim_log_file
    
    write_to_log "Script completed"
}

# Run main function
main "$@"
