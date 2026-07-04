#!/bin/bash
# ============================================================
# FPGA Open-Source Toolchain — Environment Setup
# Arty A7-35T (XC7A35T-1CSG324)
#
# Usage: source tools/env.sh
#
# ⚠️ Note: oss-cad-suite overrides PATH/PYTHONPATH.
#    Bitstream generation (fasm2frames) must use the system python3;
#    do not rely on the PYTHONPATH set here.
#    See projects/led-demo/build_and_flash.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="/Users/yizhou/ece/fpga/tools"
fi
FPGA_ROOT="$(dirname "$SCRIPT_DIR")"

echo "===== FPGA Toolchain (Arty A7-35T) ====="

# --- oss-cad-suite (Yosys, openFPGALoader, simulation) ---
OSS_CAD="$SCRIPT_DIR/oss-cad-suite"
if [ -f "$OSS_CAD/environment" ]; then
    source "$OSS_CAD/environment"
    echo "[OK] oss-cad-suite"
else
    echo "[--] oss-cad-suite not installed"
fi

# --- nextpnr-xilinx ---
NEXTPNR="$SCRIPT_DIR/nextpnr-xilinx-src/build/nextpnr-xilinx"
if [ -x "$NEXTPNR" ]; then
    export PATH="$SCRIPT_DIR/nextpnr-xilinx-src/build:$PATH"
    echo "[OK] nextpnr-xilinx"
else
    echo "[--] nextpnr-xilinx not built"
fi

# --- Chip database ---
CHIPDB="$SCRIPT_DIR/nextpnr-xilinx-src/xilinx/xc7a35t.bin"
if [ -f "$CHIPDB" ]; then
    export NEXTPNR_CHIPDB="$CHIPDB"
    echo "[OK] chipdb ($(du -h "$CHIPDB" | cut -f1))"
else
    echo "[--] chipdb not generated"
fi

# --- prjxray database ---
PRJXRAY_DB="$SCRIPT_DIR/nextpnr-xilinx-src/xilinx/external/prjxray-db"
if [ -d "$PRJXRAY_DB" ]; then
    export PRJXRAY_DB_DIR="$PRJXRAY_DB"
    echo "[OK] prjxray-db"
else
    echo "[--] prjxray-db not installed"
fi

# --- xc7frames2bit ---
XFRAME="$SCRIPT_DIR/prjxray/build/tools/xc7frames2bit"
if [ -x "$XFRAME" ]; then
    export PATH="$SCRIPT_DIR/prjxray/build/tools:$PATH"
    echo "[OK] xc7frames2bit"
else
    echo "[--] xc7frames2bit not built"
fi

# --- prjxray Python tools (use system python3, NOT the oss-cad-suite one) ---
PRJXRAY_PY="$SCRIPT_DIR/prjxray"
if [ -d "$PRJXRAY_PY" ]; then
    export PRJXRAY_PYTHONPATH="$PRJXRAY_PY:$PRJXRAY_PY/utils"
    echo "[OK] prjxray Python (fasm2frames)"
else
    echo "[--] prjxray not installed"
fi

export FPGA_ROOT="$FPGA_ROOT"

echo ""
echo "  Development flow:"
echo "    yosys → nextpnr-xilinx → fasm2frames → xc7frames2bit → openFPGALoader"
echo "  Simulation: iverilog, verilator, gtkwave"
echo ""
echo "  ⚠️ Use the system python3 for bitstream generation:"
echo "     PYTHONPATH=\$PRJXRAY_PYTHONPATH python3 .../fasm2frames.py ..."
echo "=============================="
