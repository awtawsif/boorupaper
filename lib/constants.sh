#!/bin/bash
# =================================================================
# BOORUPAPER — Constants & Default Variables
# Global variables, default values, and ANSI color definitions
# =================================================================

VERSION="1.4.0"

# API base URL (can be overridden via config file for other Moebooru/Danbooru instances)
BASE_URL="${BASE_URL:-https://konachan.net}"

# Server type: auto-detected from BASE_URL, or set explicitly via --server
# Supported: "moebooru" (Konachan, Yande.re, etc.) or "danbooru"
SERVER_TYPE="${SERVER_TYPE:-}"

# Danbooru authentication (optional, required for explicit content)
DANBOORU_LOGIN="${DANBOORU_LOGIN:-}"
DANBOORU_API_KEY="${DANBOORU_API_KEY:-}"

# Custom User-Agent (Danbooru requires identifying bots)
USER_AGENT="${USER_AGENT:-Boorupaper/${VERSION}}"

# Detect server type from BASE_URL if not set
detect_server_type() {
    if [[ -n "$SERVER_TYPE" ]]; then
        echo "$SERVER_TYPE"
        return
    fi
    case "$BASE_URL" in
        *danbooru*) echo "danbooru" ;;
        *konachan*|*yande.re|*moebooru*) echo "moebooru" ;;
        *) echo "moebooru" ;;
    esac
}

# Get the post endpoint for the current server type
get_post_endpoint() {
    local st
    st=$(detect_server_type)
    case "$st" in
        danbooru)  echo "/posts.json" ;;
        moebooru)  echo "/post.json" ;;
    esac
}

# --- Default Parameters ---
TAGS=""
LIMIT=50
PAGE=1
RATING="s"
ORDER="random"
MAX_FILE_SIZE="2MB"
MIN_FILE_SIZE=""
MIN_WIDTH=""
MAX_WIDTH=""
MIN_HEIGHT=""
MAX_HEIGHT=""
ASPECT_RATIO=""
MIN_SCORE=""
ARTIST=""
POOL_ID=""
PRELOAD_COUNT=3
PREFERRED_FORMAT="jpg"
ANIMATED_ONLY=false
FORCE_SET=false
DRY_RUN=false
CLEAN_MODE=false
FORCE_CLEAN=false
INIT_INTERACTIVE=false
DISCOVER_TAGS=false
DISCOVER_ARTISTS=false
LIST_POOLS=false
SEARCH_POOLS=""
EXPORT_TAGS=false

FAV_MODE=false
LIST_FAVS=false
FROM_FAVS=false

# --- Logging Variables ---
ENABLE_LOGGING=false
LOG_FILE="$HOME/.config/boorupaper/boorupaper.log"
LOG_LEVEL="detailed"
LOG_ROTATION=true

# --- Download Tracking ---
DOWNLOADED_IDS_FILE="$HOME/.config/boorupaper/downloaded_ids"

# --- Discovery ---
get_site_name() {
    local host
    host=$(echo "$BASE_URL" | sed 's|https\?://||; s|/.*||')
    # Strip common TLDs and subdomains to get site name
    case "$host" in
        *danbooru.donmai.us)  echo "danbooru" ;;
        *konachan.net)        echo "konachan" ;;
        *konachan.com)        echo "konachan" ;;
        *yande.re)            echo "yandere" ;;
        *konachan.moe)        echo "konachan" ;;
        *)                    echo "$host" | sed 's/\.[^.]*$//' ;;
    esac
}

get_exported_tags_file() {
    local site
    site=$(get_site_name)
    echo "$HOME/.config/boorupaper/discovered_tags_${site}.txt"
}

# --- Notification Variables ---
ENABLE_NOTIFICATIONS=false
NOTIFY_TIMEOUT=5000
NOTIFY_PRELOAD=false

# --- ANSI Color Constants ---
if [[ -t 1 ]] || [[ -w /dev/tty ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_ITALIC=$'\033[3m'
    C_CYAN=$'\033[36m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_MAGENTA=$'\033[35m'
    C_BLUE=$'\033[34m'
    C_WHITE=$'\033[97m'
    C_BOLD_CYAN=$'\033[1;36m'
    C_BOLD_GREEN=$'\033[1;32m'
    C_BOLD_YELLOW=$'\033[1;33m'
    C_BOLD_RED=$'\033[1;31m'
    C_BOLD_MAGENTA=$'\033[1;35m'
    C_BOLD_WHITE=$'\033[1;97m'
    C_BG_CYAN=$'\033[46m'
else
    C_RESET="" C_BOLD="" C_DIM="" C_ITALIC=""
    C_CYAN="" C_GREEN="" C_YELLOW="" C_RED="" C_MAGENTA="" C_BLUE="" C_WHITE=""
    C_BOLD_CYAN="" C_BOLD_GREEN="" C_BOLD_YELLOW="" C_BOLD_RED=""
    C_BOLD_MAGENTA="" C_BOLD_WHITE="" C_BG_CYAN=""
fi

# --- Wallpaper Tool Default Commands ---
# Used by init wizard when no custom command is specified.
WALLPAPER_COMMAND_AWWW='awww img {IMAGE} --transition-type any --transition-fps 60 --transition-duration 1'
WALLPAPER_COMMAND_MPVPAPER='mpvpaper -f -o "loop" ALL {IMAGE}'
WALLPAPER_COMMAND_SWAYBG='pkill -f swaybg; swaybg -o '"'"'*'"'"' {IMAGE} &'
WALLPAPER_COMMAND_HYPRPAPER='hyprctl hyprpaper preload {IMAGE}; for monitor in $(hyprctl monitors -j | jq -r '"'"'.[].name'"'"'); do hyprctl hyprpaper wallpaper "${monitor},{IMAGE}"; done'
WALLPAPER_COMMAND_FEH='feh --bg-scale {IMAGE}'
WALLPAPER_COMMAND_NITROGEN='nitrogen --set-scaled --save {IMAGE}'
WALLPAPER_COMMAND_XWALLPAPER='xwallpaper --zoom {IMAGE}'
