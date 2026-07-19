#!/bin/bash
# =================================================================
# BOORUPAPER — Discovery Functions
# Tag discovery, artist discovery, and pool listing
# =================================================================

discover_tags() {
    local pattern="${1:-}"
    local order="${2:-count}"
    local limit="${3:-$DISCOVER_LIMIT}"
    local server
    server=$(detect_server_type)

    echo "Discovering tags..."

    if [[ "$server" == "danbooru" ]]; then
        local api_url="${BASE_URL}/tags.json?search[order]=${order}&search[hide_empty]=true&limit=${limit}"
        [[ -n "$pattern" ]] && api_url="${api_url}&search[name_matches]=${pattern}"

        local json
        json=$(mktemp)
        local -a curl_args=(-sf -A "$USER_AGENT")
        [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_API_KEY" ]] && curl_args+=(-u "${DANBOORU_LOGIN}:${DANBOORU_API_KEY}")

        if curl "${curl_args[@]}" "$api_url" > "$json"; then
            local tags_output
            tags_output=$(jq -r '.[] | "\(.name) (\(.post_count) posts)"' "$json" | head -"$limit")
            if $EXPORT_TAGS; then
                local tags_list
                tags_list=$(jq -r '.[].name' "$json" | head -"$limit")
                mkdir -p "$(dirname "$EXPORTED_TAGS_FILE")"
                echo "$tags_list" > "$EXPORTED_TAGS_FILE"
                echo "Exported $limit tags to $EXPORTED_TAGS_FILE"
            else
                echo "$tags_output"
            fi
        else
            echo "Error: Failed to fetch tags" >&2
            rm -f "$json"
            return 1
        fi
        rm -f "$json"
    else
        local api_url="${BASE_URL}/tag.xml?order=${order}&limit=${limit}"
        [[ -n "$pattern" ]] && api_url="${api_url}&name_pattern=${pattern}"

        local xml
        xml=$(mktemp)
        if curl -sf "$api_url" > "$xml"; then
            local tags_output
            tags_output=$(xmllint --xpath '//tag' "$xml" | sed -n 's/.*name="\([^"]*\)".*count="\([^"]*\)".*/\1 (\2 posts)/p' | head -"$limit")
            if $EXPORT_TAGS; then
                local tags_list
                tags_list=$(xmllint --xpath '//tag' "$xml" | sed -n 's/.*name="\([^"]*\)".*/\1/p' | head -"$limit")
                mkdir -p "$(dirname "$EXPORTED_TAGS_FILE")"
                echo "$tags_list" > "$EXPORTED_TAGS_FILE"
                echo "Exported $limit tags to $EXPORTED_TAGS_FILE"
            else
                echo "$tags_output"
            fi
        else
            echo "Error: Failed to fetch tags" >&2
            rm -f "$xml"
            return 1
        fi
        rm -f "$xml"
    fi
}

discover_artists() {
    local pattern="${1:-}"
    local limit="${2:-$DISCOVER_LIMIT}"
    local server
    server=$(detect_server_type)

    echo "Discovering artists..."

    if [[ "$server" == "danbooru" ]]; then
        local api_url="${BASE_URL}/artists.json?search[order]=name&limit=${limit}"
        [[ -n "$pattern" ]] && api_url="${api_url}&search[name_matches]=${pattern}"

        local json
        json=$(mktemp)
        local -a curl_args=(-sf -A "$USER_AGENT")
        [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_API_KEY" ]] && curl_args+=(-u "${DANBOORU_LOGIN}:${DANBOORU_API_KEY}")

        if curl "${curl_args[@]}" "$api_url" > "$json"; then
            jq -r '.[].name' "$json" | head -"$limit"
        else
            echo "Error: Failed to fetch artists" >&2
            rm -f "$json"
            return 1
        fi
        rm -f "$json"
    else
        local api_url="${BASE_URL}/artist.xml?order=name&limit=${limit}"
        [[ -n "$pattern" ]] && api_url="${api_url}&name=${pattern}"

        local xml
        xml=$(mktemp)
        if curl -sf "$api_url" > "$xml"; then
            xmllint --xpath '//artist' "$xml" | sed -n 's/.*name="\([^"]*\)".*/\1/p' | head -"$limit"
        else
            echo "Error: Failed to fetch artists" >&2
            rm -f "$xml"
            return 1
        fi
        rm -f "$xml"
    fi
}

list_pools() {
    local query="${1:-}"
    local limit="${2:-$DISCOVER_LIMIT}"
    local server
    server=$(detect_server_type)

    echo "Listing pools..."

    if [[ "$server" == "danbooru" ]]; then
        local api_url="${BASE_URL}/pools.json?limit=${limit}&search[order]=post_count"
        [[ -n "$query" ]] && api_url="${api_url}&search[name_contains]=${query}"

        local json
        json=$(mktemp)
        local -a curl_args=(-sf -A "$USER_AGENT")
        [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_API_KEY" ]] && curl_args+=(-u "${DANBOORU_LOGIN}:${DANBOORU_API_KEY}")

        if curl "${curl_args[@]}" "$api_url" > "$json"; then
            jq -r '.[] | "\(.id): \(.name) (\(.post_ids | length) posts)"' "$json" | head -"$limit"
        else
            echo "Error: Failed to fetch pools" >&2
            rm -f "$json"
            return 1
        fi
        rm -f "$json"
    else
        local api_url="${BASE_URL}/pool.xml?limit=${limit}"
        [[ -n "$query" ]] && api_url="${api_url}&query=${query}"

        local xml
        xml=$(mktemp)
        if curl -sf "$api_url" > "$xml"; then
            xmllint --xpath '//pool' "$xml" | sed -n 's/.*id="\([^"]*\)".*name="\([^"]*\)".*post_count="\([^"]*\)".*/\1: \2 (\3 posts)/p' | head -"$limit"
        else
            echo "Error: Failed to fetch pools" >&2
            rm -f "$xml"
            return 1
        fi
        rm -f "$xml"
    fi
}
