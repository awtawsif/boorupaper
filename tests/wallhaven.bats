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

@test "detect_server_type: detects wallhaven from URL" {
    BASE_URL="https://wallhaven.cc"
    SERVER_TYPE=""
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "wallhaven" ]
}

@test "detect_server_type: explicit SERVER_TYPE wallhaven overrides URL" {
    BASE_URL="https://konachan.net"
    SERVER_TYPE="wallhaven"
    run detect_server_type
    [ "$status" -eq 0 ]
    [ "$output" = "wallhaven" ]
}

# =============================================================================
# get_post_endpoint tests
# =============================================================================

@test "get_post_endpoint: returns empty for wallhaven" {
    SERVER_TYPE="wallhaven"
    run get_post_endpoint
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# =============================================================================
# get_site_name tests
# =============================================================================

@test "get_site_name: returns wallhaven for wallhaven.cc" {
    BASE_URL="https://wallhaven.cc"
    run get_site_name
    [ "$status" -eq 0 ]
    [ "$output" = "wallhaven" ]
}

# =============================================================================
# CLI validation tests
# =============================================================================

@test "cli: --server wallhaven sets SERVER_TYPE and BASE_URL" {
    parse_cli_args --server wallhaven
    [ "$SERVER_TYPE" = "wallhaven" ]
    [ "$BASE_URL" = "https://wallhaven.cc" ]
}

# =============================================================================
# Wallhaven jq filter tests
# =============================================================================

@test "build_jq_filter: Wallhaven without filters uses .path" {
    SERVER_TYPE="wallhaven"
    run build_jq_filter "false"
    [ "$status" -eq 0 ]
    [[ "$output" == *'.data // .'* ]]
    [[ "$output" == *'.[] | "\(.id)|\(.path)"'* ]]
}

@test "build_jq_filter: Wallhaven with filters uses dimension_x/dimension_y" {
    SERVER_TYPE="wallhaven"
    run build_jq_filter "true"
    [ "$status" -eq 0 ]
    [[ "$output" == *".dimension_x"* ]]
    [[ "$output" == *".dimension_y"* ]]
    [[ "$output" == *'.[] | "\(.id)|\(.path)"'* ]]
}

@test "build_jq_dry_run_filter: Wallhaven uses views and favorites" {
    SERVER_TYPE="wallhaven"
    run build_jq_dry_run_filter "false"
    [ "$status" -eq 0 ]
    [[ "$output" == *".views"* ]]
    [[ "$output" == *".favorites"* ]]
    [[ "$output" == *".dimension_x"* ]]
    [[ "$output" == *".dimension_y"* ]]
}

# =============================================================================
# Wallhaven JSON filtering tests
# =============================================================================

@test "Wallhaven search JSON is filtered correctly" {
    SERVER_TYPE="wallhaven"
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
{
  "data": [
    {"id": "abc123", "path": "https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg", "file_size": 100000, "dimension_x": 1920, "dimension_y": 1080, "views": 50, "favorites": 10},
    {"id": "def456", "path": "https://w.wallhaven.cc/full/de/wallhaven-def456.jpg", "file_size": 200000, "dimension_x": 2560, "dimension_y": 1440, "views": 100, "favorites": 20}
  ]
}
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

    [[ "$result" == *"abc123|https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg"* ]]
    [[ "$result" == *"def456|https://w.wallhaven.cc/full/de/wallhaven-def456.jpg"* ]]
    rm -f "$json"
}

@test "Wallhaven search JSON with dimension filters works" {
    SERVER_TYPE="wallhaven"
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
{
  "data": [
    {"id": "abc123", "path": "https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg", "file_size": 100000, "dimension_x": 1920, "dimension_y": 1080},
    {"id": "def456", "path": "https://w.wallhaven.cc/full/de/wallhaven-def456.jpg", "file_size": 200000, "dimension_x": 2560, "dimension_y": 1440}
  ]
}
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

    # Only abc123 (1920 width) should match max_width=2000
    [[ "$result" == *"abc123|https://w.wallhaven.cc/full/ab/wallhaven-abc123.jpg"* ]]
    [[ "$result" != *"def456"* ]]
    rm -f "$json"
}
