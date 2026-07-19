#!/bin/bash
# =================================================================
# BOORUPAPER — Download Function
# Handles API querying, filtering, and image downloading
# =================================================================

# Retrieve previously downloaded post IDs to avoid duplicates.
get_downloaded_ids() {
    if [[ -f "$DOWNLOADED_IDS_FILE" ]]; then
        cat "$DOWNLOADED_IDS_FILE"
    fi
}

# Filter posts from JSON and select a random candidate not already downloaded.
# Writes SELECTED_ID and IMAGE_URL to stdout as "ID|URL", or nothing if no match.
# Uses global variables: MAX_FILE_SIZE_BYTES, MIN_FILE_SIZE_BYTES, MIN_WIDTH_NUM,
#   MAX_WIDTH_NUM, MIN_HEIGHT_NUM, MAX_HEIGHT_NUM, ASPECT_RATIO_JSON
filter_and_select_post() {
    local json="$1"
    local downloaded_ids="$2"
    local use_filters="$3"  # "true" if dimension/size filters are active

    local jq_filter
    jq_filter=$(build_jq_filter "$use_filters")

    local all_candidates
    all_candidates=$(jq -r \
        --argjson max_size "$MAX_FILE_SIZE_BYTES" \
        --argjson min_size "$MIN_FILE_SIZE_BYTES" \
        --argjson max_width "$MAX_WIDTH_NUM" \
        --argjson min_width "$MIN_WIDTH_NUM" \
        --argjson max_height "$MAX_HEIGHT_NUM" \
        --argjson min_height "$MIN_HEIGHT_NUM" \
        --argjson aspect_ratio "$ASPECT_RATIO_JSON" \
        "$jq_filter" "$json")

    if [[ -z "$all_candidates" ]]; then
        return 1
    fi

    # Try to pick one not already downloaded
    if [[ -n "$downloaded_ids" ]]; then
        local new_candidates
        new_candidates=$(echo "$all_candidates" | grep -vxFf <(echo "$downloaded_ids") | shuf)
        if [[ -n "$new_candidates" ]]; then
            echo "$new_candidates" | head -n1
            return 0
        fi
    fi

    # Fallback: pick any random entry
    echo "$all_candidates" | shuf -n 1
    return 0
}

download_wallpaper() {
    local outfile="$1"
    local ENCODED_TAGS
    local server
    server=$(detect_server_type)

    # Get wallpaper tool for format decisions
    local detection
    detection=$(detect_display_server)
    local wallpaper_tool="${detection#*:}"
    
    # Determine effective tags based on ANIMATED_ONLY
    local effective_tags
    if [[ "$ANIMATED_ONLY" == "true" ]]; then
        effective_tags="animated"
    else
        effective_tags="$TAGS"
    fi
    
    # Add animated tag if needed
    local format_filter
    format_filter=$(get_format_filter "$PREFERRED_FORMAT")
    if [[ -n "$format_filter" && "$effective_tags" != *"$format_filter"* ]]; then
        if [[ -n "$effective_tags" ]]; then
            effective_tags="${effective_tags} ${format_filter}"
        else
            effective_tags="${format_filter}"
        fi
    fi

    local API_URL
    local -a curl_args=(-s)
    curl_args+=(-A "$USER_AGENT")

    if [[ "$server" == "danbooru" ]]; then
        # Danbooru API: anonymous users limited to ~3 tags total.
        # Metatags (rating:*, order:*, score:*) each count as tags.
        # Strategy: send user tags + as many metatags as fit, then
        # filter remaining constraints client-side in jq.

        local danbooru_tags="$effective_tags"

        # Count user tags (space-separated words)
        local tag_count=0
        if [[ -n "$danbooru_tags" ]]; then
            tag_count=$(echo "$danbooru_tags" | wc -w)
        fi
        local metatag_budget=$((3 - tag_count))
        (( metatag_budget < 0 )) && metatag_budget=0

        # Add artist filter (Danbooru uses artist name as tag) — counts as a tag
        if [[ -n "$ARTIST" ]] && (( metatag_budget > 0 )); then
            danbooru_tags="${danbooru_tags} ${ARTIST}"
            (( metatag_budget-- ))
        fi

        # Add rating as server-side metatag if room
        local client_side_rating=false
        if [[ -n "$RATING" ]] && (( metatag_budget > 0 )); then
            local rating_tag
            case "$RATING" in
                g) rating_tag="rating:general" ;;
                s) rating_tag="rating:sensitive" ;;
                q) rating_tag="rating:questionable" ;;
                e) rating_tag="rating:explicit" ;;
                *) rating_tag="rating:sensitive" ;;
            esac
            danbooru_tags="${danbooru_tags} ${rating_tag}"
            (( metatag_budget-- ))
        elif [[ -n "$RATING" ]]; then
            client_side_rating=true
        fi

        # Add order as server-side metatag if room (only for non-random)
        local client_side_order=false
        if [[ "$ORDER" != "random" && -n "$ORDER" ]] && (( metatag_budget > 0 )); then
            local order_tag
            case "$ORDER" in
                score) order_tag="order:score" ;;
                date)  order_tag="order:date" ;;
            esac
            if [[ -n "$order_tag" ]]; then
                danbooru_tags="${danbooru_tags} ${order_tag}"
                (( metatag_budget-- ))
            fi
        elif [[ "$ORDER" != "random" ]]; then
            client_side_order=true
        fi

        # Add score filter as server-side metatag if room
        local client_side_score=false
        if [[ -n "$MIN_SCORE" ]] && (( metatag_budget > 0 )); then
            danbooru_tags="${danbooru_tags} score:>=${MIN_SCORE}"
            (( metatag_budget-- ))
        elif [[ -n "$MIN_SCORE" ]]; then
            client_side_score=true
        fi

        # Export client-side flags for jq filter
        export DANBOORU_CLIENT_RATING="$client_side_rating"
        export DANBOORU_CLIENT_SCORE="$client_side_score"
        export DANBOORU_CLIENT_ORDER="$client_side_order"

        # For random ordering, use a random page number for variety
        local effective_page="$PAGE"
        if [[ "$ORDER" == "random" && "$PAGE" == "1" ]]; then
            effective_page=$((RANDOM % 50 + 1))
        fi

        # Encode spaces as + for URL
        local encoded_tags="${danbooru_tags// /+}"

        if [[ -n "$POOL_ID" ]]; then
            API_URL="${BASE_URL}/pools/${POOL_ID}.json"
        else
            API_URL="${BASE_URL}/posts.json?limit=${LIMIT}&page=${effective_page}&tags=${encoded_tags}"
        fi

        # Add authentication if credentials are set (raises tag limit)
        if [[ -n "$DANBOORU_LOGIN" && -n "$DANBOORU_API_KEY" ]]; then
            curl_args+=(-u "${DANBOORU_LOGIN}:${DANBOORU_API_KEY}")
        fi
    else
        # Moebooru API: tags are + separated, rating/score/order appended
        local encoded_effective_tags="${effective_tags// /+}"

        if [[ -n "$POOL_ID" ]]; then
            API_URL="${BASE_URL}/pool/show.json?id=${POOL_ID}"
        else
            API_URL="${BASE_URL}/post.json?limit=${LIMIT}&page=${PAGE}&tags=${encoded_effective_tags}+rating:${RATING}+order:${ORDER}"
            [[ -n "$MIN_SCORE" ]] && API_URL="${API_URL}+score:>=${MIN_SCORE}"
            [[ -n "$ARTIST" ]] && API_URL="${API_URL}+user:${ARTIST}"

            if [[ "$RATING" != "s" && "$BASE_URL" == *"konachan.net"* ]]; then
                echo "Warning: konachan.net is SFW-only and does not serve rating='$RATING' content." >&2
                echo "Set BASE_URL in your config to a Moebooru instance that supports all ratings." >&2
                log_warning "konachan.net does not support rating='$RATING'; set BASE_URL in config for full ratings"
            fi
        fi
    fi

    echo "-> Querying API: $API_URL"
    log_api_call "$API_URL"
    log_file_operation "create" "temp_json_file"
    notify_progress_update "Querying API" "Fetching from ${server}..."
    local json
    json=$(mktemp)
    local http_code
    http_code=$(curl "${curl_args[@]}" -w '%{http_code}' -o "$json" "$API_URL")
    if [[ "$http_code" -ge 400 ]]; then
        local error_msg
        error_msg=$(jq -r '.message // .error // "Unknown error"' "$json" 2>/dev/null || echo "HTTP $http_code")
        echo "Error: API returned HTTP $http_code — $error_msg" >&2
        log_error "API request failed: HTTP $http_code — $error_msg"
        log_file_operation "delete" "$json"
        rm -f "$json"
        return 1
    fi
    if [[ "$http_code" -eq 0 ]]; then
        echo "Error: failed to reach $BASE_URL" >&2
        log_error "API request failed: $BASE_URL"
        log_file_operation "delete" "$json"
        rm -f "$json"
        return 1
    fi

    # Determine if dimension/size filters are active (needed for both dry-run and normal mode)
    local use_filters="false"
    if (( MAX_FILE_SIZE_BYTES != 0 || MIN_FILE_SIZE_BYTES != 0 )) || \
       [[ -n "$MIN_WIDTH" || -n "$MAX_WIDTH" || -n "$MIN_HEIGHT" || -n "$MAX_HEIGHT" || "$ASPECT_RATIO_JSON" != "[]" ]]; then
        use_filters="true"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_write "INFO" "Dry run mode: displaying available posts"
        echo "---- Available Posts ----"
        printf "ID\tScore\tAuthor\tWidth\tHeight\tSize\tTags\n"
        local dry_run_filter
        dry_run_filter=$(build_jq_dry_run_filter "$use_filters")
        if [[ "$use_filters" == "true" ]]; then
            jq -r --argjson max_size "$MAX_FILE_SIZE_BYTES" --argjson min_size "$MIN_FILE_SIZE_BYTES" \
                --argjson max_width "$MAX_WIDTH_NUM" --argjson min_width "$MIN_WIDTH_NUM" \
                --argjson max_height "$MAX_HEIGHT_NUM" --argjson min_height "$MIN_HEIGHT_NUM" \
                --argjson aspect_ratio "$ASPECT_RATIO_JSON" \
                "$dry_run_filter" "$json"
        else
            jq -r "$dry_run_filter" "$json"
        fi
        log_file_operation "delete" "$json"
        rm -f "$json"
        return 0
    fi

local IMAGE_URL
    local SELECTED_ID=""

    local downloaded_ids
    downloaded_ids=$(get_downloaded_ids)

    local selected
    if selected=$(filter_and_select_post "$json" "$downloaded_ids" "$use_filters"); then
        SELECTED_ID=$(echo "$selected" | cut -d'|' -f1)
        IMAGE_URL=$(echo "$selected" | cut -d'|' -f2)
    fi

    rm -f "$json"

    if [ -z "$IMAGE_URL" ]; then
        if (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES == 0 )); then
            echo "Error: no suitable image found." >&2
        elif (( MAX_FILE_SIZE_BYTES > 0 && MIN_FILE_SIZE_BYTES == 0 )); then
            echo "Error: no suitable image found under ${MAX_FILE_SIZE}." >&2
        elif (( MAX_FILE_SIZE_BYTES == 0 && MIN_FILE_SIZE_BYTES > 0 )); then
            echo "Error: no suitable image found over ${MIN_FILE_SIZE}." >&2
        else
            echo "Error: no suitable image found between ${MIN_FILE_SIZE} and ${MAX_FILE_SIZE}." >&2
        fi
        notify_error "No Results" "No wallpaper matched your filters"
        return 1
    fi

    echo "-> Downloading: $IMAGE_URL"
    log_write "INFO" "Downloading image: $IMAGE_URL"
    log_file_operation "download" "$outfile" "from $IMAGE_URL"
    notify_progress_update "Downloading" "Fetching image..."

    # Get extension from URL and update outfile path
    local ext
    ext=$(get_extension_from_url "$IMAGE_URL")
    local outfile_with_ext="${outfile}.${ext}"

    # Store the actual URL in a per-job temp file to avoid race conditions
    # during concurrent preload operations (outfile base is unique per job)
    echo "$IMAGE_URL" > "${outfile}.url"

    # Ensure cleanup of metadata and base temp files on exit
    trap 'rm -f "${outfile}.url" "$outfile" 2>/dev/null' RETURN

    local tmpfile="${outfile_with_ext}.tmp"
    if ! curl -sfL -A "$USER_AGENT" "$IMAGE_URL" -o "$tmpfile"; then
        echo "Error: download failed." >&2
        log_error "Download failed: $IMAGE_URL"
        log_file_operation "delete" "$tmpfile"
        rm -f "$tmpfile"
        notify_error "Download Failed" "Could not download image"
        return 1
    fi
    
    mv "$tmpfile" "$outfile_with_ext"

    local size
    size=$(stat -c%s "$outfile_with_ext")
    if (( MAX_FILE_SIZE_BYTES > 0 && size > MAX_FILE_SIZE_BYTES )); then
        echo "Skipped (too large: $(human_readable_size "$size"))" >&2
        log_warning "Image skipped due to size limit: $(human_readable_size "$size") > $MAX_FILE_SIZE"
        log_file_operation "delete" "$outfile_with_ext" "size limit exceeded"
        rm -f "$outfile_with_ext"
        notify_error "Too Large" "Image $(human_readable_size "$size") exceeds $(human_readable_size "$MAX_FILE_SIZE")"
        return 1
    fi
    if (( MIN_FILE_SIZE_BYTES > 0 && size < MIN_FILE_SIZE_BYTES )); then
        echo "Skipped (too small: $(human_readable_size "$size"))" >&2
        log_warning "Image skipped due to minimum size: $(human_readable_size "$size") < $MIN_FILE_SIZE"
        log_file_operation "delete" "$outfile_with_ext" "below minimum size"
        rm -f "$outfile_with_ext"
        notify_error "Too Small" "Image $(human_readable_size "$size") below minimum $(human_readable_size "$MIN_FILE_SIZE")"
        return 1
    fi

    echo "-> Download complete ($(human_readable_size "$size"))"
    log_success "Image downloaded successfully: $outfile_with_ext ($(human_readable_size "$size"))"
    notify_progress_update "Download complete" "$(human_readable_size "$size")"
    
    if [[ -n "$SELECTED_ID" ]]; then
        # Use flock for atomic append to prevent corruption from concurrent writes
        (
            flock -x 200
            echo "$SELECTED_ID" >> "$DOWNLOADED_IDS_FILE"
        ) 200>"${DOWNLOADED_IDS_FILE}.lock"
    fi
    
    return 0
}
