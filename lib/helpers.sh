#!/bin/bash
# =================================================================
# BOORUPAPER — Helper Functions
# Size converters, aspect ratio parser, page argument parser
# =================================================================

convert_to_bytes() {
    local size_str="$1"
    size_str=$(echo "$size_str" | tr '[:lower:]' '[:upper:]')
    if [[ "$size_str" =~ ^[0-9]+$ ]]; then
        echo "$size_str"
    elif [[ "$size_str" =~ ^([0-9]+(\.[0-9]+)?)KB$ ]]; then
        awk "BEGIN {printf \"%d\", ${BASH_REMATCH[1]} * 1024}"
    elif [[ "$size_str" =~ ^([0-9]+(\.[0-9]+)?)MB$ ]]; then
        awk "BEGIN {printf \"%d\", ${BASH_REMATCH[1]} * 1024 * 1024}"
    elif [[ "$size_str" =~ ^([0-9]+(\.[0-9]+)?)GB$ ]]; then
        awk "BEGIN {printf \"%d\", ${BASH_REMATCH[1]} * 1024 * 1024 * 1024}"
    else
        echo "Error: invalid size format '$1' (use e.g. 500KB or 2MB)" >&2
        exit 1
    fi
}

human_readable_size() {
    local bytes="$1"
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        awk "BEGIN {printf \"%.1fKB\", $bytes/1024}"
    else
        awk "BEGIN {printf \"%.2fMB\", $bytes/1048576}"
    fi
}

parse_aspect_ratio() {
    local input="$1"
    local ratios=()
    IFS=',' read -r -a input_ratios <<< "$input"

    for ratio in "${input_ratios[@]}"; do
        case "$ratio" in
            "16:9") ratios+=("1.78") ;;
            "21:9") ratios+=("2.37") ;;
            "4:3") ratios+=("1.33") ;;
            "1:1") ratios+=("1.00") ;;
            "3:2") ratios+=("1.50") ;;
            "5:4") ratios+=("1.25") ;;
            "32:9") ratios+=("3.56") ;;
            *)
                if [[ "$ratio" =~ ^([0-9]+):([0-9]+)$ ]]; then
                    ratios+=("$(awk "BEGIN {printf \"%.2f\", ${BASH_REMATCH[1]}/${BASH_REMATCH[2]}}")")
                else
                    echo "Error: invalid aspect ratio '$ratio' (use format like '16:9' or '16:9,4:3')" >&2
                    exit 1
                fi
                ;;
        esac
    done

    # Output as JSON array
    local json="["
    for i in "${!ratios[@]}"; do
        json+="${ratios[$i]}"
        [[ $i -lt $((${#ratios[@]} - 1)) ]] && json+=", "
    done
    json+="]"
    echo "$json"
}

parse_page_argument() {
    local arg="$1"

    # Handle "random" or "rand" (default range 1-1000)
    if [[ "$arg" == "random" || "$arg" == "rand" ]]; then
        echo $((RANDOM % 1000 + 1))
        return 0
    fi

    # Handle range format: "random:MIN-MAX" or "MIN-MAX"
    if [[ "$arg" =~ ^(random:)?([0-9]+)-([0-9]+)$ ]]; then
        local min="${BASH_REMATCH[2]}"
        local max="${BASH_REMATCH[3]}"

        if (( min >= max )); then
            echo "Error: Invalid range '$arg' (min must be less than max)" >&2
            return 1
        fi

        echo $((RANDOM % (max - min + 1) + min))
        return 0
    fi

    # Handle plain numeric page
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        echo "$arg"
        return 0
    fi

    # Invalid format
    echo "Error: Invalid page format '$arg'. Use number, 'random', or 'MIN-MAX'" >&2
    return 1
}

# Build the jq filter for selecting posts with optional dimension/size filtering.
# Returns a jq filter string that selects posts matching the given constraints.
# Globals used: MAX_FILE_SIZE_BYTES, MIN_FILE_SIZE_BYTES, MIN_WIDTH_NUM,
#   MAX_WIDTH_NUM, MIN_HEIGHT_NUM, MAX_HEIGHT_NUM, ASPECT_RATIO_JSON, SERVER_TYPE,
#   RATING, MIN_SCORE, ORDER.
build_jq_filter() {
    local use_filters="$1"  # "true" if dimension/size filters are active
    local server
    server=$(detect_server_type)

    if [[ "$server" == "danbooru" ]]; then
        # Danbooru client-side filters: only applied when metatags didn't fit
        local rating_code=""
        local score_code=""
        local sort_code=""

        if [[ "${DANBOORU_CLIENT_RATING}" == "true" && -n "$RATING" ]]; then
            rating_code="and (.rating == \"$RATING\")"
        fi
        if [[ "${DANBOORU_CLIENT_SCORE}" == "true" && -n "$MIN_SCORE" ]]; then
            score_code="and ((.score // 0) >= $MIN_SCORE)"
        fi
        if [[ "${DANBOORU_CLIENT_ORDER}" == "true" ]]; then
            case "$ORDER" in
                score) sort_code=" | sort_by(.score // 0) | reverse" ;;
                date)  sort_code=" | sort_by(.created_at // \"\") | reverse" ;;
            esac
        fi

        if [[ "$use_filters" == "true" ]]; then
            cat <<JQFILTER
if type == "array" then . else .posts? // . end |
 map(select(
  type == "object" and
  .file_size != null and
  .image_width != null and
  .image_height != null and
  (.file_size <= \$max_size or \$max_size == 0) and
  (.file_size >= \$min_size or \$min_size == 0) and
  (.image_width <= \$max_width or \$max_width == 0) and
  (.image_width >= \$min_width or \$min_width == 0) and
  (.image_height <= \$max_height or \$max_height == 0) and
  (.image_height >= \$min_height or \$min_height == 0) and
  (if (\$aspect_ratio | length == 0) then true else . as \$p | any(\$aspect_ratio[]; . as \$r | (\$p.image_width / \$p.image_height >= (\$r - 0.02) and \$p.image_width / \$p.image_height <= (\$r + 0.02))) end)
  ${rating_code} ${score_code}
 ))${sort_code} |
 .[] | "\(.id)|\(.file_url)"
JQFILTER
        else
            if [[ -n "$rating_code" || -n "$score_code" || -n "$sort_code" ]]; then
                cat <<JQFILTER
if type == "array" then . else .posts? // . end |
 map(select(
  type == "object"
  ${rating_code} ${score_code}
 ))${sort_code} |
 .[] | "\(.id)|\(.file_url)"
JQFILTER
            else
                echo 'if type == "array" then . else .posts? // . end | .[] | "\(.id)|\(.file_url)"'
            fi
        fi
    else
        if [[ "$use_filters" == "true" ]]; then
            cat <<'JQFILTER'
if type == "array" then . else .posts? // . end |
 map(select(
  type == "object" and
  .file_size != null and
  .width != null and
  .height != null and
  (.file_size <= $max_size or $max_size == 0) and
  (.file_size >= $min_size or $min_size == 0) and
  (.width <= $max_width or $max_width == 0) and
  (.width >= $min_width or $min_width == 0) and
  (.height <= $max_height or $max_height == 0) and
  (.height >= $min_height or $min_height == 0) and
  (if ($aspect_ratio | length == 0) then true else . as $p | any($aspect_ratio[]; . as $r | ($p.width / $p.height >= ($r - 0.02) and $p.width / $p.height <= ($r + 0.02))) end)
 )) |
 .[] | "\(.id)|\(.file_url)"
JQFILTER
        else
            echo 'if type == "array" then . else .posts? // . end | .[] | "\(.id)|\(.file_url)"'
        fi
    fi
}

# Build the jq filter for dry-run display output (tabular format).
build_jq_dry_run_filter() {
    local use_filters="$1"
    local server
    server=$(detect_server_type)

    if [[ "$server" == "danbooru" ]]; then
        local rating_code=""
        local score_code=""
        local sort_code=""

        if [[ "${DANBOORU_CLIENT_RATING}" == "true" && -n "$RATING" ]]; then
            rating_code="and (.rating == \"$RATING\")"
        fi
        if [[ "${DANBOORU_CLIENT_SCORE}" == "true" && -n "$MIN_SCORE" ]]; then
            score_code="and ((.score // 0) >= $MIN_SCORE)"
        fi
        if [[ "${DANBOORU_CLIENT_ORDER}" == "true" ]]; then
            case "$ORDER" in
                score) sort_code=" | sort_by(.score // 0) | reverse" ;;
                date)  sort_code=" | sort_by(.created_at // \"\") | reverse" ;;
            esac
        fi

        if [[ "$use_filters" == "true" ]]; then
            cat <<JQFILTER
if type == "array" then . else .posts? // . end |
 map(select(
    type == "object" and
    .file_size != null and
    .image_width != null and
    .image_height != null and
    (.file_size <= \$max_size or \$max_size == 0) and
    (.file_size >= \$min_size or \$min_size == 0) and
    (.image_width <= \$max_width or \$max_width == 0) and
    (.image_width >= \$min_width or \$min_width == 0) and
    (.image_height <= \$max_height or \$max_height == 0) and
    (.image_height >= \$min_height or \$min_height == 0) and
    (if (\$aspect_ratio | length == 0) then true else . as \$p | any(\$aspect_ratio[]; . as \$r | (\$p.image_width / \$p.image_height >= (\$r - 0.02) and \$p.image_width / \$p.image_height <= (\$r + 0.02))) end)
    ${rating_code} ${score_code}
 ))${sort_code} |
 map([.id, (.score // 0), (.uploader_id // "unknown"), .image_width, .image_height, (.file_size|tostring), (.tag_string | .[0:50])]) |
 .[] | @tsv
JQFILTER
        else
            if [[ -n "$rating_code" || -n "$score_code" || -n "$sort_code" ]]; then
                cat <<JQFILTER
if type == "array" then . else .posts? // . end |
 map(select(
    type == "object"
    ${rating_code} ${score_code}
 ))${sort_code} |
 map([.id, (.score // 0), (.uploader_id // "unknown"), .image_width, .image_height, (.file_size|tostring), (.tag_string | .[0:50])]) |
 .[] | @tsv
JQFILTER
            else
                echo 'if type == "array" then . else .posts? // . end | map([.id, (.score // 0), (.uploader_id // "unknown"), .image_width, .image_height, (.file_size|tostring), (.tag_string | .[0:50])]) | .[] | @tsv'
            fi
        fi
    else
        if [[ "$use_filters" == "true" ]]; then
            cat <<'JQFILTER'
if type == "array" then . else .posts? // . end |
 map(select(
    type == "object" and
    .file_size != null and
    .width != null and
    .height != null and
    (.file_size <= $max_size or $max_size == 0) and
    (.file_size >= $min_size or $min_size == 0) and
    (.width <= $max_width or $max_width == 0) and
    (.width >= $min_width or $min_width == 0) and
    (.height <= $max_height or $max_height == 0) and
    (.height >= $min_height or $min_height == 0) and
    (if ($aspect_ratio | length == 0) then true else . as $p | any($aspect_ratio[]; . as $r | ($p.width / $p.height >= ($r - 0.02) and $p.width / $p.height <= ($r + 0.02))) end)
 )) |
 map([.id, (.score // 0), (.author // "unknown"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) |
 .[] | @tsv
JQFILTER
        else
            echo 'if type == "array" then . else .posts? // . end | map([.id, (.score // 0), (.author // "unknown"), .width, .height, (.file_size|tostring), (.tags | .[0:50])]) | .[] | @tsv'
        fi
    fi
}
