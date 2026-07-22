# Boorupaper

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-1.5.0-orange.svg)](https://github.com/awtawsif/boorupaper)

A wallpaper rotator for Wayland and X11 that fetches high-quality images from [Konachan.net](https://konachan.net) (Moebooru), [Danbooru](https://danbooru.donmai.us), and [Wallhaven](https://wallhaven.cc), with automatic server detection.

## Features

- **Multi-site support** — Konachan.net (Moebooru), Danbooru, and Wallhaven, auto-detected from config
- **Smart filtering** — tags, rating, score, resolution, aspect ratio, file size
- **Auto-detection** — finds your display server and available wallpaper tools
- **Background preloading** — instant wallpaper transitions with a per-rating cache
- **Force-set mode** — skip cache and immediately download/apply a new wallpaper
- **Animated wallpapers** — GIF and WebM support with proper frame handling
- **Favorites system** — save and rotate from a personal collection
- **Dry-run mode** — preview results before downloading
- **Notifications & logging** — optional progress toasts and detailed logs

## Quick Start

```bash
git clone https://github.com/awtawsif/boorupaper.git
cd boorupaper
chmod +x boorupaper.sh
./boorupaper.sh --init-interactive   # guided setup wizard
./boorupaper.sh                      # set a random wallpaper
```

The interactive wizard auto-detects your display server, available wallpaper
tools, and writes a personalised config to `~/.config/boorupaper/boorupaper.conf`.

## Requirements

| Tool | Purpose |
|------|---------|
| `bash`, `curl`, `jq`, `xmllint`, `flock` | Core dependencies |
| One wallpaper tool | See table below |

### Supported Wallpaper Tools

| Wayland | X11 |
|---------|-----|
| awww (recommended), mpvpaper, swaybg, hyprpaper | feh (recommended), mpvpaper, nitrogen, fbsetbg, xwallpaper |

## Usage

### Common Commands

```bash
# Filter by tags, rating, and score
./boorupaper.sh --tags "landscape scenic" --rating s --min-score 20

# Animated wallpapers
./boorupaper.sh --format gif
./boorupaper.sh --animated-only

# Preview without downloading
./boorupaper.sh --dry-run --tags "touhou" --limit 10

# Favorites
./boorupaper.sh --fav              # save current wallpaper
./boorupaper.sh --list-favs        # list saved favorites
./boorupaper.sh --from-favs        # random wallpaper from favorites

# Discover content
./boorupaper.sh --discover-tags    # popular tags
./boorupaper.sh --discover-artists # popular artists
./boorupaper.sh --list-pools       # available pools

# Maintenance
./boorupaper.sh --clean-cache      # clear preload cache
./boorupaper.sh --help             # full option list
./boorupaper.sh --version          # show version
```

### Full CLI Reference

Run `./boorupaper.sh --help` for the complete option list, or see the table below:

<details>
<summary>Click to expand</summary>

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--tags` | `-t` | Space-separated tags | None |
| `--limit` | `-l` | Posts to query | 50 |
| `--page` | `-p` | Page, `random`, or `MIN-MAX` | 1 |
| `--rating` | `-r` | `s` / `q` / `e` / `g` (Danbooru only) | `s` |
| `--order` | `-o` | `random` / `score` / `date` | `random` |
| `--max-file-size` | `-s` | e.g. `2MB`, `0` to disable | `2MB` |
| `--min-file-size` | `-z` | e.g. `500KB` | disabled |
| `--min-width` | | Minimum width (px) | disabled |
| `--max-width` | | Maximum width (px) | disabled |
| `--min-height` | | Minimum height (px) | disabled |
| `--max-height` | | Maximum height (px) | disabled |
| `--aspect-ratio` | | e.g. `16:9`, `21:9` | disabled |
| `--min-score` | `-m` | Score threshold | disabled |
| `--artist` | `-a` | Filter by artist | None |
| `--pool` | `-P` | Pool ID | None |
| `--format` | `-f` | `jpg` / `gif` / `webm` | `jpg` |
| `--animated-only` | | Search animated only | false |
| `--random-tags` | `-R` | Pick N random tags from config list | 0 |
| `--dry-run` | `-d` | Preview without downloading | false |
| `--discover-tags` | `-D` | Show popular tags | false |
| `--discover-artists` | `-A` | Show popular artists | false |
| `--export-tags` | `-E` | Save discovered tags to file | false |
| `--list-pools` | `-L` | List pools | false |
| `--search-pools` | `-S` | Search pools by name | None |
| `--fav` | | Save current wallpaper to favorites | false |
| `--list-favs` | | List favorites | false |
| `--from-favs` | | Random from favorites | false |
| `--clean-cache` | `-cc` | Clean preload cache | false |
| `--clean-force` | `-cf` | Force clean (no prompt) | false |
| `--init-interactive` | `-ii` | Interactive init wizard | false |
| `--server` | | Server type: `moebooru` / `danbooru` / `wallhaven` (auto-detected) | auto |
| `--version` | `-v` | Show version | |
| `--help` | `-h` | Show help | |

</details>

### Examples

```bash
# Resolution filtering
./boorupaper.sh --min-width 1920 --min-height 1080 --aspect-ratio "16:9,21:9"

# Force immediate download/set (skip cache)
./boorupaper.sh --force-set

# High-quality originals
./boorupaper.sh --tags "original" --rating s --min-score 50 --min-file-size "500KB"

# From a curated pool
./boorupaper.sh --pool 5678

# Random tag combinations
# (configure RANDOM_TAGS_LIST in config, then:)
./boorupaper.sh --random-tags 3

# Danbooru-specific
./boorupaper.sh --server danbooru --tags "landscape scenic" --rating g
./boorupaper.sh --server danbooru --tags "1girl solo" --min-score 20 --order score

# Wallhaven-specific (requires API key for non-safe ratings)
./boorupaper.sh --server wallhaven --tags "landscape" --rating s
./boorupaper.sh --server wallhaven --tags "anime" --min-score 50 --order score
```

### Scheduled Rotation

```bash
# Cron — every hour
0 * * * * /path/to/boorupaper.sh --tags "landscape scenic" --rating s
```

## Configuration

Configuration lives in `~/.config/boorupaper/boorupaper.conf` (created by `--init-interactive`).
All defaults are built into the script — the config file is only needed for overrides.
For a full reference, see `man/boorupaper.conf.5` (or `man -l man/boorupaper.conf.5`).

```bash
# Minimal custom config example
TAGS="landscape scenic"
RATING="s"
MAX_FILE_SIZE="5MB"
MIN_SCORE="15"
```

### Key Options

| Category | Options |
|----------|---------|
| Server | `BASE_URL`, `SERVER_TYPE`, `DANBOORU_LOGIN`, `DANBOORU_API_KEY`, `WALLHAVEN_API_KEY`, `USER_AGENT` |
| Search | `TAGS`, `LIMIT`, `RATING`, `ORDER`, `PAGE` |
| Filters | `MIN_SCORE`, `ARTIST`, `POOL_ID`, resolution & size limits |
| Animated | `PREFERRED_FORMAT`, `ANIMATED_ONLY` |
| Cache | `PRELOAD_COUNT`, `MAX_PRELOAD_CACHE` |
| Favorites | `FAVORITES_DIR` |
| Notifications | `ENABLE_NOTIFICATIONS`, `NOTIFY_TIMEOUT`, `NOTIFY_PRELOAD` |
| Logging | `ENABLE_LOGGING`, `LOG_LEVEL`, `LOG_ROTATION` |
| Custom command | `WALLPAPER_COMMAND` (use `{IMAGE}` as placeholder) |

For the full list with defaults and descriptions, see [`boorupaper.conf`](boorupaper.conf).

### Other Servers

Boorupaper supports Moebooru-based sites (Konachan, Yande.re, etc.), Danbooru, and Wallhaven.
Server type is auto-detected from `BASE_URL`, or set explicitly:

```bash
# Use a different Moebooru instance
BASE_URL="https://yoursite.example.com"

# Or use Danbooru
BASE_URL="https://danbooru.donmai.us"
SERVER_TYPE="danbooru"

# Or use Wallhaven
BASE_URL="https://wallhaven.cc"
SERVER_TYPE="wallhaven"

# Or pass via CLI
./boorupaper.sh --server danbooru --tags "landscape"
```

#### Wallhaven

Wallhaven uses a single API endpoint for all content ratings. To access sketchy or
explicit wallpapers, you need an API key from [wallhaven.cc/settings/account](https://wallhaven.cc/settings/account):

```bash
WALLHAVEN_API_KEY="your_api_key"
```

Without an API key, only safe wallpapers are returned.

> **Note:** Wallhaven returns a maximum of 24 results per page. The `--limit` flag
> is capped server-side; use `--page` to paginate through results.

For Danbooru, you can optionally set authentication credentials in your config
(required for some restricted content):

```bash
DANBOORU_LOGIN="your_username"
DANBOORU_API_KEY="your_api_key"
```

> **Note:** Danbooru limits anonymous users to 3 tags per query. Boorupaper
> automatically manages this by fitting as many filters as possible into the
> query and applying the rest client-side.

## Project Structure

```
boorupaper/
├── boorupaper.sh              # Entry point
├── lib/
│   ├── constants.sh          # Globals, defaults, colors, tool commands
│   ├── config.sh             # Config loading
│   ├── helpers.sh            # Size/aspect/page parsers, jq filter builder
│   ├── logging.sh            # Log functions & rotation
│   ├── formats.sh            # Format detection helpers
│   ├── display.sh            # Server detection & wallpaper setting
│   ├── download.sh           # API queries & image download
│   ├── cache.sh              # Preload management
│   ├── discovery.sh          # Tag/artist/pool discovery
│   ├── favorites.sh          # Favorites CRUD
│   ├── init.sh               # Interactive init wizard
│   ├── cli.sh                # Argument parsing & help
│   └── notifications.sh      # notify-send wrappers
├── man/
│   └── boorupaper.conf.5      # Man page for config options
├── docs/
│   ├── danbooru-api.md        # Danbooru API reference
│   └── wallhaven-api-v1-docs.md # Wallhaven API reference
├── tests/                    # Bats test suite
└── api_doc.md                # Moebooru API reference
```

## Development

```bash
# Lint
shellcheck boorupaper.sh lib/*.sh

# Syntax check
bash -n boorupaper.sh && for f in lib/*.sh; do bash -n "$f"; done

# Run tests (requires bats-core)
./run_tests.sh

# Dry-run test
./boorupaper.sh --dry-run --tags "test" --limit 1
```

### Code Style

- 4-space indentation, no tabs
- `UPPERCASE` globals, `lowercase` locals (with `local`)
- `snake_case` functions
- `[[ ]]` for conditionals, always quote variables
- Errors to stderr

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No wallpaper tool found | Install one: `awww`/`feh` (recommended) |
| No suitable image found | Relax filters, increase `--limit`, try different tags |
| Download fails | Check internet, verify the target site is reachable |
| Danbooru: "cannot search for more than N tags" | Reduce `--tags` to 2 or fewer; Boorupaper auto-manages the tag budget |
| Danbooru: "database timed out" | Danbooru server overload; retry or use fewer metatags (`--min-score`, `--order score`) |
| Wallhaven: 401 Unauthorized | Set `WALLHAVEN_API_KEY` in config (required for sketchy/explicit ratings) |
| Wallhaven: no results returned | Try broader tags, or check that `--rating s` matches available content |
| Wrong tool used | Re-run `--init-interactive` or set `WALLPAPER_COMMAND` manually |
| GIF artifacts | Ensure `awww-daemon` is running (auto-started) |

For detailed debugging, enable logging in your config or run with `ENABLE_LOGGING="true" LOG_LEVEL="verbose"`.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the code style above
4. Test with `--dry-run` and actual downloads
5. Submit a PR

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

- [Konachan.net](https://konachan.net) for the Moebooru API
- [Danbooru](https://danbooru.donmai.us) for the Danbooru API
- [Wallhaven](https://wallhaven.cc) for the Wallhaven API
- Developers of awww, swaybg, hyprpaper, feh, nitrogen, mpvpaper, and all supported tools
