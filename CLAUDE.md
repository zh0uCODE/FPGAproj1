# FPGA 开源工具链 — Digilent Arty A7-35T

## 项目概述

在 MacBook (Apple Silicon, macOS 15.5) 上搭建一套**完全免费、开源**的 FPGA 开发工具链，
目标是让 **Digilent Arty A7-35T**（Xilinx Artix-7 XC7A35T-1CSG324）能够跑通完整的
数字逻辑设计流程：Verilog → 综合 → 布局布线 → 生成比特流 → 烧录到板子。

所有工具安装在项目目录下，打包即可带走，实现便携化。

## 用户偏好

- 用户说"打开开发板资料"时，用 `open` 命令在浏览器中打开：
  `open docs/arty-a7-reference-manual.mhtml`
- 全程用中文交流
- 用户说"烧录/烧到板子"时，按下面的完整开发流程跑一遍，最后用 openFPGALoader 烧录

## "build tools" / "构建工具链" 命令

当用户说 **"build tools"** / **"构建工具链"** / **"安装工具链"** / **"重建工具链"** /
**"搞环境"**，执行：

```bash
bash tools/setup_all.sh
```

这个脚本全自动完成：
1. 安装 Homebrew 编译依赖（cmake, boost, eigen, gflags, abseil, yaml-cpp）
2. 下载 oss-cad-suite（Yosys + openFPGALoader + 仿真工具）
3. 克隆并编译 nextpnr-xilinx（布局布线）
4. 生成芯片数据库 chipdb
5. 克隆并编译 prjxray（比特流工具）+ 安装 Python 依赖

首次运行约 2-3 小时。跑完后 `source tools/env.sh` 即可激活全部工具。

**git clone 后的标准流程：**
```bash
git clone <repo-url> fpga
cd fpga
# 在 Claude Code 中说 "build tools"，或直接:
bash tools/setup_all.sh
```

---

## 完整开发流程（已验证通过 ✅）

> 参考工程：`projects/led-demo/` — LED0 和 LED3 常亮，LED1/LED2 熄灭

### 0. 前提：激活环境

```bash
source tools/env.sh
```

### 1. 综合 (Yosys)

```bash
cd projects/你的工程
yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top top; write_json top.json" top.v
```

### 2. 布局布线 (nextpnr-xilinx)

```bash
nextpnr-xilinx \
    --chipdb /Users/yizhou/ece/fpga/tools/nextpnr-xilinx-src/xilinx/xc7a35t.bin \
    --xdc arty.xdc \
    --json top.json \
    --write top_routed.json \
    --fasm top.fasm
```

### 3. 比特流生成（⚠️ 注意 Python 环境）

> **关键坑：** oss-cad-suite 自带了 Python 环境，`source environment` 后会覆盖系统 Python。
> 但 `fasm` 包是 pip 装到系统/miniconda Python 里的，oss-cad-suite 的 Python 找不到。
> **所以比特流生成步骤不能用 oss-cad-suite 的 Python。**

```bash
# 用 miniconda 的 python3（绝对路径），不要 source oss-cad-suite
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

### 4. 烧录

```bash
# 需要 oss-cad-suite 环境（openFPGALoader 在里面）
source /Users/yizhou/ece/fpga/tools/oss-cad-suite/environment

# 烧到 SRAM（掉电丢失，调试用）
openFPGALoader -b arty top.bit

# 烧到 Flash（掉电保存）
openFPGALoader -b arty -f top.bit
```

### 一键脚本

`projects/led-demo/build_and_flash.sh` 是验证通过的完整一键脚本，从综合到烧录。
新工程可以参考它来写。

---

## 踩坑记录

### 坑 9: oss-cad-suite 的 Python 环境冲突（重要！）

**现象**：`source oss-cad-suite/environment` 后运行 `python3 fasm2frames.py` 报
`ModuleNotFoundError: No module named 'fasm'`，尽管 `pip3 list | grep fasm` 显示已安装。

**原因**：oss-cad-suite 自带了 Python 3.11（在 `py3bin/`）和相关库，`source environment` 会
把 PATH 和 PYTHONPATH 指向 oss-cad-suite 的 Python。但 `fasm` 是 `pip3 install` 到
系统/miniconda Python 的，oss-cad-suite 的 Python 找不到。

**解决**：
- Step 1-2（综合、布局布线）和 Step 4（烧录）需要 oss-cad-suite 环境
- Step 3（比特流生成）**必须用系统/miniconda 的 python3**，不要 source oss-cad-suite
- 比特流生成前先确保 prjxray Python 依赖已装：
  ```bash
  pip3 install simplejson numpy pyyaml intervaltree ordered-set textx fasm
  ```

**避坑原则**：oss-cad-suite 的环境是"污染的"——它改了 PATH/PYTHONPATH/PYTHONHOME。
只在需要它的工具（yosys、openFPGALoader）时才 source，用完尽快切回。

### 坑 10: prjxray fasm2frames 缺少 Python 依赖

**现象**：`ModuleNotFoundError: No module named 'simplejson'`（以及 numpy、intervaltree 等）

**原因**：prjxray 有 `requirements.txt`，但 `pip3 install -e` 被安全策略阻止。
单独 `pip3 install fasm` 只装了 fasm 核心包，不包括 prjxray 的其他依赖。

**解决**：
```bash
pip3 install simplejson numpy pyyaml intervaltree ordered-set textx
```

### 坑 1-8

见 `docs/SOP-macos-fpga-toolchain.md` 第 9 节。

---

## 硬件信息

- 开发板：Digilent Arty A7-35T
- FPGA 芯片：Xilinx Artix-7 XC7A35T-1CSG324 (CSG324, 324脚 BGA)
- 逻辑单元：33,280 LUTs / 41,600 FFs / 90 DSP / 1,800Kb BRAM
- 时钟：100MHz 晶振 (E3)
- USB-JTAG：FTDI FT2232HQ（板载）
- 4 LED (H5, J5, T9, T10) · 4 RGB LED · 4 开关 · 4 按钮 · 4 Pmod · Eth · DDR3

详细引脚表 → `docs/hardware-reference.md`

## 工具链架构

```
Verilog 源码
      │
      ▼
┌──────────┐  Yosys 0.66       综合: synth_xilinx -arch xc7
│  Yosys   │  (oss-cad-suite)  Verilog → JSON
└────┬─────┘
     │ JSON
     ▼
┌──────────┐  nextpnr-xilinx   布局布线
│ nextpnr  │  0.8.2 (源码编译) JSON → FASM
└────┬─────┘
     │ FASM
     ▼
┌──────────┐  fasm2frames      Python (系统 python3)
│ prjxray  │  xc7frames2bit    C++ (源码编译)
└────┬─────┘
     │ .bit
     ▼
┌──────────┐  openFPGALoader   烧录到板子
│ 烧录     │  1.1.1            openFPGALoader -b arty
└──────────┘
```

## 目录结构

```
fpga/
├── CLAUDE.md                   ← 项目文档（本文件）
├── .gitignore
├── hardware/
│   ├── arty-a7-35t.xdc        ← XDC 约束（时钟+LED 已启用）
│   └── arty-a7-35t-top.v      ← 顶层 Verilog 模板
├── docs/
│   ├── arty-a7-reference-manual.mhtml  ← 官方参考手册（板子照片+标注）
│   ├── hardware-reference.md           ← 引脚速查卡
│   └── SOP-macos-fpga-toolchain.md     ← 工具链创建 SOP
├── tools/
│   ├── env.sh                  ← 环境脚本
│   ├── setup_all.sh            ← 一键安装
│   ├── oss-cad-suite/          ← [gitignore] 1.8GB
│   ├── nextpnr-xilinx-src/     ← [gitignore] 1.3GB
│   └── prjxray/                ← [gitignore] 219MB
└── projects/
    └── led-demo/               ← 验证通过的示例工程
        ├── top.v               ← LED0+LED3 亮
        ├── arty.xdc            ← 4 LED 约束
        └── build_and_flash.sh  ← 一键脚本
```

## 环境激活

```bash
source tools/env.sh
```

env.sh 会按需加载：
- oss-cad-suite 环境（yosys, openFPGALoader）
- nextpnr-xilinx 路径
- prjxray Python 路径（用系统 python3 而非 oss-cad-suite 的）
- chipdb 和 prjxray-db 路径

## 已验证的示例工程

`projects/led-demo/` — 最简示例，LED0 和 LED3 常亮：

```verilog
module top (output wire [3:0] led);
    assign led[0] = 1'b1;
    assign led[1] = 1'b0;
    assign led[2] = 1'b0;
    assign led[3] = 1'b1;
endmodule
```

一键跑通：`bash projects/led-demo/build_and_flash.sh`

## 参考资源

- https://github.com/YosysHQ/oss-cad-suite-build
- https://github.com/openXC7/nextpnr-xilinx
- https://github.com/f4pga/prjxray
- https://github.com/trabucayre/openFPGALoader
- https://digilent.com/reference/programmable-logic/arty-a7/start

---

*最后更新: 2026-07-03*
