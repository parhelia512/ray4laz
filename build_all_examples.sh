#!/bin/bash
# Build all ray4laz examples
# Usage: ./build_all_examples.sh [category]
# Example: ./build_all_examples.sh core

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR"
EXAMPLES_DIR="$BASE/examples"
LOG_DIR="$BASE/build_log"
mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUCCESS=0
FAILED=0
SKIPPED=0

build_example() {
    local lpi_file="$1"
    local name=$(basename "$lpi_file" .lpi)
    
    echo -n "  Building: $name ... "
    
    if lazbuild "$lpi_file" --build-mode=Default > "$LOG_DIR/$name.log" 2>&1; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Determine which categories to build
if [ -n "$1" ]; then
    CATEGORIES="$1"
else
    CATEGORIES="core shapes textures models shaders audio text gui fmx"
fi

echo "=========================================="
echo "  Building ray4laz examples"
echo "=========================================="
echo ""

for category in $CATEGORIES; do
    if [ "$category" = "extras" ]; then
        continue
    fi
    echo "--- Category: $category ---"
    
    if [ ! -d "$EXAMPLES_DIR/$category" ]; then
        echo "  Category directory not found, skipping"
        continue
    fi
    
    for example_dir in "$EXAMPLES_DIR/$category"/*/; do
        [ -d "$example_dir" ] || continue
        
        example_name=$(basename "$example_dir")
        lpi_file=$(find "$example_dir" -maxdepth 1 -name "*.lpi" | head -1)
        
        if [ -z "$lpi_file" ]; then
            echo "  $example_name: No .lpi file found, skipping"
            ((SKIPPED++))
            continue
        fi
        
        if build_example "$lpi_file"; then
            ((SUCCESS++))
        else
            ((FAILED++))
        fi
    done
    echo ""
done

echo "=========================================="
echo "  Build Results"
echo "=========================================="
echo -e "  ${GREEN}Success: $SUCCESS${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo -e "  ${YELLOW}Skipped: $SKIPPED${NC}"
echo "  Total: $((SUCCESS + FAILED + SKIPPED))"
echo ""
echo "  Logs saved to: $LOG_DIR/"
echo "=========================================="
