#!/bin/bash
# ============================================
# RM01-Thor Install Script
# 将所有 RM01-Thor 专用文件安装到 Linux_for_Tegra 对应目录
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
L4T_DIR="$(dirname "$PROJECT_DIR")"

echo "============================================"
echo "RM01-Thor Install Script"
echo "============================================"
echo ""
echo "Project: $PROJECT_DIR"
echo "L4T:     $L4T_DIR"
echo ""

# 检查必要文件
check_file() {
    if [ ! -f "$1" ]; then
        echo "ERROR: File not found: $1"
        exit 1
    fi
    echo "  ✓ $(basename "$1")"
}

echo "[1/5] Checking source files..."
check_file "$PROJECT_DIR/rm01-thor.conf"
check_file "$PROJECT_DIR/dts/tegra264-rm01-thor.dts"
check_file "$PROJECT_DIR/dtb/tegra264-rm01-thor.dtb"
check_file "$PROJECT_DIR/bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts"
check_file "$PROJECT_DIR/tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml"
echo ""

echo "[2/5] Installing rm01-thor.conf..."
cp -v "$PROJECT_DIR/rm01-thor.conf" "$L4T_DIR/"

echo "[3/5] Installing DTB to kernel/dtb/..."
cp -v "$PROJECT_DIR/dtb/tegra264-rm01-thor.dtb" "$L4T_DIR/kernel/dtb/"

echo "[4/5] Installing MB2 BCT to bootloader/..."
cp -v "$PROJECT_DIR/bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts" "$L4T_DIR/bootloader/"

echo "[5/6] Installing partition layout to tools/kernel_flash/..."
cp -v "$PROJECT_DIR/tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml" "$L4T_DIR/tools/kernel_flash/"

echo "[6/6] Installing optimized flash scripts..."
# 备份原始脚本
if [ -f "$L4T_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh" ] && \
   [ ! -f "$L4T_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh.orig" ]; then
    cp "$L4T_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh" \
       "$L4T_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh.orig"
    echo "  Original script backed up to l4t_flash_from_kernel.sh.orig"
fi
cp -v "$PROJECT_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh" "$L4T_DIR/tools/kernel_flash/"
# 同步到 images 目录
if [ -d "$L4T_DIR/tools/kernel_flash/images" ]; then
    cp -v "$PROJECT_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh" "$L4T_DIR/tools/kernel_flash/images/"
fi

# 可选：同步 DTS 源文件
if [ -d "$L4T_DIR/source/hardware/nvidia/t264/nv-public/nv-platform" ]; then
    echo ""
    echo "[Optional] Installing DTS source..."
    cp -v "$PROJECT_DIR/dts/tegra264-rm01-thor.dts" "$L4T_DIR/source/hardware/nvidia/t264/nv-public/nv-platform/"
fi

echo ""
echo "============================================"
echo "Installation complete!"
echo "============================================"
echo ""
echo "Installed files:"
echo "  - rm01-thor.conf"
echo "  - kernel/dtb/tegra264-rm01-thor.dtb"
echo "  - bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts"
echo "  - tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml"
echo "  - tools/kernel_flash/l4t_flash_from_kernel.sh (optimized)"
echo ""
echo "Performance optimization applied:"
echo "  - APP partition write: ~4.5 MB/s -> ~750 MB/s"
echo "  - ESP partition write: ~46 MB/s -> ~200 MB/s"
echo ""
echo "To flash:"
echo "  cd $L4T_DIR"
echo "  sudo ./flash.sh rm01-thor nvme0n1p1"
echo ""
echo "Or use direct flash script:"
echo "  sudo ./rm01-thor/scripts/flash.sh --external-device sda nvme0n1p1"
