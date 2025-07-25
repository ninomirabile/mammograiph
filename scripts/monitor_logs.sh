#!/bin/bash

# Real-time Log Monitor for AI Medical Imaging - Starter Kit
# Monitors application logs with color coding and filtering

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="logs"
APP_LOG="$LOG_DIR/app.log"
ERROR_LOG="$LOG_DIR/error.log"

# Default settings
FILTER_LEVEL="INFO"
SHOW_TIMESTAMPS=true
FOLLOW=true
LINES=50

# Help function
show_help() {
    echo "AI Medical Imaging - Log Monitor"
    echo "================================="
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -f, --follow          Follow log files (default: true)"
    echo "  -n, --lines N         Show last N lines (default: 50)"
    echo "  -l, --level LEVEL     Filter by log level (DEBUG, INFO, WARNING, ERROR)"
    echo "  -t, --no-timestamps   Hide timestamps"
    echo "  -e, --errors-only     Show only error logs"
    echo "  -a, --all-logs        Show all log files"
    echo "  -h, --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Monitor all logs with default settings"
    echo "  $0 -l ERROR           # Show only error messages"
    echo "  $0 -n 100             # Show last 100 lines"
    echo "  $0 -e                 # Show only error log file"
    echo "  $0 --no-follow        # Show current logs without following"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -l|--level)
            FILTER_LEVEL="$2"
            shift 2
            ;;
        -t|--no-timestamps)
            SHOW_TIMESTAMPS=false
            shift
            ;;
        -e|--errors-only)
            ERROR_ONLY=true
            shift
            ;;
        -a|--all-logs)
            ALL_LOGS=true
            shift
            ;;
        --no-follow)
            FOLLOW=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${RED}Error: Log directory '$LOG_DIR' does not exist${NC}"
    echo "Make sure the application has been started at least once."
    exit 1
fi

# Colorize log levels
colorize_log() {
    local line="$1"
    
    # Color by log level
    if echo "$line" | grep -q "ERROR"; then
        echo -e "${RED}$line${NC}"
    elif echo "$line" | grep -q "WARNING"; then
        echo -e "${YELLOW}$line${NC}"
    elif echo "$line" | grep -q "INFO"; then
        echo -e "${GREEN}$line${NC}"
    elif echo "$line" | grep -q "DEBUG"; then
        echo -e "${BLUE}$line${NC}"
    elif echo "$line" | grep -q "Request:"; then
        echo -e "${CYAN}$line${NC}"
    elif echo "$line" | grep -q "Response:"; then
        echo -e "${PURPLE}$line${NC}"
    else
        echo "$line"
    fi
}

# Filter logs by level
filter_by_level() {
    local level="$1"
    case $level in
        DEBUG)
            grep -E "(DEBUG|INFO|WARNING|ERROR)"
            ;;
        INFO)
            grep -E "(INFO|WARNING|ERROR)"
            ;;
        WARNING)
            grep -E "(WARNING|ERROR)"
            ;;
        ERROR)
            grep -E "ERROR"
            ;;
        *)
            cat
            ;;
    esac
}

# Remove timestamps if requested
remove_timestamps() {
    if [ "$SHOW_TIMESTAMPS" = false ]; then
        sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\},[0-9]\{3\} - //'
    else
        cat
    fi
}

# Monitor specific log file
monitor_log() {
    local log_file="$1"
    local description="$2"
    
    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}Warning: Log file '$log_file' does not exist${NC}"
        return
    fi
    
    echo -e "${BLUE}=== $description ===${NC}"
    echo -e "${BLUE}File: $log_file${NC}"
    echo
    
    if [ "$FOLLOW" = true ]; then
        tail -n "$LINES" -f "$log_file" | filter_by_level "$FILTER_LEVEL" | remove_timestamps | while read -r line; do
            colorize_log "$line"
        done
    else
        tail -n "$LINES" "$log_file" | filter_by_level "$FILTER_LEVEL" | remove_timestamps | while read -r line; do
            colorize_log "$line"
        done
    fi
}

# Main monitoring function
main() {
    echo "=========================================="
    echo "AI Medical Imaging - Log Monitor"
    echo "=========================================="
    echo "Filter Level: $FILTER_LEVEL"
    echo "Lines: $LINES"
    echo "Follow: $FOLLOW"
    echo "Timestamps: $SHOW_TIMESTAMPS"
    echo "=========================================="
    echo
    
    # Show only error logs if requested
    if [ "$ERROR_ONLY" = true ]; then
        monitor_log "$ERROR_LOG" "Error Log"
        return
    fi
    
    # Show all logs if requested
    if [ "$ALL_LOGS" = true ]; then
        # Monitor all log files in parallel
        echo -e "${BLUE}Monitoring all log files...${NC}"
        echo
        
        # Use tail to monitor multiple files
        if [ "$FOLLOW" = true ]; then
            tail -n "$LINES" -f "$APP_LOG" "$ERROR_LOG" | filter_by_level "$FILTER_LEVEL" | remove_timestamps | while read -r line; do
                colorize_log "$line"
            done
        else
            echo -e "${BLUE}=== Application Log ===${NC}"
            tail -n "$LINES" "$APP_LOG" | filter_by_level "$FILTER_LEVEL" | remove_timestamps | while read -r line; do
                colorize_log "$line"
            done
            echo
            echo -e "${BLUE}=== Error Log ===${NC}"
            tail -n "$LINES" "$ERROR_LOG" | filter_by_level "$FILTER_LEVEL" | remove_timestamps | while read -r line; do
                colorize_log "$line"
            done
        fi
    else
        # Default: monitor main application log
        monitor_log "$APP_LOG" "Application Log"
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Log monitoring stopped${NC}"; exit 0' INT

# Run main function
main "$@" 