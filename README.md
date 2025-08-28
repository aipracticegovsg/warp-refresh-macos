# WARP Refresh for macOS

A macOS version of the [Windows WARP refresh script](https://github.com/dsaidgovsg/warp-refresh) that periodically refreshes Cloudflare WARP's auto-connect timeout to prevent unexpected reconnections.

## What it does

This script helps prevent interruptions during video calls or unexpected TLS certificate errors by refreshing WARP's auto-connect timeout. It:

1. Checks if WARP is currently disconnected
2. If disconnected, performs a quick connect-disconnect cycle to refresh the timeout
3. Logs all activities with timestamps
4. Maintains a log file with a maximum of 100 lines

**Important**: The script only acts when WARP is in disconnected state. If you prefer to keep WARP connected, this script will do nothing.

## Prerequisites

- macOS with Cloudflare WARP installed
- WARP CLI tools available (usually installed with the WARP app)
- Basic familiarity with Terminal

## Installation

### Quick Installation

1. **Download the files**:
   ```bash
   # Create a directory for the script
   mkdir -p ~/Documents/warp-refresh
   cd ~/Documents/warp-refresh
   
   # Download the script
   curl -O https://raw.githubusercontent.com/YOUR_USERNAME/warp-refresh-mac/main/warp-refresh.sh
   
   # Make it executable
   chmod +x warp-refresh.sh
   ```

2. **Set up the scheduled task**:
   ```bash
   # Download the plist template
   curl -O https://raw.githubusercontent.com/YOUR_USERNAME/warp-refresh-mac/main/com.warp.refresh.plist
   
   # Update the plist with correct paths
   sed -i '' "s|SCRIPT_PATH_PLACEHOLDER|$HOME/Documents/warp-refresh/warp-refresh.sh|g" com.warp.refresh.plist
   sed -i '' "s|WORKING_DIR_PLACEHOLDER|$HOME/Documents/warp-refresh|g" com.warp.refresh.plist
   
   # Copy to LaunchAgents directory
   cp com.warp.refresh.plist ~/Library/LaunchAgents/
   
   # Load the scheduled task
   launchctl load ~/Library/LaunchAgents/com.warp.refresh.plist
   ```

### Manual Installation

1. **Create the script directory**:
   ```bash
   mkdir -p ~/Documents/warp-refresh
   cd ~/Documents/warp-refresh
   ```

2. **Create the script file** (`warp-refresh.sh`):
   Copy the contents from `warp-refresh.sh` in this repository and save it to `~/Documents/warp-refresh/warp-refresh.sh`

3. **Make the script executable**:
   ```bash
   chmod +x ~/Documents/warp-refresh/warp-refresh.sh
   ```

4. **Create the plist file**:
   Copy the contents from `com.warp.refresh.plist` and save it as `~/Library/LaunchAgents/com.warp.refresh.plist`
   
   **Important**: Replace the placeholders in the plist file:
   - Replace `SCRIPT_PATH_PLACEHOLDER` with the full path to your script (e.g., `/Users/yourusername/Documents/warp-refresh/warp-refresh.sh`)
   - Replace `WORKING_DIR_PLACEHOLDER` with the directory containing the script (e.g., `/Users/yourusername/Documents/warp-refresh`)

5. **Load the scheduled task**:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.warp.refresh.plist
   ```

## Usage

### Starting the scheduled task
```bash
launchctl load ~/Library/LaunchAgents/com.warp.refresh.plist
```

### Stopping the scheduled task
```bash
launchctl unload ~/Library/LaunchAgents/com.warp.refresh.plist
```

### Checking if the task is running
```bash
launchctl list | grep com.warp.refresh
```

### Running the script manually (for testing)
```bash
cd ~/Documents/warp-refresh
./warp-refresh.sh
```

### Viewing logs
The script creates a log file in the same directory:
```bash
tail -f ~/Documents/warp-refresh/warp-refresh.log
```

## Configuration

### Changing the schedule interval
Edit the plist file and modify the `StartInterval` value (in seconds):
- 3600 = 1 hour (default, same as Windows version)
- 1800 = 30 minutes
- 900 = 15 minutes

After changing, reload the task:
```bash
launchctl unload ~/Library/LaunchAgents/com.warp.refresh.plist
launchctl load ~/Library/LaunchAgents/com.warp.refresh.plist
```

### Changing the log file location
Edit the `LOG_FILE` variable in the script to point to your preferred location.

## Troubleshooting

### Check if WARP CLI is working
```bash
warp-cli status
```
This should show the current WARP status.

### Check launchd logs
```bash
# View system logs for our service
log show --predicate 'subsystem == "com.apple.launchd"' --info --last 1h | grep warp.refresh

# Or check the output files
cat /tmp/warp-refresh.out
cat /tmp/warp-refresh.err
```

### Verify the scheduled task is loaded
```bash
launchctl list | grep com.warp.refresh
```

### Test the script manually
```bash
cd ~/Documents/warp-refresh
./warp-refresh.sh
cat warp-refresh.log
```

## Uninstallation

To completely remove the scheduled task:

```bash
# Stop and unload the task
launchctl unload ~/Library/LaunchAgents/com.warp.refresh.plist

# Remove the plist file
rm ~/Library/LaunchAgents/com.warp.refresh.plist

# Optionally remove the script directory
rm -rf ~/Documents/warp-refresh
```

## How it works

The script uses the same logic as the Windows version:

1. **Status Check**: Uses `warp-cli status` to check if WARP is disconnected
2. **Refresh Action**: If disconnected, runs `warp-cli connect` followed immediately by `warp-cli disconnect`
3. **Logging**: All actions are logged with timestamps to `warp-refresh.log`
4. **Log Management**: Keeps only the last 100 log lines to prevent disk space issues
5. **Scheduling**: Uses macOS launchd (instead of Windows Task Scheduler) to run every hour

## Differences from Windows version

- Uses bash shell script instead of VBScript
- Uses launchd instead of Windows Task Scheduler
- Uses Unix-style paths and commands
- Includes better error handling for missing WARP installation
- Uses `mktemp` for safe temporary file handling

## Security Notes

- The script runs with your user privileges (no root access required)
- All operations are logged for transparency
- The script only interacts with the WARP CLI, no system modifications
- Log files are created in the script directory with standard user permissions

## Contributing

Feel free to submit issues or pull requests to improve the script or documentation.

## License

This project maintains the same spirit as the original Windows version - helping developers maintain stable WARP connections during work sessions.
