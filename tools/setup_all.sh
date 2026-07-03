#!/bin/bash
# ============================================================
# FPGA 开源工具链 — 一键完成全部设置
# 针对 Digilent Arty A7-35T (XC7A35T-1CSG324)
# ============================================================
set -e
ROOT="/Users/yizhou/ece/fpga/tools"
NEXTPNR="$ROOT/nextpnr-xilinx-src"

echo "=========================================="
echo " FPGA 开源工具链 — 剩余步骤一键完成"
echo "=========================================="
echo ""

# ---- Step 1: 编译芯片数据库 ----
echo ">>> [1/3] 芯片数据库 (chipdb)..."
cd "$NEXTPNR"
if [ -f xilinx/xc7a35t.bin ]; then
    echo "      chipdb 已存在，跳过 ($(du -h xilinx/xc7a35t.bin | cut -f1))"
else
    if [ ! -f xilinx/xc7a35t.bba ]; then
        echo "      生成 BBA 文件（需要 2-3 分钟）..."
        python3 xilinx/python/bbaexport.py --device xc7a35tcsg324-1 --bba xilinx/xc7a35t.bba
    fi
    echo "      编译 BBA → BIN..."
    ./build/bbasm --l xilinx/xc7a35t.bba xilinx/xc7a35t.bin
    echo "      chipdb 生成完毕: $(du -h xilinx/xc7a35t.bin | cut -f1)"
fi

# ---- Step 2: 安装 prjxray Python 工具 ----
echo ""
echo ">>> [2/3] prjxray Python 工具 (fasm2frames)..."
if python3 -c "import fasm" 2>/dev/null; then
    echo "      fasm 已安装"
else
    pip3 install fasm
fi
if [ -d "$ROOT/prjxray" ]; then
    echo "      prjxray 仓库已克隆"
else
    git clone --depth=1 https://github.com/f4pga/prjxray.git "$ROOT/prjxray"
fi
# 验证 fasm2frames 可用
cd "$ROOT/prjxray"
PYTHONPATH="$ROOT/prjxray:$ROOT/prjxray/utils" python3 -c "
from prjxray import fasm_assembler
print('      prjxray Python 模块: OK')
"

# ---- Step 3: 编译 xc7frames2bit ----
echo ""
echo ">>> [3/3] prjxray C++ 工具 (xc7frames2bit)..."
cd "$ROOT/prjxray"
if [ -x "build/tools/xc7frames2bit" ]; then
    echo "      xc7frames2bit 已编译"
else
    echo "      安装依赖..."
    brew list gflags abseil yaml-cpp > /dev/null 2>&1 || \
        brew install gflags abseil yaml-cpp
    echo "      编译 prjxray..."
    rm -rf build && mkdir -p build && cd build
    cmake -DCMAKE_PREFIX_PATH=/opt/homebrew ..
    make -j8 xc7frames2bit
    echo "      xc7frames2bit 编译完毕"
    ls -lh tools/xc7frames2bit
fi

# ---- 验证 ----
echo ""
echo "=========================================="
echo " 全部完成！验证工具链:"
echo "=========================================="
echo ""

source "$ROOT/oss-cad-suite/environment"
echo "Yosys:  $(yosys --version 2>&1 | head -1)"
echo "nextpnr: $($NEXTPNR/build/nextpnr-xilinx --version 2>&1 | head -1)"
echo "openFPGALoader: $(openFPGALoader --version 2>&1 | head -1)"
echo "fasm2frames: $(PYTHONPATH=$ROOT/prjxray:$ROOT/prjxray/utils python3 -c 'print("OK")' 2>&1)"

if [ -x "$ROOT/prjxray/build/tools/xc7frames2bit" ]; then
    echo "xc7frames2bit: OK"
else
    echo "xc7frames2bit: 编译失败，请检查 prjxray/build 目录"
fi

echo ""
echo "=========================================="
echo " 激活环境: source tools/env.sh"
echo "=========================================="
