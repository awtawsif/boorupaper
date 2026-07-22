# Wallhaven Support — Implementation Plan

## Goal
Add Wallhaven as a third supported server type with full search, filtering, and API key support.

## Tasks

- [ ] Task 1: **`lib/constants.sh` — Add wallhaven server type** → Add `"wallhaven"` case to `detect_server_type()`, `get_post_endpoint()`, `get_site_name()`, and new `WALLHAVEN_API_KEY` global. → Verify: `bash -n lib/constants.sh`

- [ ] Task 2: **`lib/cli.sh` — Add `wallhaven` to `--server` flag** → Update `--server` validation to accept `wallhaven`, set `BASE_URL="https://wallhaven.cc"`. → Verify: `bash -n lib/cli.sh`

- [ ] Task 3: **`lib/helpers.sh` — Add wallhaven jq filter branches** → Add wallhaven case to `build_jq_filter()` and `build_jq_dry_run_filter()` using `.path`, `.dimension_x`, `.dimension_y`, `.file_size`. → Verify: `bash -n lib/helpers.sh`

- [ ] Task 4: **`lib/download.sh` — Add wallhaven download branch** → Add wallhaven case in `download_wallpaper()`: build search URL with purity mapping, tag encoding, API key header, limit capping to 24. → Verify: `bash -n lib/download.sh`

- [ ] Task 5: **`lib/discovery.sh` — Add wallhaven discovery messages** → Add wallhaven branch to `discover_tags()`, `discover_artists()`, `list_pools()` showing "not supported" messages. → Verify: `bash -n lib/discovery.sh`

- [ ] Task 6: **`lib/init.sh` — Add Wallhaven to init wizard** → Add option 3 in server selection, prompt for `WALLHAVEN_API_KEY`. → Verify: `bash -n lib/init.sh`

- [ ] Task 7: **`tests/wallhaven.bats` — Add wallhaven unit tests** → Tests for server detection, purity mapping, jq filters, CLI validation. → Verify: `bats tests/wallhaven.bats`

- [ ] Task 8: **Run full verification** → Run `shellcheck boorupaper.sh lib/*.sh`, `bash -n` on all files, and `bats tests/`. → Verify: all pass

## Done When
- `--server wallhaven` works end-to-end
- Wallhaven API searches return and filter results correctly
- Rating maps to purity (s→100, q→110, e→111)
- API key config loads from `boorupaper.conf`
- All tests pass
