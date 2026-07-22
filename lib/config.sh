#!/bin/bash
# =================================================================
# BOORUPAPER — Configuration Loading
# Config file resolution and loading
# =================================================================

# User config path only. Defaults live in constants.sh; the user config
# overrides them. See man/boorupaper.conf.5 for documentation.
CONFIG_FILE="$HOME/.config/boorupaper/boorupaper.conf"

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi

    # If RANDOM_TAGS_LIST is a file path (no parentheses), load tags from it
    if [[ -n "$RANDOM_TAGS_LIST" && "$RANDOM_TAGS_LIST" != *'('* ]]; then
        local tags_file="$RANDOM_TAGS_LIST"
        # Prefer site-specific file (e.g. discovered_tags_konachan.txt)
        local site_file
        site_file=$(get_exported_tags_file)
        if [[ -f "$site_file" ]]; then
            tags_file="$site_file"
        elif [[ -f "$tags_file" ]]; then
            tags_file="$tags_file"
        fi
        if [[ -f "$tags_file" ]]; then
            mapfile -t RANDOM_TAGS_LIST < "$tags_file"
        fi
    fi

    WALLPAPER_COMMAND=${WALLPAPER_COMMAND:-""}
    
    # Load logging configuration
    ENABLE_LOGGING=${ENABLE_LOGGING:-false}
    LOG_FILE=${LOG_FILE:-"$HOME/.config/boorupaper/boorupaper.log"}
    LOG_LEVEL=${LOG_LEVEL:-"detailed"}
    LOG_ROTATION=${LOG_ROTATION:-true}
}

process_random_tags() {
    if [[ "${#RANDOM_TAGS_LIST[@]}" -gt 0 && "$RANDOM_TAGS_COUNT" -gt 0 ]]; then
        local selected_tags
        selected_tags=$(printf "%s\n" "${RANDOM_TAGS_LIST[@]}" | shuf -n "$RANDOM_TAGS_COUNT" | tr '\n' ' ')
        if [[ -n "$TAGS" ]]; then
            TAGS="$TAGS $selected_tags"
        else
            TAGS="$selected_tags"
        fi
        # Trim leading/trailing whitespace
        TAGS="${TAGS#"${TAGS%%[![:space:]]*}"}"
        TAGS="${TAGS%"${TAGS##*[![:space:]]}"}"
    fi
}
