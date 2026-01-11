# RM01-Thor V1.0 CVB - Flash Configuration

Jetson AGX Thor (T264) 自定义载板 RM01-Thor 的刷机配置文件。

## 硬件配置

| 组件 | 规格 |
|------|------|
| **SoM** | P3834-0008 (128GB 内存) |
| **存储** | NVMe SSD (PCIe C5) |
| **网络** | PCIe 网卡 (PCIe C1) |
| **调试** | UART 串口 |
| **USB** | USB 2.0/3.0 |
| **散热** | PWM 风扇控制 |

## 软件版本

- JetPack: 7.1
- L4T: R38.4.0
- CUDA: 13.0
- GPU Driver: 580.00

## 快速安装

### 方法 1: Git Clone

```bash
cd /path/to/Linux_for_Tegra
git clone https://github.com/thomas-hiddenpeak/RM-01-Thor-Flash-conf.git rm01-thor
cd rm01-thor
./setup.sh
```

### 方法 2: 手动下载

下载 release 并解压到 `Linux_for_Tegra/rm01-thor/`，然后运行：

```bash
./setup.sh
```

## 刷机

使用 initrd flash 直接刷机到外部存储设备：

```bash
cd /path/to/Linux_for_Tegra
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
    --external-device sda \
    -c tools/kernel_flash/flash_l4t_t264_nvme_minimal.xml \
    --direct sda \
    rm01-thor nvme0n1p1
```

## 性能优化

本配置包含优化的烧录脚本，显著提升写入速度：

| 分区 | 原始速度 | 优化后速度 | 提升 |
|------|---------|-----------|------|
| APP | ~4.5 MB/s | ~750 MB/s | **~170x** |
| ESP | ~46 MB/s | ~200 MB/s | **~4x** |

### 优化内容

1. **`read_write_file` 函数**: 优先使用 1MB block size (原 1KB)
2. **APP 分区写入**: 使用 `bs=1M oflag=direct` (原 `bs=4K oflag=sync`)

### 恢复原始脚本

如需恢复原始烧录脚本：

```bash
cd /path/to/Linux_for_Tegra/tools/kernel_flash
cp l4t_flash_from_kernel.sh.orig l4t_flash_from_kernel.sh
cp images/l4t_flash_from_kernel.sh.orig images/l4t_flash_from_kernel.sh
```

## 目录结构

```
rm01-thor/
├── rm01-thor.conf                    # 刷机配置
├── setup.sh                          # 一键安装脚本 (推荐)
├── dts/
│   └── tegra264-rm01-thor.dts        # 设备树源文件
├── dtb/
│   └── tegra264-rm01-thor.dtb        # 编译后 DTB
├── bootloader/
│   └── tegra264-mb2-bct-misc-*.dts   # MB2 BCT (禁用 CVB EEPROM)
├── tools/kernel_flash/
│   ├── flash_l4t_t264_nvme_minimal.xml # 分区布局
│   └── l4t_flash_from_kernel.sh      # 优化的烧录脚本
└── scripts/
    ├── install.sh                    # 安装脚本 (setup.sh 的替代)
    └── build-dtb.sh                  # DTB 编译脚本
```

## 设备树配置

### 启用的功能
- DCE (GPU IPC)
- PMC (电源管理)
- USB 2.0/3.0
- PCIe C1/C5
- UART
- PWM Fan

### 禁用的功能 (Headless 优化)
- Display
- Audio (aconnect/ADSP)
- AON
- CAN
- MGBE (10GbE)
- Camera

## License

BSD-3-Clause
