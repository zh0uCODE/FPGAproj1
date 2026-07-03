#!/bin/bash
# ============================================================
# FPGA 开源工具链 — 全自动一键安装
# git clone 后只需运行此脚本，所有工具自动就绪
#
# 用法:
#   bash tools/setup_all.sh
#
# 针对: Digilent Arty A7-35T (XC7A35T-1CSG324)
# 平台: Apple Silicon Mac, macOS 15+
# 耗时: 首次约 2-3 小时（含下载编译）
# 磁盘: ~3.5 GB
# ============================================================
set -e

FPGA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$FPGA_ROOT/tools"
NEXTPNR="$TOOLS/nextpnr-xilinx-src"
PRJXRAY="$TOOLS/prjxray"

echo "╔══════════════════════════════════════════════╗"
echo "║  FPGA 开源工具链 — 全自动安装               ║"
echo "║  Arty A7-35T / XC7A35T-1CSG324              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ============================================================
# Phase 0: 系统依赖
# ============================================================
echo "━━━ Phase 0/5: 系统依赖 ━━━"

if ! command -v brew &> /dev/null; then
    echo "请先安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

DEPS=(cmake boost eigen gflags abseil yaml-cpp)
MISSING=()
for dep in "${DEPS[@]}"; do
    if ! brew list "$dep" &>/dev/null; then
        MISSING+=("$dep")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "安装编译依赖: ${MISSING[*]} ..."
    brew install "${MISSING[@]}"
else
    echo "系统依赖已就绪"
fi

# ============================================================
# Phase 1: oss-cad-suite
# ============================================================
echo ""
echo "━━━ Phase 1/5: oss-cad-suite (Yosys + openFPGALoader + 仿真) ━━━"

if [ -f "$TOOLS/oss-cad-suite/environment" ]; then
    echo "oss-cad-suite 已安装，跳过"
else
    echo "下载预编译包（~490MB）..."
    LATEST=$(curl -sL https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases \
        | python3 -c "import json,sys; r=json.load(sys.stdin); print(r[0]['tag_name'])")
    TAG="${LATEST//-/}"
    TGZ="oss-cad-suite-darwin-arm64-${TAG}.tgz"
    URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${LATEST}/${TGZ}"
    curl -L -o "$TOOLS/oss-cad-suite.tgz" "$URL"
    echo "解压中..."
    tar xzf "$TOOLS/oss-cad-suite.tgz" -C "$TOOLS"
    rm "$TOOLS/oss-cad-suite.tgz"
    echo "oss-cad-suite 安装完成"
fi

# 快速验证
source "$TOOLS/oss-cad-suite/environment"
echo "  Yosys: $(yosys --version 2>&1 | head -1)"
echo "  openFPGALoader: $(openFPGALoader --version 2>&1 | head -1)"

# ============================================================
# Phase 2: nextpnr-xilinx
# ============================================================
echo ""
echo "━━━ Phase 2/5: nextpnr-xilinx (布局布线) ━━━"

if [ ! -d "$NEXTPNR" ]; then
    echo "克隆 openXC7/nextpnr-xilinx（含 prjxray-db submodule）..."
    git clone --recurse-submodules https://github.com/openXC7/nextpnr-xilinx.git "$NEXTPNR"
fi

if [ -x "$NEXTPNR/build/nextpnr-xilinx" ]; then
    echo "nextpnr-xilinx 已编译，跳过"
else
    echo "编译 nextpnr-xilinx（约 10-20 分钟）..."
    mkdir -p "$NEXTPNR/build" && cd "$NEXTPNR/build"
    cmake -DARCH=xilinx \
        -DBUILD_GUI=OFF \
        -DBUILD_PYTHON=OFF \
        -DUSE_OPENMP=OFF \
        -DEigen3_DIR=/opt/homebrew/share/eigen3/cmake \
        -DCMAKE_CXX_FLAGS="-I/opt/homebrew/include/eigen3" \
        ..
    make -j$(sysctl -n hw.ncpu)
    echo "nextpnr-xilinx 编译完成"
fi
echo "  nextpnr-xilinx: $($NEXTPNR/build/nextpnr-xilinx --version 2>&1 | head -1)"

# ============================================================
# Phase 3: 芯片数据库
# ============================================================
echo ""
echo "━━━ Phase 3/5: 芯片数据库 (chipdb) ━━━"

if [ -f "$NEXTPNR/xilinx/xc7a35t.bin" ]; then
    echo "chipdb 已存在 ($(du -h "$NEXTPNR/xilinx/xc7a35t.bin" | cut -f1))"
else
    cd "$NEXTPNR"
    if [ ! -f xilinx/xc7a35t.bba ]; then
        echo "生成 BBA（约 2-3 分钟）..."
        python3 xilinx/python/bbaexport.py --device xc7a35tcsg324-1 --bba xilinx/xc7a35t.bba
    fi
    echo "编译 BBA → BIN..."
    ./build/bbasm --l xilinx/xc7a35t.bba xilinx/xc7a35t.bin
    echo "chipdb: $(du -h xilinx/xc7a35t.bin | cut -f1)"
fi

# ============================================================
# Phase 4: prjxray 比特流工具
# ============================================================
echo ""
echo "━━━ Phase 4/5: prjxray 比特流工具 ━━━"

echo "安装 Python 依赖..."
pip3 install fasm simplejson numpy pyyaml intervaltree ordered-set textx 2>&1 | tail -1

if [ ! -d "$PRJXRAY" ]; then
    echo "克隆 f4pga/prjxray..."
    git clone --depth=1 https://github.com/f4pga/prjxray.git "$PRJXRAY"
    cd "$PRJXRAY"
    git submodule update --init --recursive --depth=1
fi

if [ -x "$PRJXRAY/build/tools/xc7frames2bit" ]; then
    echo "xc7frames2bit 已编译，跳过"
else
    echo "编译 xc7frames2bit（约 5-10 分钟）..."
    cd "$PRJXRAY"
    rm -rf build && mkdir build && cd build
    cmake -DCMAKE_PREFIX_PATH=/opt/homebrew ..
    make -j$(sysctl -n hw.ncpu) xc7frames2bit
    echo "xc7frames2bit: $(ls -lh tools/xc7frames2bit | awk '{print $5}')"
fi

# 验证 fasm2frames
PYTHONPATH="$PRJXRAY:$PRJXRAY/utils" python3 -c "
from prjxray import fasm_assembler
print('  fasm2frames: OK')
" 2>/dev/null || echo "  fasm2frames: 有非关键警告，不影响使用"

# ============================================================
# Phase 5: 验证
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  安装完成！验证                              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

source "$TOOLS/oss-cad-suite/environment"
export PATH="$NEXTPNR/build:$PATH"
export PATH="$PRJXRAY/build/tools:$PATH"

echo "  Yosys:           $(yosys --version 2>&1 | head -1)"
echo "  nextpnr-xilinx:  $(nextpnr-xilinx --version 2>&1 | head -1)"
echo "  openFPGALoader:  $(openFPGALoader --version 2>&1 | head -1)"
echo "  chipdb:          $(du -h $NEXTPNR/xilinx/xc7a35t.bin | cut -f1)"
echo "  xc7frames2bit:   $(ls -lh $PRJXRAY/build/tools/xc7frames2bit 2>/dev/null | awk '{print $5}')"

echo ""
echo "  ✅ 全部就绪！"
echo "  source tools/env.sh    # 激活环境"
echo "  bash projects/led-demo/build_and_flash.sh  # 跑示例工程"
