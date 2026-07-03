#!/bin/bash
# ============================================================
# FPGA 开源工具链 — 环境配置脚本
# 适用: Digilent Arty A7-35T (Xilinx Artix-7 XC7A35T-1CSG324)
#
# 使用方法:
#   source tools/env.sh
# ============================================================

# 检测脚本所在目录（兼容 source 和直接执行）
if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # 被 source 加载，BASH_SOURCE 指向本文件
    _THIS_FILE="${BASH_SOURCE[0]}"
else
    _THIS_FILE="${0}"
fi
SCRIPT_DIR="$(cd "$(dirname "$_THIS_FILE")" 2>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ]; then
    # 回退：假设在 fpga/tools/ 下
    SCRIPT_DIR="/Users/yizhou/ece/fpga/tools"
fi
FPGA_ROOT="$(dirname "$SCRIPT_DIR")"

echo "===== FPGA 开源工具链 v1.0 ====="
echo "目标板: Digilent Arty A7-35T (XC7A35T-1CSG324)"
echo ""

# --- oss-cad-suite (Yosys, openFPGALoader, 仿真工具等) ---
OSS_CAD="$SCRIPT_DIR/oss-cad-suite"
if [ -f "$OSS_CAD/environment" ]; then
    source "$OSS_CAD/environment"
    echo "[OK] oss-cad-suite"
else
    echo "[!!] oss-cad-suite 未找到"
fi

# --- nextpnr-xilinx (布局布线) ---
NEXTPNR_BUILD="$SCRIPT_DIR/nextpnr-xilinx-src/build"
if [ -x "$NEXTPNR_BUILD/nextpnr-xilinx" ]; then
    export PATH="$NEXTPNR_BUILD:$PATH"
    echo "[OK] nextpnr-xilinx"
else
    echo "[!!] nextpnr-xilinx 未编译"
fi

# --- 芯片数据库 chipdb (nextpnr-xilinx 需要) ---
CHIPDB="$SCRIPT_DIR/nextpnr-xilinx-src/xilinx/xc7a35t.bin"
if [ -f "$CHIPDB" ]; then
    export NEXTPNR_CHIPDB="$CHIPDB"
    echo "[OK] chipdb (xc7a35t)"
else
    echo "[!!] chipdb 未生成"
fi

# --- prjxray 数据库 (比特流生成需要) ---
PRJXRAY_DB="$SCRIPT_DIR/nextpnr-xilinx-src/xilinx/external/prjxray-db"
if [ -d "$PRJXRAY_DB" ]; then
    export PRJXRAY_DB_DIR="$PRJXRAY_DB"
    echo "[OK] prjxray-db"
else
    echo "[!!] prjxray-db 未找到"
fi

# --- prjxray Python 工具 (fasm2frames) ---
PRJXRAY="$SCRIPT_DIR/prjxray"
if [ -d "$PRJXRAY" ]; then
    export PYTHONPATH="$PRJXRAY:$PRJXRAY/utils${PYTHONPATH:+:$PYTHONPATH}"
    echo "[OK] prjxray Python 工具"
else
    echo "[!!] prjxray 未安装"
fi

# --- prjxray C++ 工具 (xc7frames2bit) ---
if [ -x "$PRJXRAY/build/tools/xc7frames2bit" ]; then
    export PATH="$PRJXRAY/build/tools:$PATH"
    echo "[OK] xc7frames2bit"
else
    echo "[--] xc7frames2bit 未编译（需手动编译）"
fi

# --- FPGA 项目根目录 ---
export FPGA_ROOT="$FPGA_ROOT"

echo ""
echo "--- 工具链流程 ---"
echo "  yosys          → 综合 (Verilog → JSON)"
echo "  nextpnr-xilinx → 布局布线 (JSON → FASM)"
echo "  fasm2frames     → 帧生成 (FASM → frames)"
echo "  xc7frames2bit   → 比特流 (frames → .bit)"
echo "  openFPGALoader  → 烧录 (-b arty)"
echo "--- 仿真工具 ---"
echo "  iverilog, verilator, gtkwave"
echo "=============================="
