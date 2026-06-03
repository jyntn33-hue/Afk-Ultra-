#!/bin/bash

# =========================
#     AFK MAKER ULTRA
#   pratik x dark edition
# =========================

set -euo pipefail

# ---------------- CONFIG ----------------
WORKSPACE_DIR="$HOME/afk_maker_ultra"
LOG_FILE="$WORKSPACE_DIR/activity.log"
CONFIG_FILE="$WORKSPACE_DIR/config.conf"
PID_FILE="$WORKSPACE_DIR/simulator.pid"
STATUS_FILE="$WORKSPACE_DIR/status.json"

MAX_DISK_USAGE="500M"

mkdir -p "$WORKSPACE_DIR"

# ---------------- COLORS ----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ---------------- INIT JSON ----------------
if [[ ! -f "$STATUS_FILE" ]]; then
cat > "$STATUS_FILE" <<EOF
{
  "folders": 0,
  "created": 0,
  "edited": 0,
  "deleted": 0,
  "start_time": $(date +%s)
}
EOF
fi

# require jq
if ! command -v jq >/dev/null 2>&1; then
    echo "Install jq first: sudo apt install jq"
    exit 1
fi

# ---------------- JSON HELPERS ----------------
get_json() {
    jq -r ".\"$1\"" "$STATUS_FILE"
}

update_json() {
    local key="$1"
    local value="$2"
    tmp=$(mktemp)
    jq ".\"$key\" = $value" "$STATUS_FILE" > "$tmp" && mv "$tmp" "$STATUS_FILE"
}

# ---------------- NEON BANNER ----------------
show_banner() {
clear

colors=("\033[1;36m" "\033[1;35m" "\033[1;32m" "\033[1;34m")

for i in {1..3}; do
    c=${colors[$RANDOM % ${#colors[@]}]}

    clear
    echo -e "$c"
cat << "EOF"

    █████╗ ███████╗██╗  ██╗    ███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗ 
   ██╔══██╗██╔════╝██║ ██╔╝    ████╗ ████║██╔══██╗██║ ██╔╝██╔════╝██╔══██╗
   ███████║█████╗  █████╔╝     ██╔████╔██║███████║█████╔╝ █████╗  ██████╔╝
   ██╔══██║██╔══╝  ██╔═██╗     ██║╚██╔╝██║██╔══██║██║███╗ ██╔══╝  ██╔══██╗
   ██║  ██║███████╗██║  ██╗    ██║ ╚═╝ ██║██║  ██║╚█████╔╝███████╗██║  ██║
   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝ ╚════╝ ╚══════╝╚═╝  ╚═╝

                     📛 AFK MAKER ULTRA 📛

EOF

    echo -e "\033[1;95mpratik x dark\033[0m"
    sleep 0.4
done
}

# ---------------- BOOT EFFECT ----------------
glitch_loading() {
    echo -e "\033[1;36mBooting AFK Engine...\033[0m"
    text="INITIALIZING CORE SYSTEM"

    for ((i=0;i<${#text};i++)); do
        echo -ne "\r${text:0:$i}"
        sleep 0.03
    done

    echo -e "\n\033[1;32m✔ SYSTEM ONLINE\033[0m"
    sleep 0.5
}

# ---------------- RANDOM GENERATORS ----------------
gen_folder() {
    echo "cosmic_$RANDOM"
}

gen_file() {
    echo "data_$RANDOM.txt"
}

gen_content() {
    echo "event log $RANDOM at $(date)"
}

# ---------------- DISK CHECK ----------------
check_disk() {
    local size
    size=$(du -sb "$WORKSPACE_DIR" | awk '{print $1}')
    local limit
    limit=$(numfmt --from=iec "$MAX_DISK_USAGE" 2>/dev/null || echo 524288000)

    if (( size > limit )); then
        find "$WORKSPACE_DIR" -type f | sort | head -n 10 | xargs rm -f
    fi
}

# ---------------- OPERATIONS ----------------
perform() {

    op=$((RANDOM%5))

    case $op in

    0)
        dir="$WORKSPACE_DIR/$(gen_folder)"
        mkdir -p "$dir"
        update_json folders "$(($(get_json folders)+1))"
        ;;

    1)
        dir=$(find "$WORKSPACE_DIR" -type d | shuf -n 1 2>/dev/null || echo "$WORKSPACE_DIR")
        file="$dir/$(gen_file)"
        echo "$(gen_content)" > "$file"
        update_json created "$(($(get_json created)+1))"
        ;;

    2)
        file=$(find "$WORKSPACE_DIR" -type f | shuf -n 1 2>/dev/null || true)
        [[ -n "$file" ]] && echo "$(gen_content)" >> "$file"
        update_json edited "$(($(get_json edited)+1))"
        ;;

    3)
        item=$(find "$WORKSPACE_DIR" -mindepth 1 | shuf -n 1 2>/dev/null || true)
        [[ -n "$item" ]] && mv "$item" "$item._afk"
        ;;

    4)
        item=$(find "$WORKSPACE_DIR" -mindepth 1 | shuf -n 1 2>/dev/null || true)
        [[ -n "$item" ]] && rm -rf "$item"
        update_json deleted "$(($(get_json deleted)+1))"
        ;;

    esac

    check_disk
}

# ---------------- DASHBOARD ----------------
dashboard() {
    while true; do
        clear

        folders=$(get_json folders)
        created=$(get_json created)
        edited=$(get_json edited)
        deleted=$(get_json deleted)
        start=$(get_json start_time)

        now=$(date +%s)
        uptime=$((now-start))

        echo -e "\033[1;36m╔════════════════════════════╗\033[0m"
        echo -e "\033[1;36m║     ⚡ AFK ULTRA PANEL     ║\033[0m"
        echo -e "\033[1;36m╚════════════════════════════╝\033[0m"

        echo ""
        echo -e "📁 Folders : $folders"
        echo -e "📄 Created : $created"
        echo -e "✏️ Edited  : $edited"
        echo -e "🗑 Deleted : $deleted"
        echo -e "⏱ Uptime  : ${uptime}s"

        echo ""
        echo -e "\033[1;95mpratik x dark\033[0m"

        sleep 1
    done
}

# ---------------- START ----------------
start() {
    show_banner
    glitch_loading

    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Already running"
        exit 1
    fi

    echo $$ > "$PID_FILE"
    trap "rm -f $PID_FILE; exit" INT TERM

    while true; do
        perform
        sleep 1
    done
}

stop() {
    [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" 2>/dev/null && rm -f "$PID_FILE"
    echo "Stopped"
}

status() {
    [[ -f "$PID_FILE" ]] && echo "Running PID: $(cat "$PID_FILE")" || echo "Not running"
}

# ---------------- MAIN ----------------
case "${1:-status}" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    dashboard) dashboard ;;
    *) echo "Usage: $0 {start|stop|status|dashboard}" ;;
esac
