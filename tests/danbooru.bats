#!/usr/bin/env bats

load test_helper

setup() {
    source_lib "constants"
    source_lib "helpers"
    source_lib "cli"
}

# =============================================================================
# Server type detection tests
# =============================================================================

@test "detect_server_type: defaults to moebooru for konachan.net" {
    BASE_URL="https://konachan.net"
    SERVER_TYPE=""
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "moebooru" ]
}

@test "detect_server_type: detects danbooru from URL" {
    BASE_URL="https://danbooru.donmai.us"
    SERVER_TYPE=""
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "danbooru" ]
}

@test "detect_server_type: detects moebooru from yande.re" {
    BASE_URL="https://yande.re"
    SERVER_TYPE=""
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "moebooru" ]
}

@test "detect_server_type: explicit SERVER_TYPE overrides URL detection" {
    BASE_URL="https://danbooru.donmai.us"
    SERVER_TYPE="moebooru"
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "moebooru" ]
}

@test "detect_server_type: explicit danbooru SERVER_TYPE" {
    BASE_URL="https://konachan.net"
    SERVER_TYPE="danbooru"
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "danbooru" ]
}

@test "detect_server_type: defaults to moebooru for unknown URL" {
    BASE_URL="https://example.com"
    SERVER_TYPE=""
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "moebooru" ]
}

# =============================================================================
# get_post_endpoint tests
# =============================================================================

@test "get_post_endpoint: returns /posts.json for danbooru" {
    SERVER_TYPE="danbooru"
    run get_post_endpoint
    [ "$status" -eq 0 ]
    [ "$output" = "/posts.json" ]
}

@test "get_post_endpoint: returns /post.json for moebooru" {
    SERVER_TYPE="moebooru"
    run get_post_endpoint
    [ "$status" -eq 0 ]
    [ "$output" = "/post.json" ]
}

# =============================================================================
# Danbooru jq filter tests
# =============================================================================

@test "build_jq_filter: Danbooru without filters uses image_width/image_height in filter" {
    SERVER_TYPE="danbooru"
    run build_jq_filter "false"
    [ "$status" -eq 0 ]
    [[ "$output" == *'.[] | "\(.id)|\(.file_url)"'* ]]
}

@test "build_jq_filter: Danbooru with filters uses image_width/image_height" {
    SERVER_TYPE="danbooru"
    run build_jq_filter "true"
    [ "$status" -eq 0 ]
    [[ "$output" == *".image_width"* ]]
    [[ "$output" == *".image_height"* ]]
    [[ "$output" == *'.[] | "\(.id)|\(.file_url)"'* ]]
}

@test "build_jq_filter: Moebooru with filters uses width/height" {
    SERVER_TYPE="moebooru"
    run build_jq_filter "true"
    [ "$status" -eq 0 ]
    [[ "$output" == *".width"* ]]
    [[ "$output" == *".height"* ]]
    [[ "$output" == *'.[] | "\(.id)|\(.file_url)"'* ]]
}

@test "build_jq_dry_run_filter: Danbooru uses uploader_id and tag_string" {
    SERVER_TYPE="danbooru"
    run build_jq_dry_run_filter "false"
    [ "$status" -eq 0 ]
    [[ "$output" == *"uploader_id"* ]]
    [[ "$output" == *"tag_string"* ]]
    [[ "$output" == *"image_width"* ]]
    [[ "$output" == *"image_height"* ]]
}

@test "build_jq_dry_run_filter: Moebooru uses author and tags" {
    SERVER_TYPE="moebooru"
    run build_jq_dry_run_filter "false"
    [ "$status" -eq 0 ]
    [[ "$output" == *"author"* ]]
    [[ "$output" == *".tags"* ]]
    [[ "$output" == *".width"* ]]
    [[ "$output" == *".height"* ]]
}

# =============================================================================
# Danbooru rating validation tests
# =============================================================================

@test "cli: Danbooru 'g' rating is accepted" {
    SERVER_TYPE="danbooru"
    parse_cli_args -r g
    [ "$RATING" = "g" ]
}

@test "cli: uppercase 'G' rating is lowercased" {
    SERVER_TYPE="danbooru"
    parse_cli_args -r G
    [ "$RATING" = "g" ]
}

@test "cli: 's' rating still works" {
    run parse_cli_args -r s
    [ "$status" -eq 0 ]
    [ "$RATING" = "s" ]
}

@test "cli: invalid rating is rejected" {
    run parse_cli_args -r x
    [ "$status" -ne 0 ]
}

# =============================================================================
# Danbooru server flag tests
# =============================================================================

@test "cli: --server danbooru sets SERVER_TYPE" {
    parse_cli_args --server danbooru
    [ "$SERVER_TYPE" = "danbooru" ]
}

@test "cli: --server moebooru sets SERVER_TYPE" {
    parse_cli_args --server moebooru
    [ "$SERVER_TYPE" = "moebooru" ]
}

@test "cli: --server invalid value is rejected" {
    run parse_cli_args --server invalid
    [ "$status" -ne 0 ]
}

# =============================================================================
# Danbooru JSON filtering tests
# =============================================================================

@test "Danbooru posts JSON is filtered correctly" {
    SERVER_TYPE="danbooru"
    MAX_FILE_SIZE_BYTES=0
    MIN_FILE_SIZE_BYTES=0
    MAX_WIDTH_NUM=0
    MIN_WIDTH_NUM=0
    MAX_HEIGHT_NUM=0
    MIN_HEIGHT_NUM=0
    ASPECT_RATIO_JSON="[]"

    local json
    json=$(mktemp)
    cat > "$json" <<'EOF'
[
  {"id": 1, "file_url": "https://example.com/1.jpg", "file_size": 100000, "image_width": 1920, "image_height": 1080, "score": 50, "uploader_id": 1, "tag_string": "1girl solo"},
  {"id": 2, "file_url": "https://example.com/2.jpg", "file_size": 200000, "image_width": 2560, "image_height": 1440, "score": 100, "uploader_id": 2, "tag_string": "landscape scenery"}
]
EOF

    local result
    result=$(jq -r \
        --argjson max_size "$MAX_FILE_SIZE_BYTES" \
        --argjson min_size "$MIN_FILE_SIZE_BYTES" \
        --argjson max_width "$MAX_WIDTH_NUM" \
        --argjson min_width "$MIN_WIDTH_NUM" \
        --argjson max_height "$MAX_HEIGHT_NUM" \
        --argjson min_height "$MIN_HEIGHT_NUM" \
        --argjson aspect_ratio "$ASPECT_RATIO_JSON" \
        "$(build_jq_filter "false")" "$json")

    [[ "$result" == *"1|https://example.com/1.jpg"* ]]
    [[ "$result" == *"2|https://example.com/2.jpg"* ]]
    rm -f "$json"
}

@test "Danbooru posts JSON with dimension filters works" {
    SERVER_TYPE="danbooru"
    MAX_FILE_SIZE_BYTES=0
    MIN_FILE_SIZE_BYTES=0
    MAX_WIDTH_NUM=2000
    MIN_WIDTH_NUM=0
    MAX_HEIGHT_NUM=0
    MIN_HEIGHT_NUM=0
    ASPECT_RATIO_JSON="[]"

    local json
    json=$(mktemp)
    cat > "$json" <<'EOF'
[
  {"id": 1, "file_url": "https://example.com/1.jpg", "file_size": 100000, "image_width": 1920, "image_height": 1080, "score": 50, "uploader_id": 1, "tag_string": "1girl solo"},
  {"id": 2, "file_url": "https://example.com/2.jpg", "file_size": 200000, "image_width": 2560, "image_height": 1440, "score": 100, "uploader_id": 2, "tag_string": "landscape scenery"}
]
EOF

    local result
    result=$(jq -r \
        --argjson max_size "$MAX_FILE_SIZE_BYTES" \
        --argjson min_size "$MIN_FILE_SIZE_BYTES" \
        --argjson max_width "$MAX_WIDTH_NUM" \
        --argjson min_width "$MIN_WIDTH_NUM" \
        --argjson max_height "$MAX_HEIGHT_NUM" \
        --argjson min_height "$MIN_HEIGHT_NUM" \
        --argjson aspect_ratio "$ASPECT_RATIO_JSON" \
        "$(build_jq_filter "true")" "$json")

    # Only post 1 (1920 width) should match max_width=2000
    [[ "$result" == *"1|https://example.com/1.jpg"* ]]
    [[ "$result" != *"2|https://example.com/2.jpg"* ]]
    rm -f "$json"
}
