# Boorupaper

Boorupaper is a modular Bash-based wallpaper rotator designed for Wayland and X11 display servers. It fetches high-quality images from Moebooru-based sites (defaulting to [Konachan.net](https://konachan.net)) and applies them using various backend tools.

## Core Technologies
- **Language:** Bash (>= 4.0 recommended)
- **Dependencies:** `curl`, `jq`, `xmllint`, `flock`
- **Supported Backends:** 
    - **Wayland:** `awww` (recommended), `mpvpaper`, `swaybg`, `hyprpaper`
    - **X11:** `feh` (recommended), `mpvpaper`, `nitrogen`, `fbsetbg`, `xwallpaper`

## Project Architecture
The project follows a modular library-based architecture to maintain clean separation of concerns.

- `boorupaper.sh`: The main entry point. It handles bootstrapping, sources modules, and coordinates the execution flow.
- `lib/`: Contains the core logic divided into functional modules:
    - `constants.sh`: Global constants, default values, and ANSI color definitions.
    - `config.sh`: Logic for loading and merging user configurations.
    - `cli.sh`: Argument parsing and help documentation.
    - `display.sh`: Environment detection (Wayland/X11) and wallpaper setting logic.
    - `download.sh`: API interaction and image retrieval.
    - `cache.sh`: Management of the wallpaper preload cache. Supports `--force-set` to bypass.
    - `helpers.sh`: Utility functions for unit conversion, aspect ratio parsing (supports multiple ratios), and data filtering.
    - `logging.sh`: File-based logging and rotation.
    - `notifications.sh`: Desktop notification wrappers.
    - `formats.sh`: Image/Video format detection.
    - `favorites.sh`: Management of user-saved favorite wallpapers.
    - `init.sh`: Interactive setup wizard for first-time configuration.
    - `discovery.sh`: Tools for exploring tags, artists, and pools.

## Development Workflow

### Building and Running
As a shell script, no compilation is required.
- **Run:** `./boorupaper.sh [options]`
- **Setup:** `./boorupaper.sh --init-interactive` (Creates `~/.config/boorupaper/boorupaper.conf`)

### Testing
Tests are written using the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core).
- **Run all tests:** `./run_tests.sh`
- **Linting:** `shellcheck boorupaper.sh lib/*.sh`
- **Syntax Check:** `bash -n boorupaper.sh && for f in lib/*.sh; do bash -n "$f"; done`

### Coding Conventions
- **Indentation:** 4-space indentation (no tabs).
- **Naming:** 
    - `UPPERCASE` for global variables.
    - `lowercase` for local variables (always use the `local` keyword).
    - `snake_case` for function names.
- **Conditionals:** Prefer `[[ ... ]]` over `[ ... ]`.
- **Variables:** Always quote variables to prevent word splitting and globbing.
- **Error Handling:** Direct error messages to `stderr`.

## Key Files
- `boorupaper.sh`: Main script.
- `api_doc.md`: Reference for the Moebooru API used by the project.
- `man/boorupaper.conf.5`: Documentation for configuration options.
- `lib/constants.sh`: The source of truth for default settings.
