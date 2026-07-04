#!/bin/bash
set -e
cd /Users/yizhou/ece/fpga/projects/led-demo

OSS_CAD="/Users/yizhou/ece/fpga/tools/oss-cad-suite"
NEXTPNR="/Users/yizhou/ece/fpga/tools/nextpnr-xilinx-src/build"
CHIPDB="/Users/yizhou/ece/fpga/tools/nextpnr-xilinx-src/xilinx/xc7a35t.bin"
PRJXRAY_DB="/Users/yizhou/ece/fpga/tools/nextpnr-xilinx-src/xilinx/external/prjxray-db"
PRJXRAY="/Users/yizhou/ece/fpga/tools/prjxray"

# Python dependencies (does not depend on oss-cad-suite)
pip3 install simplejson numpy pyyaml intervaltree ordered-set 2>&1 | tail -1

# ---- Synthesis & P&R (need oss-cad-suite) ----
echo "=== Synthesis ==="
source $OSS_CAD/environment
export PATH="$NEXTPNR:$PATH"
yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top top; write_json top.json" top.v 2>&1 | tail -1

echo "=== Place & Route ==="
nextpnr-xilinx --chipdb $CHIPDB --xdc arty.xdc --json top.json --write top_routed.json --fasm top.fasm 2>&1 | grep -E "error|errors"

# ---- Bitstream (use system python, NOT oss-cad-suite) ----
echo "=== FASM -> frames ==="
export PYTHONPATH="$PRJXRAY:$PRJXRAY/utils"
/Users/yizhou/miniconda3/bin/python3 $PRJXRAY/utils/fasm2frames.py \
    --part xc7a35tcsg324-1 \
    --db-root $PRJXRAY_DB/artix7 \
    top.fasm > top.frames
echo "  frames: $(wc -l < top.frames) lines"

echo "=== frames -> .bit ==="
$PRJXRAY/build/tools/xc7frames2bit \
    --part_file $PRJXRAY_DB/artix7/xc7a35tcsg324-1/part.yaml \
    --part_name xc7a35tcsg324-1 \
    --frm_file top.frames \
    --output_file top.bit
ls -lh top.bit

# ---- Flash ----
echo "=== Flashing ==="
source $OSS_CAD/environment
openFPGALoader -b arty top.bit
echo "DONE"
