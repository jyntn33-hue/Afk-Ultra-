#!/usr/bin/env bash
# ============================
# AFK ULTRA GOD MODE v4
# VPS SAFE SIMULATOR ENGINE
# pratik x dark edition
# ============================

set -euo pipefail

# ---------- CONFIG ----------
APP_NAME="afk-ultra-god"
BASE_DIR="$HOME/.afk_god_mode"
WORKDIR="$BASE_DIR/workspace"
LOGDIR="$BASE_DIR/logs"
STATE="$BASE_DIR/state.env"
PIDFILE="$BASE_DIR/afk.pid"

MAX_FILES=800
MAX_FOLDERS=300
SLEEP_TIME=1

mkdir -p "$WORKDIR" "$LOGDIR"

# ---------- COLORS ----------
C="\033[0m"
G="\033[1;32m"
P="\033[1;35m"
CYN="\033[1;36m"

# ---------- STATE ----------
[[ -f "$STATE" ]] && source "$STATE" || true

FILES_CREATED=${FILES_CREATED:-0}
FOLDERS_CREATED=${FOLDERS_CREATED:-0}
FILES_EDITED=${FILES_EDITED:-0}
FILES_DELETED=${FILES_DELETED:-0}

save_state() {
cat > "$STATE" <<EOF
FILES_CREATED=$FILES_CREATED
FOLDERS_CREATED=$FOLDERS_CREATED
FILES_EDITED=$FILES_EDITED
FILES_DELETED=$FILES_DELETED
EOF
}

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOGDIR/activity.log"
}

# ---------- RANDOM ----------
rand() {
    echo $((RANDOM % $1))
}

# ---------- OPERATIONS ----------
create_file() {
    [[ $FILES_CREATED -ge $MAX_FILES ]] && return

    local f="$WORKDIR/file_$(rand 99999).txt"
    echo "data $(date)" > "$f"

    FILES_CREATED=$((FILES_CREATED+1))
    log "FILE + $f"
}

create_folder() {
    [[ $FOLDERS_CREATED -ge $MAX_FOLDERS ]] && return

    local d="$WORKDIR/dir_$(rand 99999)"
    mkdir -p "$d"

    FOLDERS_CREATED=$((FOLDERS_CREATED+1))
    log "DIR + $d"
}

edit_file() {
    local f
    f=$(find "$WORKDIR" -type f 2>/dev/null | shuf -n 1 || true)
    [[ -z "$f" ]] && return

    echo "update $(date)" >> "$f"
    FILES_EDITED=$((FILES_EDITED+1))
    log "EDIT $f"
}

delete_item() {
    local f
    f=$(find "$WORKDIR" -mindepth 1 2>/dev/null | shuf -n 1 || true)
    [[ -z "$f" ]] && return

    rm -rf "$f"
    FILES_DELETED=$((FILES_DELETED+1))
    log "DEL $f"
}

# ---------- ENGINE ----------
run_engine() {
    echo $$ > "$PIDFILE"

    while true; do
        case $((RANDOM % 4)) in
            0) create_file ;;
            1) create_folder ;;
            2) edit_file ;;
            3) delete_item ;;
        esac

        save_state
        sleep "$SLEEP_TIME"
    done
}

# ---------- DASHBOARD ----------
dashboard() {
    while true; do
        clear
        source "$STATE"

        echo -e "${CYN}=== AFK ULTRA GOD MODE ===${C}"
        echo -e "Files Created   : $FILES_CREATED"
        echo -e "Folders Created : $FOLDERS_CREATED"
        echo -e "Files Edited    : $FILES_EDITED"
        echo -e "Files Deleted   : $FILES_DELETED"
        echo ""
        echo -e "${P}pratik x dark${C}"

        sleep 1
    done
}

# ---------- CONTROL ----------
start() {
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "Already running"
        exit 1
    fi

    echo -e "${G}Starting AFK GOD MODE...${C}"
    run_engine
}

stop() {
    [[ -f "$PIDFILE" ]] && kill "$(cat "$PIDFILE")" 2>/dev/null && rm -f "$PIDFILE"
    echo "Stopped"
}

status() {
    [[ -f "$PIDFILE" ]] && echo "Running PID: $(cat "$PIDFILE")" || echo "Not running"
}

# ---------- MENU ----------
case "${1:-status}" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    dashboard) dashboard ;;
    *)
        echo "Usage: $0 {start|stop|status|dashboard}"
        ;;
esac
