#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                      AFK ULTRA MAKER SYSTEM v3.0                           ║
# ║                 Advanced VPS Activity Simulator Engine                      ║
# ║                                                                              ║
# ║              █████╗ ███████╗██╗  ██╗    ██╗   ██╗██╗  ████████╗██████╗  █████╗ 
# ║             ██╔══██╗██╔════╝██║ ██╔╝    ██║   ██║██║  ╚══██╔══╝██╔══██╗██╔══██╗
# ║             ███████║█████╗  █████╔╝     ██║   ██║██║     ██║   ██████╔╝███████║
# ║             ██╔══██║██╔══╝  ██╔═██╗     ██║   ██║██║     ██║   ██╔══██╗██╔══██║
# ║             ██║  ██║██║     ██║  ██╗    ╚██████╔╝███████╗██║   ██║  ██║██║  ██║
# ║             ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝     ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          CONFIGURATION SYSTEM                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

SCRIPT_VERSION="3.0.0"
SCRIPT_NAME="AFK ULTRA MAKER"
CONFIG_DIR="${HOME}/.config/afk-ultra-maker"
CONFIG_FILE="${CONFIG_DIR}/config.cfg"
WORKSPACE_DIR="${CONFIG_DIR}/workspace"
LOG_DIR="${CONFIG_DIR}/logs"
PID_DIR="${CONFIG_DIR}/pids"
ACTIVITY_LOG="${LOG_DIR}/activity.log"
SYSTEM_LOG="${LOG_DIR}/system.log"
MAIN_PID_FILE="${PID_DIR}/afk-maker.pid"
DASHBOARD_PID_FILE="${PID_DIR}/dashboard.pid"

# Default configuration
DEFAULT_DISK_LIMIT_MB=500
DEFAULT_SPEED_LEVEL="medium"
DEFAULT_MAX_FILES=1000
DEFAULT_CLEANUP_THRESHOLD=80
DEFAULT_AUTO_CLEANUP=true

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          COLOR SYSTEM (Neon Cyberpunk)                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Reset
NC='\033[0m'

# Regular Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold Colors
BOLD_BLACK='\033[1;30m'
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'
BOLD_CYAN='\033[1;36m'
BOLD_WHITE='\033[1;37m'

# Neon Colors (High Intensity)
NEON_CYAN='\033[1;96m'
NEON_PURPLE='\033[1;95m'
NEON_GREEN='\033[1;92m'
NEON_YELLOW='\033[1;93m'
GLITCH='\033[5m'

# Background Colors
BG_BLACK='\033[40m'
BG_CYAN='\033[46m'
BG_PURPLE='\033[45m'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          CORE VARIABLES                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# Activity counters
FOLDERS_CREATED=0
FILES_CREATED=0
FILES_EDITED=0
FILES_DELETED=0
OPERATIONS_PER_SEC=0
START_TIME=0
MODE="idle"
CYCLE_START=0

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          UTILITY FUNCTIONS                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

debug_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $1" >> "${SYSTEM_LOG}"
}

error_log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ERROR: $1" >> "${SYSTEM_LOG}" 2>&1
}

safe_execute() {
    local cmd="$1"
    local fallback="$2"
    eval "$cmd" 2>/dev/null || {
        error_log "Failed to execute: $cmd"
        eval "$fallback" 2>/dev/null || true
    }
}

random_number() {
    local min=$1
    local max=$2
    echo $((RANDOM % (max - min + 1) + min))
}

random_delay() {
    local base=$1
    local variance=$2
    sleep $(echo "scale=3; ($base + $variance * $RANDOM / 32767)" | bc 2>/dev/null || echo "0.1")
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          INITIALIZATION SYSTEM                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

init_system() {
    debug_log "Initializing AFK ULTRA MAKER SYSTEM..."
    
    # Create directory structure
    mkdir -p "${CONFIG_DIR}" "${WORKSPACE_DIR}" "${LOG_DIR}" "${PID_DIR}"
    
    # Initialize config if not exists
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        cat > "${CONFIG_FILE}" << EOF
# AFK ULTRA MAKER Configuration
DISK_LIMIT_MB=${DEFAULT_DISK_LIMIT_MB}
SPEED_LEVEL="${DEFAULT_SPEED_LEVEL}"
MAX_FILES=${DEFAULT_MAX_FILES}
CLEANUP_THRESHOLD=${DEFAULT_CLEANUP_THRESHOLD}
AUTO_CLEANUP=${DEFAULT_AUTO_CLEANUP}
EOF
        debug_log "Default configuration created"
    fi
    
    # Load configuration
    source "${CONFIG_FILE}"
    
    # Ensure workspace is clean and safe
    chmod 755 "${WORKSPACE_DIR}" 2>/dev/null || true
    
    # Initialize log files
    touch "${ACTIVITY_LOG}" "${SYSTEM_LOG}"
    
    debug_log "System initialization complete"
}

load_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        source "${CONFIG_FILE}"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          FILE SYSTEM SIMULATION                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

get_random_filename() {
    local prefixes=("data" "log" "config" "cache" "temp" "backup" "debug" "info" "system" "process")
    local suffixes=("data" "info" "dump" "state" "session" "metrics" "report" "index" "manifest" "snapshot")
    local extensions=("txt" "log" "json" "tmp" "cfg" "dat" "csv" "xml" "yaml" "ini")
    
    local prefix=${prefixes[$((RANDOM % ${#prefixes[@]}))]}
    local suffix=${suffixes[$((RANDOM % ${#suffixes[@]}))]}
    local ext=${extensions[$((RANDOM % ${#extensions[@]}))]}
    local random_id=$(random_number 1000 9999)
    
    echo "${prefix}_${suffix}_${random_id}.${ext}"
}

get_random_content() {
    local size=$1
    local contents=(
        "{\"status\": \"ok\", \"code\": $(random_number 100 599), \"message\": \"Operation completed\"}"
        "[$(date +%s)] INFO: System process $(random_number 1000 9999) started"
        "timestamp: $(date '+%Y-%m-%d %H:%M:%S'), load: $(random_number 1 100).$(random_number 0 99)%, memory: $(random_number 256 8192)MB"
        "ERROR: Failed to connect to service on port $(random_number 1024 65535)"
        "DEBUG: Processing batch #$(random_number 1 10000)"
        "CPU: $(random_number 0 100)%, Memory: $(random_number 20 95)%, Network: $(random_number 1 1000)MB/s"
        "Connection established to $(random_number 10 255).$(random_number 0 255).$(random_number 0 255).$(random_number 0 255)"
        "WARNING: Disk usage at $(random_number 50 95)% on /dev/sda$(random_number 1 5)"
    )
    
    local content=""
    for ((i=0; i<size; i++)); do
        content+="${contents[$((RANDOM % ${#contents[@]}))]}\n"
    done
    echo -e "$content"
}

create_file() {
    if [[ $FILES_CREATED -ge $MAX_FILES ]]; then
        debug_log "Max files limit reached: ${MAX_FILES}"
        return
    fi
    
    local filename=$(get_random_filename)
    local filepath="${WORKSPACE_DIR}/${filename}"
    local content_size=$(random_number 1 10)
    local content=$(get_random_content $content_size)
    
    echo "$content" > "${filepath}" 2>/dev/null || {
        error_log "Failed to create file: ${filepath}"
        return
    }
    
    FILES_CREATED=$((FILES_CREATED + 1))
    log_activity "CREATED" "${filename}"
}

create_folder() {
    local foldername="dir_$(date +%s%N | sha256sum | head -c 8)_$(random_number 100 999)"
    local folderpath="${WORKSPACE_DIR}/${foldername}"
    
    mkdir -p "${folderpath}" 2>/dev/null || {
        error_log "Failed to create folder: ${folderpath}"
        return
    }
    
    FOLDERS_CREATED=$((FOLDERS_CREATED + 1))
    log_activity "CREATED_DIR" "${foldername}"
    
    # Create some files inside new folder
    local files_in_folder=$(random_number 0 5)
    for ((i=0; i<files_in_folder; i++)); do
        local inner_file="${folderpath}/$(get_random_filename)"
        echo "$(get_random_content 1)" > "${inner_file}" 2>/dev/null || true
    done
}

edit_file() {
    local files=($(find "${WORKSPACE_DIR}" -type f -name "*.txt" -o -name "*.log" -o -name "*.json" 2>/dev/null | head -50))
    
    if [[ ${#files[@]} -eq 0 ]]; then
        return
    fi
    
    local file_to_edit="${files[$((RANDOM % ${#files[@]}))]}"
    
    # Append content
    echo -e "\n[$(date '+%H:%M:%S')] Updated at $(date)\n$(get_random_content 2)" >> "${file_to_edit}" 2>/dev/null || {
        error_log "Failed to edit file: ${file_to_edit}"
        return
    }
    
    FILES_EDITED=$((FILES_EDITED + 1))
    log_activity "EDITED" "$(basename ${file_to_edit})"
}

rename_item() {
    local items=($(find "${WORKSPACE_DIR}" -maxdepth 1 -mindepth 1 2>/dev/null | head -50))
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return
    fi
    
    local item_to_rename="${items[$((RANDOM % ${#items[@]}))]}"
    local item_name=$(basename "${item_to_rename}")
    local new_name="renamed_$(date +%s%N | sha256sum | head -c 6)_${item_name}"
    local new_path="$(dirname ${item_to_rename})/${new_name}"
    
    mv "${item_to_rename}" "${new_path}" 2>/dev/null || {
        error_log "Failed to rename: ${item_to_rename}"
        return
    }
    
    log_activity "RENAMED" "${item_name} -> ${new_name}"
}

delete_old_item() {
    local items=($(find "${WORKSPACE_DIR}" -mindepth 1 -type f -o -type d 2>/dev/null | sort -R | head -20))
    
    if [[ ${#items[@]} -eq 0 ]]; then
        return
    fi
    
    local item_to_delete="${items[$((RANDOM % ${#items[@]}))]}"
    
    # Safety check - ensure we're in workspace
    if [[ "${item_to_delete}" == "${WORKSPACE_DIR}"* ]] && [[ "${item_to_delete}" != "${WORKSPACE_DIR}" ]]; then
        rm -rf "${item_to_delete}" 2>/dev/null || {
            error_log "Failed to delete: ${item_to_delete}"
            return
        }
        FILES_DELETED=$((FILES_DELETED + 1))
        log_activity "DELETED" "$(basename ${item_to_delete})"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          ACTIVITY LOGGING                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

log_activity() {
    local action=$1
    local target=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    
    echo "[${timestamp}] ${action} | ${target}" >> "${ACTIVITY_LOG}"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          CLEANUP & MAINTENANCE                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

check_disk_usage() {
    local workspace_size=$(du -sm "${WORKSPACE_DIR}" 2>/dev/null | cut -f1)
    local limit_mb=${DISK_LIMIT_MB}
    
    if [[ $workspace_size -gt $((limit_mb * CLEANUP_THRESHOLD / 100)) ]]; then
        debug_log "Disk usage at ${workspace_size}MB, threshold reached"
        return 0
    fi
    return 1
}

auto_cleanup() {
    debug_log "Starting auto cleanup..."
    
    # Remove oldest files first
    local files_to_remove=$(find "${WORKSPACE_DIR}" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | head -50 | cut -d' ' -f2-)
    
    for file in $files_to_remove; do
        if [[ -f "$file" ]]; then
            rm -f "$file" 2>/dev/null || true
            FILES_DELETED=$((FILES_DELETED + 1))
        fi
    done
    
    # Remove empty directories
    find "${WORKSPACE_DIR}" -type d -empty -delete 2>/dev/null || true
    
    debug_log "Cleanup completed"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          SMART SYSTEM BEHAVIOR                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

generate_fake_system_logs() {
    local log_file="${WORKSPACE_DIR}/system_monitor_$(date +%Y%m%d).log"
    local cpu_usage=$(random_number 5 95)
    local mem_usage=$(random_number 256 4096)
    local net_in=$(random_number 100 10000)
    local net_out=$(random_number 50 5000)
    local processes=$(random_number 100 500)
    
    cat >> "${log_file}" << EOF
[$(date '+%H:%M:%S')] CPU: ${cpu_usage}% | RAM: ${mem_usage}MB/${random_number 4096 8192}MB | NET: ${net_in}KB/s↓ ${net_out}KB/s↑
[$(date '+%H:%M:%S')] SYSTEM: Running processes: ${processes} | Load average: $(echo "scale=2; $RANDOM/32767*4" | bc 2>/dev/null || echo "1.5")
[$(date '+%H:%M:%S')] $( [[ $((RANDOM % 10)) -eq 0 ]] && echo "WARNING: High I/O wait detected on disk $(random_number 0 10)" || echo "INFO: All services nominal")
EOF
}

simulate_errors() {
    if [[ $((RANDOM % 15)) -eq 0 ]]; then
        local error_log="${WORKSPACE_DIR}/error_$(date +%Y%m%d).log"
        local errors=(
            "WARNING: Connection timeout to $(random_number 10 255).$(random_number 0 255).$(random_number 0 255).$(random_number 0 255):$(random_number 1024 65535)"
            "ERROR: Failed to allocate memory: $(random_number 1 1024)MB requested"
            "CRITICAL: Disk I/O error on sector $(random_number 1000000 9999999)"
            "ALERT: Unusual traffic pattern detected from source port $(random_number 1024 65535)"
            "WARNING: Certificate expiration in $(random_number 1 30) days for domain service-$(random_number 1 100).local"
        )
        echo "[$(date)] ${errors[$((RANDOM % ${#errors[@]}))]}" >> "${error_log}"
    fi
}

adaptive_workload() {
    local current_hour=$(date +%-H)
    
    # Heavy load during business hours, lighter at night
    if [[ $current_hour -ge 8 && $current_hour -le 20 ]]; then
        MODE="active"
        CYCLE_START=$((CYCLE_START + 1))
        if [[ $CYCLE_START -gt 50 ]]; then
            MODE="idle"
            CYCLE_START=0
        fi
    else
        MODE="idle"
        CYCLE_START=0
    fi
}

get_operations_speed() {
    case $SPEED_LEVEL in
        "low")
            echo $(random_number 1 3)
            ;;
        "high")
            echo $(random_number 8 15)
            ;;
        *)
            echo $(random_number 3 8)
            ;;
    esac
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          MAIN ENGINE LOOP                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

engine_loop() {
    START_TIME=$(date +%s)
    local loop_count=0
    local operation_count=0
    local last_stats_time=$START_TIME
    
    # Save PID
    echo $$ > "${MAIN_PID_FILE}"
    
    debug_log "Engine started with PID: $$"
    
    while true; do
        load_config
        adaptive_workload
        
        local operations_per_cycle=$(get_operations_speed)
        
        for ((i=0; i<operations_per_cycle; i++)); do
            # Random weighted operation selection
            local operation_chance=$((RANDOM % 100))
            
            if [[ $operation_chance -lt 30 ]]; then
                create_file
            elif [[ $operation_chance -lt 50 ]]; then
                create_folder
            elif [[ $operation_chance -lt 70 ]]; then
                edit_file
            elif [[ $operation_chance -lt 85 ]]; then
                rename_item
            elif [[ $operation_chance -lt 95 ]]; then
                delete_old_item
            else
                # System maintenance operations
                if [[ $((RANDOM % 3)) -eq 0 ]]; then
                    generate_fake_system_logs
                else
                    simulate_errors
                fi
            fi
            
            operation_count=$((operation_count + 1))
            
            # Random delay for realism
            if [[ $MODE == "idle" ]]; then
                random_delay 0.5 0.5
            else
                random_delay 0.1 0.1
            fi
        done
        
        # Periodic maintenance
        if [[ $((RANDOM % 50)) -eq 0 ]]; then
            if check_disk_usage && [[ "$AUTO_CLEANUP" == "true" ]]; then
                auto_cleanup
            fi
        fi
        
        # Calculate operations per second
        local current_time=$(date +%s)
        if [[ $((current_time - last_stats_time)) -ge 5 ]]; then
            local elapsed=$((current_time - last_stats_time))
            OPERATIONS_PER_SEC=$((operation_count / elapsed))
            operation_count=0
            last_stats_time=$current_time
        fi
        
        loop_count=$((loop_count + 1))
        
        # Save state periodically
        if [[ $((loop_count % 10)) -eq 0 ]]; then
            save_state
        fi
    done
}

save_state() {
    echo "${FOLDERS_CREATED}|${FILES_CREATED}|${FILES_EDITED}|${FILES_DELETED}|${OPERATIONS_PER_SEC}|${START_TIME}|${MODE}" > "${CONFIG_DIR}/state.dat" 2>/dev/null || true
}

load_state() {
    if [[ -f "${CONFIG_DIR}/state.dat" ]]; then
        IFS='|' read -r FOLDERS_CREATED FILES_CREATED FILES_EDITED FILES_DELETED OPERATIONS_PER_SEC START_TIME MODE < "${CONFIG_DIR}/state.dat" 2>/dev/null || true
    fi
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          UI SYSTEM                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

display_banner() {
    clear
    echo -e "${NEON_CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║         █████╗ ███████╗██╗  ██╗    ██╗   ██╗██╗  ████████╗██████╗  █████╗ 
    ║        ██╔══██╗██╔════╝██║ ██╔╝    ██║   ██║██║  ╚══██╔══╝██╔══██╗██╔══██╗
    ║        ███████║█████╗  █████╔╝     ██║   ██║██║     ██║   ██████╔╝███████║
    ║        ██╔══██║██╔══╝  ██╔═██╗     ██║   ██║██║     ██║   ██╔══██╗██╔══██║
    ║        ██║  ██║██║     ██║  ██╗    ╚██████╔╝███████╗██║   ██║  ██║██║  ██║
    ║        ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝     ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
    ║                                                                      ║
    ║              ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗               ║
    ║              ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗              ║
    ║              ██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝              ║
    ║              ██║╚██╔╝██║██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗              ║
    ║              ██║ ╚═╝ ██║██║  ██║██║  ██╗███████╗██║  ██║              ║
    ║              ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝              ║
    ║                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NEON_PURPLE}"
    cat << "EOF"
                    ░▒▓█ ADVANCED VPS ACTIVITY SIMULATOR █▓▒░
                              Version 3.0 | Production Ready
EOF
    echo -e "${NC}"
}

display_animated_boot() {
    clear
    echo -e "${NEON_CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    SYSTEM BOOT SEQUENCE                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    local boot_messages=(
        "Initializing kernel modules..."
        "Loading system configuration..."
        "Starting activity engine..."
        "Calibrating simulation parameters..."
        "Establishing workspace environment..."
        "Activating monitoring subsystems..."
        "Loading performance metrics..."
        "Initializing file system simulator..."
        "Starting background processes..."
        "System ready."
    )
    
    for msg in "${boot_messages[@]}"; do
        echo -ne "${NEON_GREEN}[${NEON_CYAN}*${NEON_GREEN}] ${NEON_PURPLE}${msg}${NC}"
        for ((i=0; i<3; i++)); do
            sleep 0.2
            echo -ne "${NEON_CYAN}.${NC}"
        done
        echo ""
        sleep 0.1
    done
    
    sleep 0.5
    clear
}

show_status() {
    display_banner
    
    local pid=""
    local status="INACTIVE"
    local uptime="0s"
    
    if [[ -f "${MAIN_PID_FILE}" ]]; then
        pid=$(cat "${MAIN_PID_FILE}")
        if kill -0 "$pid" 2>/dev/null; then
            status="${NEON_GREEN}ACTIVE${NC}"
            local current_time=$(date +%s)
            if [[ -n "${START_TIME:-}" ]]; then
                local elapsed=$((current_time - START_TIME))
                uptime=$(printf '%dh:%dm:%ds' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))
            fi
        else
            status="${RED}STALE PID${NC}"
        fi
    fi
    
    local workspace_size=$(du -sh "${WORKSPACE_DIR}" 2>/dev/null | cut -f1 || echo "0")
    local log_size=$(du -sh "${ACTIVITY_LOG}" 2>/dev/null | cut -f1 || echo "0")
    
    echo -e "${NEON_CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${NEON_CYAN}║${NC} ${BOLD_WHITE}SYSTEM STATUS DASHBOARD${NC}                                          ${NEON_CYAN}║${NC}"
    echo -e "${NEON_CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_GREEN}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Status" "${status}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "PID" "${pid:-N/A}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Uptime" "${uptime}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Mode" "${MODE:-idle}"
    echo -e "${NEON_CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_GREEN}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Folders Created" "${FOLDERS_CREATED}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_GREEN}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Files Created" "${FILES_CREATED}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_GREEN}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Files Edited" "${FILES_EDITED}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_GREEN}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Files Deleted" "${FILES_DELETED}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Ops/Sec" "${OPERATIONS_PER_SEC}"
    echo -e "${NEON_CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Workspace Size" "${workspace_size}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Activity Log Size" "${log_size}"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Disk Limit" "${DISK_LIMIT_MB}MB"
    printf "${NEON_CYAN}║${NC} ${NEON_PURPLE}%-25s${NC} : ${NEON_YELLOW}%-37s${NC} ${NEON_CYAN}║${NC}\n" "Speed Level" "${SPEED_LEVEL}"
    echo -e "${NEON_CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${NEON_GREEN}                       ⚡ pratik x dark ⚡${NC}"
}

show_dashboard() {
    # Save current terminal settings
    local old_stty=$(stty -g)
    
    # Setup trap to restore terminal
    trap "stty $old_stty; tput cnorm; clear; exit" INT TERM EXIT
    
    # Hide cursor
    tput civis
    
    while true; do
        show_status
        echo -e "\n${NEON_YELLOW}[ Press Ctrl+C to exit dashboard ]${NC}"
        sleep 2
        clear
    done
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          CONTROL SYSTEM                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

start_engine() {
    if [[ -f "${MAIN_PID_FILE}" ]]; then
        local pid=$(cat "${MAIN_PID_FILE}")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${NEON_YELLOW}[!] AFK ULTRA MAKER is already running (PID: ${pid})${NC}"
            return 1
        fi
    fi
    
    echo -e "${NEON_GREEN}[+] Starting AFK ULTRA MAKER ENGINE...${NC}"
    
    init_system
    load_state
    
    # Start engine in background
    nohup bash -c "source '${BASH_SOURCE[0]}' && engine_loop" > /dev/null 2>&1 &
    local engine_pid=$!
    
    sleep 1
    
    if kill -0 "$engine_pid" 2>/dev/null; then
        echo -e "${NEON_GREEN}[✓] Engine started successfully (PID: ${engine_pid})${NC}"
        echo -e "${NEON_CYAN}[*] Workspace: ${WORKSPACE_DIR}${NC}"
        echo -e "${NEON_CYAN}[*] Logs: ${ACTIVITY_LOG}${NC}"
        echo -e "${NEON_CYAN}[*] Use '$(basename $0) status' to check status${NC}"
        echo -e "${NEON_CYAN}[*] Use '$(basename $0) dashboard' for live monitoring${NC}"
    else
        echo -e "${RED}[✗] Failed to start engine${NC}"
        return 1
    fi
}

stop_engine() {
    echo -e "${NEON_YELLOW}[*] Stopping AFK ULTRA MAKER...${NC}"
    
    if [[ -f "${MAIN_PID_FILE}" ]]; then
        local pid=$(cat "${MAIN_PID_FILE}")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            sleep 1
            
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                kill -9 "$pid" 2>/dev/null
                sleep 1
            fi
            
            echo -e "${NEON_GREEN}[✓] Engine stopped (PID: ${pid})${NC}"
        else
            echo -e "${NEON_YELLOW}[!] Engine was not running${NC}"
        fi
        rm -f "${MAIN_PID_FILE}"
    else
        echo -e "${NEON_YELLOW}[!] No PID file found${NC}"
    fi
    
    # Stop dashboard if running
    if [[ -f "${DASHBOARD_PID_FILE}" ]]; then
        local dash_pid=$(cat "${DASHBOARD_PID_FILE}")
        kill "$dash_pid" 2>/dev/null || true
        rm -f "${DASHBOARD_PID_FILE}"
    fi
}

restart_engine() {
    echo -e "${NEON_CYAN}[*] Restarting AFK ULTRA MAKER...${NC}"
    stop_engine
    sleep 2
    start_engine
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          AUTO-RECOVERY SYSTEM                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

start_auto_recovery() {
    # This function is meant to be called from cron
    if [[ -f "${MAIN_PID_FILE}" ]]; then
        local pid=$(cat "${MAIN_PID_FILE}")
        if ! kill -0 "$pid" 2>/dev/null; then
            debug_log "Auto-recovery: Engine not running, restarting..."
            rm -f "${MAIN_PID_FILE}"
            init_system
            load_state
            nohup bash -c "source '${BASH_SOURCE[0]}' && engine_loop" > /dev/null 2>&1 &
            echo $! > "${MAIN_PID_FILE}"
        fi
    fi
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          COMMAND LINE INTERFACE                             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

show_help() {
    display_banner
    echo -e "${NEON_CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${NEON_CYAN}║${NC} ${BOLD_WHITE}COMMAND REFERENCE${NC}                                                  ${NEON_CYAN}║${NC}"
    echo -e "${NEON_CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "start" "Start the AFK engine in background"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "stop" "Stop the AFK engine"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "restart" "Restart the AFK engine"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "status" "Show system status"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "dashboard" "Live monitoring dashboard"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "config" "Edit configuration file"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "logs" "View activity logs"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "cleanup" "Manual cleanup workspace"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "install-cron" "Install auto-recovery cron job"
    printf "${NEON_CYAN}║${NC} ${NEON_GREEN}%-20s${NC} ${NEON_PURPLE}%-40s${NC} ${NEON_CYAN}║${NC}\n" "help" "Show this help"
    echo -e "${NEON_CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${NEON_GREEN}                       ⚡ pratik x dark ⚡${NC}"
}

edit_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        ${EDITOR:-nano} "${CONFIG_FILE}"
        echo -e "${NEON_GREEN}[✓] Configuration updated${NC}"
    else
        echo -e "${RED}[✗] Config file not found. Run 'start' first.${NC}"
    fi
}

view_logs() {
    if [[ -f "${ACTIVITY_LOG}" ]]; then
        tail -f "${ACTIVITY_LOG}"
    else
        echo -e "${RED}[✗] Activity log not found. Run 'start' first.${NC}"
    fi
}

manual_cleanup() {
    echo -e "${NEON_YELLOW}[*] Performing manual cleanup...${NC}"
    auto_cleanup
    echo -e "${NEON_GREEN}[✓] Cleanup completed${NC}"
}

install_cron() {
    local cron_cmd="*/5 * * * * $(realpath $0) auto-recovery"
    
    # Check if cron entry already exists
    if crontab -l 2>/dev/null | grep -q "auto-recovery"; then
        echo -e "${NEON_YELLOW}[!] Cron job already exists${NC}"
    else
        (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
        echo -e "${NEON_GREEN}[✓] Auto-recovery cron job installed${NC}"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          MAIN ENTRY POINT                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

main() {
    case "${1:-help}" in
        "start")
            start_engine
            ;;
        "stop")
            stop_engine
            ;;
        "restart")
            restart_engine
            ;;
        "status")
            load_state 2>/dev/null || true
            show_status
            ;;
        "dashboard")
            load_state 2>/dev/null || true
            show_dashboard
            ;;
        "config")
            edit_config
            ;;
        "logs")
            view_logs
            ;;
        "cleanup")
            manual_cleanup
            ;;
        "auto-recovery")
            start_auto_recovery
            ;;
        "install-cron")
            install_cron
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            show_help
            ;;
    esac
}

# Execute main function if script is run directly
    # Check for minimum bash version
    if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
        echo "Error: Bash 4.0+ required"
        exit 1
    fi
    
    main "$@"
fi
