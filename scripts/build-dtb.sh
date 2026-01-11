#!/bin/bash
# ============================================
# RM01-Thor DTB Build Script
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
L4T_DIR="$(dirname "$PROJECT_DIR")"
DTS_SOURCE_DIR="$L4T_DIR/source/hardware/nvidia/t264/nv-public/nv-platform"
DTS_INCLUDE_DIR="$L4T_DIR/source/hardware/nvidia/t264/nv-public"

DTS_FILE="tegra264-rm01-thor.dts"
DTB_FILE="tegra264-rm01-thor.dtb"

echo "============================================"
echo "RM01-Thor DTB Build Script"
echo "============================================"
echo ""

# Check if DTS exists
if [ ! -f "$DTS_SOURCE_DIR/$DTS_FILE" ]; then
    echo "ERROR: DTS file not found: $DTS_SOURCE_DIR/$DTS_FILE"
    exit 1
fi

cd "$DTS_SOURCE_DIR"

echo "[1/3] Preprocessing DTS..."
cpp -nostdinc \
    -I .. \
    -I ../include/kernel-t264 \
    -I ../../../tegra/nv-public/include/kernel \
    -I ../../../tegra/nv-public/include/nvidia-oot \
    -undef -x assembler-with-cpp \
    "$DTS_FILE" "${DTS_FILE}.preprocessed"

echo "[2/3] Compiling DTB..."
dtc -I dts -O dtb -@ \
    -W no-unit_address_vs_reg \
    -W no-simple_bus_reg \
    -o "$DTB_FILE" "${DTS_FILE}.preprocessed"

echo "[3/3] Copying files..."
# Copy to kernel/dtb for flashing
cp "$DTB_FILE" "$L4T_DIR/kernel/dtb/"
# Copy to project directory for backup
cp "$DTB_FILE" "$PROJECT_DIR/dtb/"
cp "$DTS_FILE" "$PROJECT_DIR/dts/"

# Cleanup
rm -f "${DTS_FILE}.preprocessed"

echo ""
echo "============================================"
echo "Build complete!"
echo "============================================"
echo "DTB: $L4T_DIR/kernel/dtb/$DTB_FILE"
echo "Backup: $PROJECT_DIR/dtb/$DTB_FILE"
echo ""
echo "To flash, run: ./flash.sh"
