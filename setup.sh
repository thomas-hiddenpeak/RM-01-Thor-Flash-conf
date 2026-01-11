#!/bin/bash
# ============================================
# RM01-Thor One-Click Setup Script
# 从 GitHub 克隆后一键安装到 Linux_for_Tegra
# ============================================
# 
# Usage (一键安装):
#   curl -fsSL https://raw.githubusercontent.com/thomas-hiddenpeak/RM-01-Thor-Flash-conf/main/setup.sh | bash -s /path/to/Linux_for_Tegra
#
# Or after git clone:
#   ./setup.sh /path/to/Linux_for_Tegra
#

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "============================================"
echo "RM01-Thor V1.0 CVB - One-Click Setup"
echo "============================================"
echo ""

# 获取 L4T_DIR
if [ -n "$1" ]; then
    L4T_DIR="$1"
elif [ -d "../kernel" ] && [ -d "../bootloader" ]; then
    # 如果在 Linux_for_Tegra/rm01-thor 目录下运行
    L4T_DIR="$(cd .. && pwd)"
else
    print_error "Usage: $0 <Linux_for_Tegra_path>"
    print_error "Example: $0 /home/user/nvidia/Linux_for_Tegra"
    exit 1
fi

# 验证 L4T_DIR
if [ ! -f "$L4T_DIR/flash.sh" ]; then
    print_error "Invalid Linux_for_Tegra path: $L4T_DIR"
    print_error "flash.sh not found"
    exit 1
fi

print_info "L4T Directory: $L4T_DIR"

# 获取脚本所在目录 (或当前目录)
if [ -f "$(dirname "$0")/rm01-thor.conf" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
elif [ -f "./rm01-thor.conf" ]; then
    PROJECT_DIR="$(pwd)"
else
    # 从 GitHub 下载
    print_info "Downloading RM01-Thor configuration from GitHub..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone --depth 1 https://github.com/thomas-hiddenpeak/RM-01-Thor-Flash-conf.git
    PROJECT_DIR="$TEMP_DIR/RM-01-Thor-Flash-conf"
fi

print_info "Project Directory: $PROJECT_DIR"
echo ""

# 检查必要文件
check_file() {
    if [ ! -f "$1" ]; then
        print_error "File not found: $1"
        exit 1
    fi
    print_info "  ✓ $(basename "$1")"
}

print_info "Checking source files..."
check_file "$PROJECT_DIR/rm01-thor.conf"
check_file "$PROJECT_DIR/dtb/tegra264-rm01-thor.dtb"
check_file "$PROJECT_DIR/bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts"
check_file "$PROJECT_DIR/tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml"
echo ""

# 安装文件
print_info "Installing files..."

cp -v "$PROJECT_DIR/rm01-thor.conf" "$L4T_DIR/"
cp -v "$PROJECT_DIR/dtb/tegra264-rm01-thor.dtb" "$L4T_DIR/kernel/dtb/"
cp -v "$PROJECT_DIR/bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts" "$L4T_DIR/bootloader/"
cp -v "$PROJECT_DIR/tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml" "$L4T_DIR/tools/kernel_flash/"

# 可选：安装 DTS 源文件
if [ -d "$L4T_DIR/source/hardware/nvidia/t264/nv-public/nv-platform" ] && [ -f "$PROJECT_DIR/dts/tegra264-rm01-thor.dts" ]; then
    print_info "Installing DTS source..."
    cp -v "$PROJECT_DIR/dts/tegra264-rm01-thor.dts" "$L4T_DIR/source/hardware/nvidia/t264/nv-public/nv-platform/"
fi

echo ""
echo "============================================"
print_info "Installation complete!"
echo "============================================"
echo ""
echo "To flash RM01-Thor:"
echo "  1. Connect device in recovery mode"
echo "  2. Run:"
echo "     cd $L4T_DIR"
echo "     sudo ./flash.sh rm01-thor nvme0n1p1"
echo ""
