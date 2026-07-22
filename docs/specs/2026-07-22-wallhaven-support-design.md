# Wallhaven Support — Design Spec

**Date:** 2026-07-22
**Status:** Approved

## Summary

Add Wallhaven (wallhaven.cc) as a third supported server type alongside Moebooru and Danbooru. Wallhaven has a JSON API at `/api/v1/` with different field names and search parameters. Also add a `WALLHAVEN_API_KEY` config variable for user-provided API keys.

## Changes

### 1. Server Type Detection (`lib/constants.sh`)

- `detect_server_type()`: add `*wallhaven*` case returning `"wallhaven"`
- `get_post_endpoint()`: return empty string for wallhaven (uses `/api/v1/search` directly)
- `get_site_name()`: add `*wallhaven.cc` case returning `"wallhaven"`
- New global: `WALLHAVEN_API_KEY="${WALLHAVEN_API_KEY:-}"`

### 2. Download Function (`lib/download.sh`)

New wallhaven branch in `download_wallpaper()`:

- **API URL**: `${BASE_URL}/api/v1/search?apikey=${WALLHAVEN_API_KEY}&q=${tags}&categories=${categories}&purity=${purity}&sorting=${sorting}&page=${page}`
- **Rating → purity mapping**: `s` → `100` (sfw only), `q` → `110` (sfw+sketchy), `e` → `111` (all)
- **Categories**: default `110` (general+anime, no people), configurable via `CATEGORIES` config var
- **Tags**: space-separated in `q` param (no encoding needed)
- **Limit**: Wallhaven returns 24/page max; LIMIT capped to 24, pagination adjusts
- **Random**: `sorting=random` is native, no random page hack
- **Auth**: pass `X-API-Key` header or `apikey` query param
- **No `-g` flag needed** (no brackets in wallhaven URLs)

### 3. jq Filters (`lib/helpers.sh`)

Wallhaven branch in `build_jq_filter()` and `build_jq_dry_run_filter()`:

- Wallhaven fields: `.id`, `.path` (full image URL), `.dimension_x`, `.dimension_y`, `.file_size`
- `build_jq_filter`: outputs `"\(.id)|\(.path)"`
- Dimension/size filters use `.dimension_x`, `.dimension_y`, `.file_size`
- Dry-run: id, views, favorites, dimension_x, dimension_y, file_size

### 4. Config (`lib/config.sh`)

- No structural changes; `WALLHAVEN_API_KEY` loaded via existing `source "$CONFIG_FILE"` mechanism

### 5. CLI (`lib/cli.sh`)

- `--server` accepts `wallhaven` as valid value alongside `moebooru` and `danbooru`
- When `--server wallhaven`, set `BASE_URL` to `https://wallhaven.cc`

### 6. Init Wizard (`lib/init.sh`)

- Add option 3: "Wallhaven" in server selection
- Prompt for `WALLHAVEN_API_KEY` when Wallhaven selected

### 7. Discovery (`lib/discovery.sh`)

- `discover_tags()`: Wallhaven has no standalone tag listing API; show message that Wallhaven doesn't support tag discovery
- `discover_artists()`: not supported; show message
- `list_pools()`: not supported; show message

### 8. Tests (`tests/wallhaven.bats`)

- Server detection for wallhaven.cc URL
- `--server wallhaven` CLI flag
- Purity mapping (rating s/q/e → purity 100/110/111)
- jq filter output format for wallhaven
- Dry-run filter field names

## Files Modified

| File | Change |
|---|---|
| `lib/constants.sh` | Add wallhaven detection, API key var, site name |
| `lib/download.sh` | Add wallhaven branch |
| `lib/helpers.sh` | Add wallhaven jq filter branches |
| `lib/cli.sh` | Add `wallhaven` to `--server` valid values |
| `lib/init.sh` | Add Wallhaven option in wizard |
| `lib/discovery.sh` | Add wallhaven branch with graceful messages |

## New Files

| File | Purpose |
|---|---|
| `tests/wallhaven.bats` | Unit tests for wallhaven support |
