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

    if [[ "$server" == "wallhaven" ]]; then
        # Wallhaven has no tag API — scrape the HTML tags page instead
        local sort_path="popular"
        case "$order" in
            count) sort_path="popular" ;;
            date)  sort_path="" ;;
            *)     sort_path="popular" ;;
        esac

        local tags_url="${BASE_URL}/tags"
        [[ -n "$sort_path" ]] && tags_url="${tags_url}/${sort_path}"

        local html
        html=$(mktemp)
        if ! curl -sfA "$USER_AGENT" "$tags_url" > "$html"; then
            echo "Error: Failed to fetch Wallhaven tags page" >&2
            rm -f "$html"
            return 1
        fi

        # Extract tag names from title attributes in taglist-name elements
        local tags_output
        tags_output=$(grep -oP 'taglist-name.*?title="[^"]*"' "$html" \
            | grep -oP 'title="\K[^"]+' \
            | head -"$limit")

        if [[ -z "$tags_output" ]]; then
            echo "Error: No tags found on Wallhaven tags page" >&2
            rm -f "$html"
            return 1
        fi

        if $EXPORT_TAGS; then
            local tags_list exported_file
            tags_list=$(grep -oP 'taglist-name.*?title="[^"]*"' "$html" \
                | grep -oP 'title="\K[^"]+' \
                | head -"$limit")
            exported_file=$(get_exported_tags_file)
            mkdir -p "$(dirname "$exported_file")"
            echo "$tags_list" > "$exported_file"
            echo "Exported $limit tags to $exported_file"
        else
            echo "$tags_output"
        fi
        rm -f "$html"
        return 0
    elif [[ "$server" == "danbooru" ]]; then
        local api_url="${BASE_URL}/tags.json?search[order]=${order}&search[hide_empty]=true&limit=${limit}"
        [[ -n "$pattern" ]] && api_url="${api_url}&search[name_matches]=${pattern}"

        local json
        json=$(mktemp)
        local -a curl_args=(-sgf -A "$USER_AGENT")
        [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_API_KEY" ]] && curl_args+=(-u "${DANBOORU_LOGIN}:${DANBOORU_API_KEY}")

        if curl "${curl_args[@]}" "$api_url" > "$json"; then
            local tags_output
            tags_output=$(jq -r '.[] | "\(.name) (\(.post_count) posts)"' "$json" | head -"$limit")
            if $EXPORT_TAGS; then
                local tags_list exported_file
                tags_list=$(jq -r '.[].name' "$json" | head -"$limit")
                exported_file=$(get_exported_tags_file)
                mkdir -p "$(dirname "$exported_file")"
                echo "$tags_list" > "$exported_file"
                echo "Exported $limit tags to $exported_file"
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
                local tags_list exported_file
                tags_list=$(xmllint --xpath '//tag' "$xml" | sed -n 's/.*name="\([^"]*\)".*/\1/p' | head -"$limit")
                exported_file=$(get_exported_tags_file)
                mkdir -p "$(dirname "$exported_file")"
                echo "$tags_list" > "$exported_file"
                echo "Exported $limit tags to $exported_file"
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

    if [[ "$server" == "wallhaven" ]]; then
        echo "Wallhaven does not support artist discovery."
        echo "Use --tags @username to search by uploader."
        return 0
    elif [[ "$server" == "danbooru" ]]; then
        local api_url="${BASE_URL}/artists.json?search[order]=name&limit=${limit}"
        [[ -n "$pattern" ]] && api_url="${api_url}&search[name_matches]=${pattern}"

        local json
        json=$(mktemp)
        local -a curl_args=(-sgf -A "$USER_AGENT")
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

    if [[ "$server" == "wallhaven" ]]; then
        echo "Wallhaven does not support pools."
        return 0
    elif [[ "$server" == "danbooru" ]]; then
        local api_url="${BASE_URL}/pools.json?limit=${limit}&search[order]=post_count"
        [[ -n "$query" ]] && api_url="${api_url}&search[name_contains]=${query}"

        local json
        json=$(mktemp)
        local -a curl_args=(-sgf -A "$USER_AGENT")
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
