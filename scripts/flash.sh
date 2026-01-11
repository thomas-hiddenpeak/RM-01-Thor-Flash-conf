#!/bin/bash
# ============================================
# RM01-Thor Direct Flash Script
# 使用优化的烧录脚本直接刷机
# ============================================
# 
# 用法:
#   sudo ./flash.sh [--external-device <device>] [target]
#
# 示例:
#   sudo ./flash.sh                      # 刷到 NVMe (默认)
#   sudo ./flash.sh --external-device sda nvme0n1p1  # 刷到外部设备
#
# 性能优化:
#   - APP 分区: ~4.5 MB/s -> ~750 MB/s
#   - ESP 分区: ~46 MB/s -> ~200 MB/s
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
L4T_DIR="$(dirname "$PROJECT_DIR")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root: sudo $0 $*"
    exit 1
fi

# 验证 L4T 目录
if [ ! -f "$L4T_DIR/flash.sh" ]; then
    print_error "Invalid L4T directory: $L4T_DIR"
    print_error "Please run from rm01-thor/scripts/ directory"
    exit 1
fi

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}    RM01-Thor Direct Flash Tool${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
print_info "L4T Directory: $L4T_DIR"
print_info "Project: $PROJECT_DIR"
echo ""

# 安装优化的烧录脚本
install_optimized_scripts() {
    local KERNEL_FLASH_DIR="$L4T_DIR/tools/kernel_flash"
    local OPTIMIZED_SCRIPT="$PROJECT_DIR/tools/kernel_flash/l4t_flash_from_kernel.sh"
    
    if [ ! -f "$OPTIMIZED_SCRIPT" ]; then
        print_error "Optimized script not found: $OPTIMIZED_SCRIPT"
        exit 1
    fi
    
    # 备份原始脚本
    if [ -f "$KERNEL_FLASH_DIR/l4t_flash_from_kernel.sh" ] && \
       [ ! -f "$KERNEL_FLASH_DIR/l4t_flash_from_kernel.sh.orig" ]; then
        cp "$KERNEL_FLASH_DIR/l4t_flash_from_kernel.sh" \
           "$KERNEL_FLASH_DIR/l4t_flash_from_kernel.sh.orig"
        print_info "Original script backed up"
    fi
    
    # 安装优化脚本
    cp "$OPTIMIZED_SCRIPT" "$KERNEL_FLASH_DIR/l4t_flash_from_kernel.sh"
    chmod +x "$KERNEL_FLASH_DIR/l4t_flash_from_kernel.sh"
    
    # 同步到 images 目录
    if [ -d "$KERNEL_FLASH_DIR/images" ]; then
        cp "$OPTIMIZED_SCRIPT" "$KERNEL_FLASH_DIR/images/l4t_flash_from_kernel.sh"
        chmod +x "$KERNEL_FLASH_DIR/images/l4t_flash_from_kernel.sh"
    fi
    
    print_info "Optimized flash scripts installed"
}

# 安装配置文件
install_config() {
    print_info "Installing rm01-thor configuration..."
    
    # 检查并安装必要文件
    [ -f "$PROJECT_DIR/rm01-thor.conf" ] && \
        cp "$PROJECT_DIR/rm01-thor.conf" "$L4T_DIR/"
    
    [ -f "$PROJECT_DIR/dtb/tegra264-rm01-thor.dtb" ] && \
        cp "$PROJECT_DIR/dtb/tegra264-rm01-thor.dtb" "$L4T_DIR/kernel/dtb/"
    
    [ -f "$PROJECT_DIR/bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts" ] && \
        cp "$PROJECT_DIR/bootloader/tegra264-mb2-bct-misc-p3834-0008-rm01.dts" "$L4T_DIR/bootloader/"
    
    [ -f "$PROJECT_DIR/tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml" ] && \
        cp "$PROJECT_DIR/tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml" "$L4T_DIR/tools/kernel_flash/"
    
    print_info "Configuration installed"
}

# 解析参数
FLASH_ARGS=()
TARGET="nvme0n1p1"
EXTERNAL_DEVICE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --external-device)
            EXTERNAL_DEVICE="$2"
            FLASH_ARGS+=("--external-device" "$2")
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options] [target]"
            echo ""
            echo "Options:"
            echo "  --external-device <dev>  Flash to external device (e.g., sda)"
            echo "  --help                   Show this help"
            echo ""
            echo "Default target: nvme0n1p1"
            exit 0
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

# 安装文件
install_config
install_optimized_scripts

echo ""
print_info "Starting flash process..."
echo ""

# 切换到 L4T 目录执行 initrd flash
cd "$L4T_DIR"

# 构建刷机命令
FLASH_CMD="./tools/kernel_flash/l4t_initrd_flash.sh"

if [ -n "$EXTERNAL_DEVICE" ]; then
    FLASH_CMD="$FLASH_CMD --external-device $EXTERNAL_DEVICE"
    FLASH_CMD="$FLASH_CMD -c tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml"
fi

FLASH_CMD="$FLASH_CMD --direct $EXTERNAL_DEVICE rm01-thor $TARGET"

print_info "Executing: $FLASH_CMD"
echo ""

# 执行刷机
eval "$FLASH_CMD"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}    Flash Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
