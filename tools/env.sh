#!/bin/bash
# ============================================================
# FPGA 开源工具链 — 环境配置
# Arty A7-35T (XC7A35T-1CSG324)
#
# 用法: source tools/env.sh
#
# ⚠️ 注意: oss-cad-suite 会覆盖 PATH/PYTHONPATH。
#    比特流生成（fasm2frames）需要用系统 python3，不要依赖这里的 PYTHONPATH。
#    参考 projects/led-demo/build_and_flash.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="/Users/yizhou/ece/fpga/tools"
fi
FPGA_ROOT="$(dirname "$SCRIPT_DIR")"

echo "===== FPGA 工具链 (Arty A7-35T) ====="

# --- oss-cad-suite (Yosys, openFPGALoader, 仿真) ---
OSS_CAD="$SCRIPT_DIR/oss-cad-suite"
if [ -f "$OSS_CAD/environment" ]; then
    source "$OSS_CAD/environment"
    echo "[OK] oss-cad-suite"
else
    echo "[--] oss-cad-suite 未安装"
fi

# --- nextpnr-xilinx ---
NEXTPNR="$SCRIPT_DIR/nextpnr-xilinx-src/build/nextpnr-xilinx"
if [ -x "$NEXTPNR" ]; then
    export PATH="$SCRIPT_DIR/nextpnr-xilinx-src/build:$PATH"
    echo "[OK] nextpnr-xilinx"
else
    echo "[--] nextpnr-xilinx 未编译"
fi

# --- 芯片数据库 ---
CHIPDB="$SCRIPT_DIR/nextpnr-xilinx-src/xilinx/xc7a35t.bin"
if [ -f "$CHIPDB" ]; then
    export NEXTPNR_CHIPDB="$CHIPDB"
    echo "[OK] chipdb ($(du -h "$CHIPDB" | cut -f1))"
else
    echo "[--] chipdb 未生成"
fi

# --- prjxray 数据库 ---
PRJXRAY_DB="$SCRIPT_DIR/nextpnr-xilinx-src/xilinx/external/prjxray-db"
if [ -d "$PRJXRAY_DB" ]; then
    export PRJXRAY_DB_DIR="$PRJXRAY_DB"
    echo "[OK] prjxray-db"
else
    echo "[--] prjxray-db 未安装"
fi

# --- xc7frames2bit ---
XFRAME="$SCRIPT_DIR/prjxray/build/tools/xc7frames2bit"
if [ -x "$XFRAME" ]; then
    export PATH="$SCRIPT_DIR/prjxray/build/tools:$PATH"
    echo "[OK] xc7frames2bit"
else
    echo "[--] xc7frames2bit 未编译"
fi

# --- prjxray Python 工具 (用系统 python3, 不用 oss-cad-suite 的) ---
PRJXRAY_PY="$SCRIPT_DIR/prjxray"
if [ -d "$PRJXRAY_PY" ]; then
    export PRJXRAY_PYTHONPATH="$PRJXRAY_PY:$PRJXRAY_PY/utils"
    echo "[OK] prjxray Python (fasm2frames)"
else
    echo "[--] prjxray 未安装"
fi

export FPGA_ROOT="$FPGA_ROOT"

echo ""
echo "  开发流程:"
echo "    yosys → nextpnr-xilinx → fasm2frames → xc7frames2bit → openFPGALoader"
echo "  仿真: iverilog, verilator, gtkwave"
echo ""
echo "  ⚠️ 比特流生成用系统 python3:"
echo "     PYTHONPATH=\$PRJXRAY_PYTHONPATH python3 .../fasm2frames.py ..."
echo "=============================="
