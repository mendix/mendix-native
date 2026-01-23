#!/bin/bash

# Script to reliably launch iOS Simulator
# Usage: ./launch-ios-simulator.sh <device_name> <os_version> [timeout_seconds]
#
# Examples:
#   ./launch-ios-simulator.sh "iPhone 17" "26.2"
#   ./launch-ios-simulator.sh "iPhone 17" "26.2" 120
#
# Exit codes:
#   0 - Success
#   1 - Device not found
#   2 - Boot timeout
#   3 - Invalid arguments

set -euo pipefail

# Configuration
DEVICE_NAME="${1:-}"
OS_VERSION="${2:-}"
TIMEOUT="${3:-200}"
CHECK_INTERVAL=2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$1"
}

log_success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

log_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}✗${NC} %s\n" "$1" >&2
}

# Validate arguments
if [ -z "$DEVICE_NAME" ] || [ -z "$OS_VERSION" ]; then
    log_error "Usage: $0 <device_name> <os_version> [timeout_seconds]"
    log_error "Example: $0 \"iPhone 17\" \"26.2\" 120"
    exit 3
fi

log_info "Starting iOS Simulator setup..."
log_info "Device: $DEVICE_NAME"
log_info "OS Version: $OS_VERSION"
log_info "Timeout: ${TIMEOUT}s"

# Kill any stuck simulators
log_info "Checking for existing Simulator processes..."
if pgrep -x "Simulator" > /dev/null; then
    log_warning "Found existing Simulator process, shutting down..."
    killall Simulator 2>/dev/null || true
    sleep 2
fi

# Find the device UDID
log_info "Finding device UDID for '$DEVICE_NAME' with iOS $OS_VERSION..."

# Convert version like "26.2" to runtime key format "iOS-26-2"
IOS_RUNTIME_KEY=$(echo "$OS_VERSION" | sed 's/\./-/g')

# Always show available devices
log_info ""
log_info "Available devices:"
xcrun simctl list devices available --json | \
    jq -r '.devices | to_entries[] | select(.key | contains("iOS")) | .key as $runtime | .value[] | 
    ($runtime | capture("iOS-(?<major>[0-9]+)-(?<minor>[0-9]+)") | "iOS \(.major).\(.minor)") as $version |
    "  \(.name) - \($version) - \(.udid)"'
log_info ""

# Search for device in the specific iOS version runtime
DEVICE_UDID=$(xcrun simctl list devices available --json | \
    jq -r --arg name "$DEVICE_NAME" --arg runtime_suffix "iOS-${IOS_RUNTIME_KEY}" \
    '.devices | to_entries[] | select(.key | endswith($runtime_suffix)) | .value[] | select(.name == $name and .isAvailable == true) | .udid' | \
    head -n 1)

if [ -z "$DEVICE_UDID" ]; then
    log_error "Device '$DEVICE_NAME' with iOS $OS_VERSION not found or not available"
    log_info ""
    log_info "Hint: Use exact device name from the list above (e.g., 'iPhone Air' not 'iPhone 17 Air')"
    exit 1
fi

log_success "Found device: $DEVICE_NAME (UDID: $DEVICE_UDID)"

# Check current state
CURRENT_STATE=$(xcrun simctl list devices --json | \
    jq -r --arg udid "$DEVICE_UDID" \
    '.devices[] | .[] | select(.udid == $udid) | .state')

log_info "Current state: $CURRENT_STATE"

# Shutdown if already booted to ensure clean state
if [ "$CURRENT_STATE" = "Booted" ]; then
    log_warning "Device already booted, shutting down for clean start..."
    xcrun simctl shutdown "$DEVICE_UDID" 2>/dev/null || true
    sleep 2
fi

# Boot the simulator
log_info "Booting simulator..."
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null || {
    # Check if it's already booting or booted
    CURRENT_STATE=$(xcrun simctl list devices --json | \
        jq -r --arg udid "$DEVICE_UDID" \
        '.devices[] | .[] | select(.udid == $udid) | .state')
    
    if [ "$CURRENT_STATE" != "Booted" ] && [ "$CURRENT_STATE" != "Booting" ]; then
        log_error "Failed to boot simulator"
        exit 2
    fi
}

# Wait for simulator to boot
log_info "Waiting for simulator to boot (timeout: ${TIMEOUT}s)..."
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    STATE=$(xcrun simctl list devices --json | \
        jq -r --arg udid "$DEVICE_UDID" \
        '.devices[] | .[] | select(.udid == $udid) | .state')
    
    if [ "$STATE" = "Booted" ]; then
        log_success "Simulator booted successfully!"
        break
    fi
    
    if [ $((ELAPSED % 10)) -eq 0 ] && [ $ELAPSED -gt 0 ]; then
        log_info "Still waiting... (${ELAPSED}s elapsed, timeout in $((TIMEOUT - ELAPSED))s)"
    fi
    
    sleep $CHECK_INTERVAL
    ELAPSED=$((ELAPSED + CHECK_INTERVAL))
done

# Verify boot completed
FINAL_STATE=$(xcrun simctl list devices --json | \
    jq -r --arg udid "$DEVICE_UDID" \
    '.devices[] | .[] | select(.udid == $udid) | .state')

if [ "$FINAL_STATE" != "Booted" ]; then
    log_error "Simulator boot timeout after ${TIMEOUT}s (state: $FINAL_STATE)"
    exit 2
fi

# Open Simulator.app (optional, for visibility)
log_info "Opening Simulator.app..."
open -a Simulator --args -CurrentDeviceUDID "$DEVICE_UDID" 2>/dev/null || {
    log_warning "Failed to open Simulator.app (non-critical)"
}

# Final verification
# `simctl bootstatus -b` occasionally hangs on CI even when the device is already Booted.
# Guard it with a timeout so this script can never run forever.
log_info "Verifying simulator status..."
if command -v gtimeout >/dev/null 2>&1; then
    gtimeout 60 xcrun simctl bootstatus "$DEVICE_UDID" -b 2>/dev/null || {
        log_warning "bootstatus check failed or timed out (non-critical)"
    }
elif command -v timeout >/dev/null 2>&1; then
    timeout 60 xcrun simctl bootstatus "$DEVICE_UDID" -b 2>/dev/null || {
        log_warning "bootstatus check failed or timed out (non-critical)"
    }
else
    # Best effort: run without a guard, but don't block the pipeline forever.
    xcrun simctl bootstatus "$DEVICE_UDID" -b 2>/dev/null &
    BOOTSTATUS_PID=$!
    for _ in $(seq 1 60); do
        if ! kill -0 "$BOOTSTATUS_PID" 2>/dev/null; then
            wait "$BOOTSTATUS_PID" || log_warning "bootstatus check failed (non-critical)"
            BOOTSTATUS_PID=""
            break
        fi
        sleep 1
    done
    if [ -n "${BOOTSTATUS_PID:-}" ]; then
        kill "$BOOTSTATUS_PID" 2>/dev/null || true
        log_warning "bootstatus check timed out (non-critical)"
    fi
fi

# Print simulator info
log_success "Simulator is ready!"
echo ""
echo "Device Information:"
echo "  Name: $DEVICE_NAME"
echo "  OS Version: iOS $OS_VERSION"
echo "  UDID: $DEVICE_UDID"
echo "  State: $(xcrun simctl list devices --json | jq -r --arg udid "$DEVICE_UDID" '.devices[] | .[] | select(.udid == $udid) | .state')"
echo ""

# Export UDID for use in subsequent steps
echo "SIMULATOR_UDID=$DEVICE_UDID" >> "${GITHUB_ENV:-/dev/null}"
log_success "Simulator UDID exported to GITHUB_ENV"

log_success "Setup complete! Simulator is ready for testing."
exit 0
