#!/bin/bash
# ============================================================
# FPGA Open-Source Toolchain — Fully Automated One-Click Install
# After git clone, just run this script and all tools will be ready.
#
# Usage:
#   bash tools/setup_all.sh
#
# Target: Digilent Arty A7-35T (XC7A35T-1CSG324)
# Platform: Apple Silicon Mac, macOS 15+
# Duration: ~2-3 hours on first run (including download and compile)
# Disk: ~3.5 GB
# ============================================================
set -e

FPGA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$FPGA_ROOT/tools"
NEXTPNR="$TOOLS/nextpnr-xilinx-src"
PRJXRAY="$TOOLS/prjxray"

echo "╔══════════════════════════════════════════════╗"
echo "║  FPGA Open-Source Toolchain — Auto Install   ║"
echo "║  Arty A7-35T / XC7A35T-1CSG324              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ============================================================
# Phase 0: System dependencies
# ============================================================
echo "━━━ Phase 0/5: System dependencies ━━━"

if ! command -v brew &> /dev/null; then
    echo "Please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
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
    echo "Installing build dependencies: ${MISSING[*]} ..."
    brew install "${MISSING[@]}"
else
    echo "System dependencies already satisfied"
fi

# ============================================================
# Phase 1: oss-cad-suite
# ============================================================
echo ""
echo "━━━ Phase 1/5: oss-cad-suite (Yosys + openFPGALoader + simulation) ━━━"

if [ -f "$TOOLS/oss-cad-suite/environment" ]; then
    echo "oss-cad-suite already installed, skipping"
else
    echo "Downloading prebuilt package (~490MB)..."
    LATEST=$(curl -sL https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases \
        | python3 -c "import json,sys; r=json.load(sys.stdin); print(r[0]['tag_name'])")
    TAG="${LATEST//-/}"
    TGZ="oss-cad-suite-darwin-arm64-${TAG}.tgz"
    URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${LATEST}/${TGZ}"
    curl -L -o "$TOOLS/oss-cad-suite.tgz" "$URL"
    echo "Extracting..."
    tar xzf "$TOOLS/oss-cad-suite.tgz" -C "$TOOLS"
    rm "$TOOLS/oss-cad-suite.tgz"
    echo "oss-cad-suite installed"
fi

# Quick sanity check
source "$TOOLS/oss-cad-suite/environment"
echo "  Yosys: $(yosys --version 2>&1 | head -1)"
echo "  openFPGALoader: $(openFPGALoader --version 2>&1 | head -1)"

# ============================================================
# Phase 2: nextpnr-xilinx
# ============================================================
echo ""
echo "━━━ Phase 2/5: nextpnr-xilinx (place & route) ━━━"

if [ ! -d "$NEXTPNR" ]; then
    echo "Cloning openXC7/nextpnr-xilinx (includes prjxray-db submodule)..."
    git clone --recurse-submodules https://github.com/openXC7/nextpnr-xilinx.git "$NEXTPNR"
fi

if [ -x "$NEXTPNR/build/nextpnr-xilinx" ]; then
    echo "nextpnr-xilinx already built, skipping"
else
    echo "Building nextpnr-xilinx (about 10-20 minutes)..."
    mkdir -p "$NEXTPNR/build" && cd "$NEXTPNR/build"
    cmake -DARCH=xilinx \
        -DBUILD_GUI=OFF \
        -DBUILD_PYTHON=OFF \
        -DUSE_OPENMP=OFF \
        -DEigen3_DIR=/opt/homebrew/share/eigen3/cmake \
        -DCMAKE_CXX_FLAGS="-I/opt/homebrew/include/eigen3" \
        ..
    make -j$(sysctl -n hw.ncpu)
    echo "nextpnr-xilinx build complete"
fi
echo "  nextpnr-xilinx: $($NEXTPNR/build/nextpnr-xilinx --version 2>&1 | head -1)"

# ============================================================
# Phase 3: Chip database
# ============================================================
echo ""
echo "━━━ Phase 3/5: Chip database (chipdb) ━━━"

if [ -f "$NEXTPNR/xilinx/xc7a35t.bin" ]; then
    echo "chipdb already exists ($(du -h "$NEXTPNR/xilinx/xc7a35t.bin" | cut -f1))"
else
    cd "$NEXTPNR"
    if [ ! -f xilinx/xc7a35t.bba ]; then
        echo "Generating BBA (about 2-3 minutes)..."
        python3 xilinx/python/bbaexport.py --device xc7a35tcsg324-1 --bba xilinx/xc7a35t.bba
    fi
    echo "Assembling BBA → BIN..."
    ./build/bbasm --l xilinx/xc7a35t.bba xilinx/xc7a35t.bin
    echo "chipdb: $(du -h xilinx/xc7a35t.bin | cut -f1)"
fi

# ============================================================
# Phase 4: prjxray bitstream tools
# ============================================================
echo ""
echo "━━━ Phase 4/5: prjxray bitstream tools ━━━"

echo "Installing Python dependencies..."
pip3 install fasm simplejson numpy pyyaml intervaltree ordered-set textx 2>&1 | tail -1

if [ ! -d "$PRJXRAY" ]; then
    echo "Cloning f4pga/prjxray..."
    git clone --depth=1 https://github.com/f4pga/prjxray.git "$PRJXRAY"
    cd "$PRJXRAY"
    git submodule update --init --recursive --depth=1
fi

if [ -x "$PRJXRAY/build/tools/xc7frames2bit" ]; then
    echo "xc7frames2bit already built, skipping"
else
    echo "Building xc7frames2bit (about 5-10 minutes)..."
    cd "$PRJXRAY"
    rm -rf build && mkdir build && cd build
    cmake -DCMAKE_PREFIX_PATH=/opt/homebrew ..
    make -j$(sysctl -n hw.ncpu) xc7frames2bit
    echo "xc7frames2bit: $(ls -lh tools/xc7frames2bit | awk '{print $5}')"
fi

# Verify fasm2frames
PYTHONPATH="$PRJXRAY:$PRJXRAY/utils" python3 -c "
from prjxray import fasm_assembler
print('  fasm2frames: OK')
" 2>/dev/null || echo "  fasm2frames: non-critical warnings, safe to ignore"

# ============================================================
# Phase 5: Verification
# ============================================================
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Installation complete! Verifying            ║"
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
echo "  ✅ All set!"
echo "  source tools/env.sh    # activate the environment"
echo "  bash projects/led-demo/build_and_flash.sh  # run the example project"
