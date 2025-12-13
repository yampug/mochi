#!/usr/bin/env bash
#
# Build and copy libsorbet from the sorbet repository
#
# This script builds the libsorbet C API library and copies it to
# the mochi fragments/libs directory for use by the compiler.
#
# Usage:
#   ./scripts/sorbet_lib_build.bash [options]
#
# Options:
#   --platform <macos|linux|all>  Platform to build for (default: auto-detect)
#   --rebuild                     Force rebuild even if library exists
#   --help                        Show this help message
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PLATFORM="auto"
FORCE_REBUILD=false

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOCHI_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SORBET_ROOT="$(cd "$MOCHI_ROOT/../sorbet" && pwd)"
SORBET_LIB_DIR="$SORBET_ROOT/lib"
SORBET_DIST_DIR="$SORBET_ROOT/dist"
MOCHI_LIBS_DIR="$MOCHI_ROOT/fragments/libs"

# Functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

show_help() {
    sed -n '2,/^$/p' "$0" | grep "^#" | sed 's/^# *//' | sed 's/^#//'
}

detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            print_error "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
}

check_prerequisites() {
    local platform=$1

    # Check if sorbet directory exists
    if [ ! -d "$SORBET_ROOT" ]; then
        print_error "Sorbet repository not found at: $SORBET_ROOT"
        print_info "Expected to find sorbet repository at ../sorbet relative to mochi"
        exit 1
    fi

    # Check if lib directory exists
    if [ ! -d "$SORBET_LIB_DIR" ]; then
        print_error "Sorbet lib directory not found at: $SORBET_LIB_DIR"
        exit 1
    fi

    # Check for task (go-task)
    if ! command -v task &> /dev/null; then
        print_error "Task (go-task) is not installed"
        print_info "Install with: brew install go-task/tap/go-task"
        exit 1
    fi

    # Platform-specific checks
    if [ "$platform" = "linux" ]; then
        if ! command -v docker &> /dev/null; then
            print_error "Docker is required for Linux builds but is not installed"
            exit 1
        fi
    fi
}

build_library() {
    local platform=$1

    print_info "Building libsorbet for $platform..."

    cd "$SORBET_LIB_DIR"

    case "$platform" in
        macos)
            if [ -f "$SORBET_DIST_DIR/macos/libsorbet.dylib" ] && [ "$FORCE_REBUILD" = false ]; then
                print_info "Library already exists at $SORBET_DIST_DIR/macos/libsorbet.dylib"
                print_info "Use --rebuild to force rebuild"
            else
                task build:macos
            fi
            ;;
        linux)
            if [ -f "$SORBET_DIST_DIR/linux/libsorbet.so" ] && [ "$FORCE_REBUILD" = false ]; then
                print_info "Library already exists at $SORBET_DIST_DIR/linux/libsorbet.so"
                print_info "Use --rebuild to force rebuild"
            else
                task build:linux
            fi
            ;;
        *)
            print_error "Unknown platform: $platform"
            exit 1
            ;;
    esac

    print_success "Build completed for $platform"
}

copy_library() {
    local platform=$1

    print_info "Copying library to $MOCHI_LIBS_DIR..."

    # Create libs directory if it doesn't exist
    mkdir -p "$MOCHI_LIBS_DIR"

    case "$platform" in
        macos)
            local src="$SORBET_DIST_DIR/macos/libsorbet.dylib"
            local dst="$MOCHI_LIBS_DIR/libsorbet.dylib"

            if [ ! -f "$src" ]; then
                print_error "Source library not found: $src"
                exit 1
            fi

            cp -f "$src" "$dst"
            print_success "Copied: $dst"

            # Fix the library install name to use absolute path
            install_name_tool -id "$dst" "$dst"
            print_info "Fixed library install name"

            # Show library info
            local size=$(du -h "$dst" | cut -f1)
            print_info "Library size: $size"
            ;;

        linux)
            local src="$SORBET_DIST_DIR/linux/libsorbet.so"
            local dst="$MOCHI_LIBS_DIR/libsorbet.so"

            if [ ! -f "$src" ]; then
                print_error "Source library not found: $src"
                exit 1
            fi

            cp -f "$src" "$dst"
            print_success "Copied: $dst"

            # Show library info
            local size=$(du -h "$dst" | cut -f1)
            print_info "Library size: $size"
            ;;

        *)
            print_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Auto-detect platform if not specified
if [ "$PLATFORM" = "auto" ]; then
    PLATFORM=$(detect_platform)
    print_info "Auto-detected platform: $PLATFORM"
fi

# Main execution
main() {
    print_info "Sorbet Library Build Script"
    print_info "============================"
    print_info ""
    print_info "Mochi root: $MOCHI_ROOT"
    print_info "Sorbet root: $SORBET_ROOT"
    print_info "Target platform: $PLATFORM"
    print_info ""

    # Handle "all" platform
    if [ "$PLATFORM" = "all" ]; then
        for plat in macos linux; do
            print_info "Processing platform: $plat"
            check_prerequisites "$plat"
            build_library "$plat"
            copy_library "$plat"
            print_info ""
        done
    else
        check_prerequisites "$PLATFORM"
        build_library "$PLATFORM"
        copy_library "$PLATFORM"
    fi

    print_success "All done!"
    print_info ""
    print_info "To use the library in Crystal code:"
    print_info "  require \"./compiler/src/sorbet/sorbet\""
    print_info ""
    print_info "Make sure to link with the library:"
    print_info "  crystal build -L./fragments/libs yourfile.cr"
}

main
