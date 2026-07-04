# FPGA Open-Source Toolchain — Digilent Arty A7-35T

## Project Overview

Build a **completely free and open-source** FPGA development toolchain on a MacBook
(Apple Silicon, macOS 15.5), with the goal of running the full digital logic design flow
on a **Digilent Arty A7-35T** (Xilinx Artix-7 XC7A35T-1CSG324):
Verilog → synthesis → place & route → bitstream generation → flash to the board.

All tools are installed inside the project directory, so the whole thing can be packed
up and carried anywhere — fully portable.

## User Preferences

- When the user says "open the dev board docs", open it in the browser with the `open` command:
  `open docs/arty-a7-reference-manual.mhtml`
- Communicate in Chinese throughout
- When the user says "flash / burn it to the board", run through the full development
  flow below, finishing with openFPGALoader to program the board

## "build tools" / "构建工具链" Command

When the user says **"build tools"** / **"构建工具链"** / **"安装工具链"** / **"重建工具链"** /
**"搞环境"**, run:

```bash
bash tools/setup_all.sh
```

This script does everything automatically:
1. Installs Homebrew build dependencies (cmake, boost, eigen, gflags, abseil, yaml-cpp)
2. Downloads oss-cad-suite (Yosys + openFPGALoader + simulation tools)
3. Clones and builds nextpnr-xilinx (place & route)
4. Generates the chipdb chip database
5. Clones and builds prjxray (bitstream tools) + installs Python dependencies

The first run takes about 2-3 hours. Once done, `source tools/env.sh` activates all tools.

**Standard flow after git clone:**
```bash
git clone <repo-url> fpga
cd fpga
# In Claude Code, say "build tools", or directly:
bash tools/setup_all.sh
```

---

## Full Development Flow (verified working ✅)

> Reference project: `projects/led-demo/` — LED0 and LED3 on, LED1/LED2 off

### 0. Prerequisite: activate the environment

```bash
source tools/env.sh
```

### 1. Synthesis (Yosys)

```bash
cd projects/your-project
yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top top; write_json top.json" top.v
```

### 2. Place & Route (nextpnr-xilinx)

```bash
nextpnr-xilinx \
    --chipdb /Users/yizhou/ece/fpga/tools/nextpnr-xilinx-src/xilinx/xc7a35t.bin \
    --xdc arty.xdc \
    --json top.json \
    --write top_routed.json \
    --fasm top.fasm
```

### 3. Bitstream Generation (⚠️ mind the Python environment)

> **Key pitfall:** oss-cad-suite bundles its own Python environment; after `source environment`
> it shadows the system Python. But the `fasm` package was pip-installed into the
> system/miniconda Python, which the oss-cad-suite Python can't see.
> **So the bitstream generation step must NOT use the oss-cad-suite Python.**

```bash
# Use miniconda's python3 (absolute path); do not source oss-cad-suite
export PRJXRAY_DB_DIR="/Users/yizhou/ece/fpga/tools/nextpnr-xilinx-src/xilinx/external/prjxray-db"
export PYTHONPATH="/Users/yizhou/ece/fpga/tools/prjxray:/Users/yizhou/ece/fpga/tools/prjxray/utils"

# Step 3a: FASM → frames
python3 /Users/yizhou/ece/fpga/tools/prjxray/utils/fasm2frames.py \
    --part xc7a35tcsg324-1 \
    --db-root $PRJXRAY_DB_DIR/artix7 \
    top.fasm > top.frames

# Step 3b: frames → .bit
/Users/yizhou/ece/fpga/tools/prjxray/build/tools/xc7frames2bit \
    --part_file $PRJXRAY_DB_DIR/artix7/xc7a35tcsg324-1/part.yaml \
    --part_name xc7a35tcsg324-1 \
    --frm_file top.frames \
    --output_file top.bit
```

### 4. Flashing

```bash
# Needs the oss-cad-suite environment (openFPGALoader lives there)
source /Users/yizhou/ece/fpga/tools/oss-cad-suite/environment

# Load to SRAM (lost on power-off, for debugging)
openFPGALoader -b arty top.bit

# Write to Flash (persists across power cycles)
openFPGALoader -b arty -f top.bit
```

### One-Click Script

`projects/led-demo/build_and_flash.sh` is a verified end-to-end one-click script,
from synthesis to flashing. New projects can use it as a reference.

---

## Pitfall Log

### Pitfall 9: oss-cad-suite Python environment conflict (important!)

**Symptom**: after `source oss-cad-suite/environment`, running `python3 fasm2frames.py` fails with
`ModuleNotFoundError: No module named 'fasm'`, even though `pip3 list | grep fasm` shows it installed.

**Cause**: oss-cad-suite bundles Python 3.11 (in `py3bin/`) and related libraries; `source environment`
points PATH and PYTHONPATH at the oss-cad-suite Python. But `fasm` was `pip3 install`ed into the
system/miniconda Python, which the oss-cad-suite Python can't find.

**Fix**:
- Steps 1-2 (synthesis, P&R) and Step 4 (flashing) need the oss-cad-suite environment
- Step 3 (bitstream generation) **must use the system/miniconda python3**; do not source oss-cad-suite
- Before generating the bitstream, make sure the prjxray Python dependencies are installed:
  ```bash
  pip3 install simplejson numpy pyyaml intervaltree ordered-set textx fasm
  ```

**Rule of thumb**: the oss-cad-suite environment is "polluting" — it changes PATH/PYTHONPATH/PYTHONHOME.
Only source it when you need its tools (yosys, openFPGALoader), and switch back as soon as you're done.

### Pitfall 10: prjxray fasm2frames missing Python dependencies

**Symptom**: `ModuleNotFoundError: No module named 'simplejson'` (also numpy, intervaltree, etc.)

**Cause**: prjxray has a `requirements.txt`, but `pip3 install -e` was blocked by security policy.
Installing only `pip3 install fasm` gets the fasm core package but not prjxray's other dependencies.

**Fix**:
```bash
pip3 install simplejson numpy pyyaml intervaltree ordered-set textx
```

### Pitfalls 1-8

See Section 9 of `docs/SOP-macos-fpga-toolchain.md`.

---

## Hardware Info

- Dev board: Digilent Arty A7-35T
- FPGA chip: Xilinx Artix-7 XC7A35T-1CSG324 (CSG324, 324-pin BGA)
- Logic: 33,280 LUTs / 41,600 FFs / 90 DSP / 1,800Kb BRAM
- Clock: 100MHz crystal (E3)
- USB-JTAG: FTDI FT2232HQ (on-board)
- 4 LEDs (H5, J5, T9, T10) · 4 RGB LEDs · 4 switches · 4 buttons · 4 Pmods · Eth · DDR3

Detailed pinout tables → `docs/hardware-reference.md`

## Toolchain Architecture

```
Verilog source
      │
      ▼
┌──────────┐  Yosys 0.66       Synthesis: synth_xilinx -arch xc7
│  Yosys   │  (oss-cad-suite)  Verilog → JSON
└────┬─────┘
     │ JSON
     ▼
┌──────────┐  nextpnr-xilinx   Place & route
│ nextpnr  │  0.8.2 (built     JSON → FASM
└────┬─────┘   from source)
     │ FASM
     ▼
┌──────────┐  fasm2frames      Python (system python3)
│ prjxray  │  xc7frames2bit    C++ (built from source)
└────┬─────┘
     │ .bit
     ▼
┌──────────┐  openFPGALoader   Flash to the board
│ Flash    │  1.1.1            openFPGALoader -b arty
└──────────┘
```

## Directory Layout

```
fpga/
├── CLAUDE.md                   ← project documentation (this file)
├── .gitignore
├── hardware/
│   ├── arty-a7-35t.xdc        ← XDC constraints (clock + LEDs enabled)
│   └── arty-a7-35t-top.v      ← top-level Verilog template
├── docs/
│   ├── arty-a7-reference-manual.mhtml  ← official reference manual (board photos + annotations)
│   ├── hardware-reference.md           ← pinout quick-reference card
│   └── SOP-macos-fpga-toolchain.md     ← toolchain setup SOP
├── tools/
│   ├── env.sh                  ← environment script
│   ├── setup_all.sh            ← one-click install
│   ├── oss-cad-suite/          ← [gitignored] 1.8GB
│   ├── nextpnr-xilinx-src/     ← [gitignored] 1.3GB
│   └── prjxray/                ← [gitignored] 219MB
└── projects/
    └── led-demo/               ← verified example project
        ├── top.v               ← LED0+LED3 on
        ├── arty.xdc            ← 4-LED constraints
        └── build_and_flash.sh  ← one-click script
```

## Environment Activation

```bash
source tools/env.sh
```

env.sh loads as needed:
- oss-cad-suite environment (yosys, openFPGALoader)
- nextpnr-xilinx path
- prjxray Python path (uses the system python3, not the oss-cad-suite one)
- chipdb and prjxray-db paths

## Verified Example Project

`projects/led-demo/` — minimal example, LED0 and LED3 always on:

```verilog
module top (output wire [3:0] led);
    assign led[0] = 1'b1;
    assign led[1] = 1'b0;
    assign led[2] = 1'b0;
    assign led[3] = 1'b1;
endmodule
```

Run end to end: `bash projects/led-demo/build_and_flash.sh`

## References

- https://github.com/YosysHQ/oss-cad-suite-build
- https://github.com/openXC7/nextpnr-xilinx
- https://github.com/f4pga/prjxray
- https://github.com/trabucayre/openFPGALoader
- https://digilent.com/reference/programmable-logic/arty-a7/start

---

*Last updated: 2026-07-03*
