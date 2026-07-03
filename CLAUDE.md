# FPGA 开源工具链 — Digilent Arty A7-35T

## 项目概述

在 MacBook (Apple Silicon, macOS 15.5) 上搭建一套**完全免费、开源**的 FPGA 开发工具链，
目标是让 **Digilent Arty A7-35T**（Xilinx Artix-7 XC7A35T-1CSG324）能够跑通完整的
数字逻辑设计流程：Verilog → 综合 → 布局布线 → 生成比特流 → 烧录到板子。

所有工具安装在项目目录下，打包即可带走，实现便携化。

## 用户偏好

- 用户说"打开开发板资料"或类似表述时，用 `open` 命令在浏览器中打开：
  `open docs/arty-a7-reference-manual.mhtml`
- 全程用中文交流

## 硬件信息

- 开发板：Digilent Arty A7-35T
- FPGA 芯片：Xilinx Artix-7 XC7A35T-1CSG324
- 封装：CSG324（324 引脚 BGA）
- 逻辑单元：33,280 个 LUT
- 板载 100MHz 时钟
- USB-JTAG：FTDI FT2232HQ（板载，无需额外下载器）

## 工具链架构

开源 FPGA 工具链（针对 Xilinx 7 系列）由四个组件构成完整流程：

```
Verilog/VHDL 源码
      │
      ▼
┌─────────────┐
│   Yosys     │  RTL 综合 (Synthesis)
│   v0.66     │  Verilog → JSON 网表
└──────┬──────┘
       │  JSON netlist
       ▼
┌─────────────┐
│ nextpnr-    │  布局布线 (Place & Route)
│ xilinx      │  JSON → FASM (FPGA Assembly)
│  v0.8.2     │  需要芯片数据库 (chipdb)
└──────┬──────┘
       │  FASM file
       ▼
┌─────────────┐
│  prjxray    │  比特流生成
│  tools      │  FASM → frames → .bit 文件
└──────┬──────┘
       │  .bit file
       ▼
┌─────────────┐
│ openFPGA    │  烧录到板子
│ Loader      │  通过板载 USB-JTAG
│  v1.1.1     │
└─────────────┘
```

## 各组件详情

| 组件 | 版本 | 许可证 | 磁盘占用 | 说明 |
|------|------|--------|---------|------|
| **Yosys** | 0.66+181 | ISC | ~50MB | RTL 综合，`synth_xilinx -arch xc7` |
| **nextpnr-xilinx** | 0.8.2-81 | ISC | ~2.6MB | 布局布线，从源码编译 |
| **prjxray-db** | git HEAD | CC0 | ~724MB | Artix-7 比特流数据库 |
| **chipdb (xc7a35t.bin)** | 生成 | - | ~?MB | 从 prjxray-db 编译的芯片数据库 |
| **openFPGALoader** | 1.1.1 | Apache 2.0 | ~5MB | 烧录，支持 `-b arty` |
| **prjxray (Python)** | git HEAD | ISC | ~20MB | fasm2frames, xc7frames2bit |

oss-cad-suite 附加工具：
- iverilog, Verilator — Verilog 仿真
- GTKWave — 波形查看
- SymbiYosys — 形式验证
- Amaranth — Python-based HDL 框架

```
fpga/
├── CLAUDE.md               ← 项目文档（Claude Code 自动读取）
├── .gitignore              ← Git 忽略规则
├── hardware/               ← 板级硬件描述文件
│   ├── arty-a7-35t.xdc    ← 完整 XDC 约束（时钟/LED 已启用，其余注释备用）
│   └── arty-a7-35t-top.v  ← 顶层 Verilog 模板（可直接用）
├── docs/
│   ├── SOP-macos-fpga-toolchain.md  ← 工具链创建 SOP（踩坑 + 一键脚本）
│   └── hardware-reference.md        ← 硬件参考卡（所有引脚速查表）
├── tools/
│   ├── env.sh              ← 环境脚本（source 一下激活全部工具）
│   ├── setup_all.sh        ← 一键安装脚本
│   ├── oss-cad-suite/      ← Yosys + 仿真 + openFPGALoader (1.8GB, gitignore 排除)
│   ├── nextpnr-xilinx-src/ ← 布局布线 + 芯片数据库 (1.3GB, gitignore 排除)
│   └── prjxray/            ← 比特流工具 (219MB, gitignore 排除)
└── projects/               ← 你的 FPGA 工程
    └── blinky/             ← 测试工程

## 安装步骤

### 前提条件

确保系统装有：
```bash
# Xcode Command Line Tools（含 clang, make 等）
xcode-select --install

# Homebrew（包管理器）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 编译依赖
brew install cmake boost eigen
```

### 一键安装

```bash
cd /Users/yizhou/ece/fpga
bash tools/setup_all.sh
```

这个脚本会：
1. 从 prjxray-db 生成芯片数据库（xc7a35t.bin）
2. 克隆并安装 prjxray Python 工具（fasm2frames, xc7frames2bit）
3. 验证所有工具可用

### nextpnr-xilinx 编译细节（记录备忘）

之前在 macOS + Apple Clang 17 上编译 nextpnr-xilinx 遇到的问题和解决方法：

| 问题 | 解决方案 |
|------|---------|
| Apple Clang 不支持 `-fopenmp` | `-DUSE_OPENMP=OFF` |
| 找不到 Boost::Python 3.x | `-DBUILD_PYTHON=OFF`（Python 工具可独立运行） |
| 找不到 Eigen3 | `-DEigen3_DIR=/opt/homebrew/share/eigen3/cmake -DCMAKE_CXX_FLAGS="-I/opt/homebrew/include/eigen3"` |

完整的 cmake 命令：
```bash
cmake -DARCH=xilinx \
    -DBUILD_GUI=OFF \
    -DBUILD_PYTHON=OFF \
    -DUSE_OPENMP=OFF \
    -DEigen3_DIR=/opt/homebrew/share/eigen3/cmake \
    -DCMAKE_CXX_FLAGS="-I/opt/homebrew/include/eigen3" \
    ..
make -j8
```

## 日常使用

### 激活环境

```bash
source tools/env.sh
```

### 开发流程

#### 1. 写 Verilog

```verilog
// projects/blinky/blinky.v
module top (
    input  wire clk,
    output wire led
);
    reg [25:0] counter = 0;
    always @(posedge clk) counter <= counter + 1;
    assign led = counter[25];  // 100MHz / 2^26 ≈ 0.75 Hz
endmodule
```

#### 2. 写约束文件 (XDC)

```tcl
# projects/blinky/arty.xdc
# 时钟
set_property PACKAGE_PIN E3  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

# LED 0
set_property PACKAGE_PIN H5  [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]

# LED 1-3（Arty A7 有 4 个 LED）
# set_property PACKAGE_PIN J5  [get_ports {led[1]}]
# set_property PACKAGE_PIN T9  [get_ports {led[2]}]
# set_property PACKAGE_PIN T10 [get_ports {led[3]}]
```

#### 3. 综合（Synthesis）

```bash
cd projects/blinky
yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top top; write_json blinky.json" blinky.v
```

#### 4. 布局布线（Place & Route）

```bash
nextpnr-xilinx \
    --chipdb $NEXTPNR_CHIPDB \
    --xdc arty.xdc \
    --json blinky.json \
    --write blinky_routed.json \
    --fasm blinky.fasm
```

#### 5. 生成比特流

```bash
fasm2frames --part xc7a35tcsg324-1 \
    --db-root $PRJXRAY_DB_DIR/artix7 \
    blinky.fasm > blinky.frames

xc7frames2bit \
    --part_file $PRJXRAY_DB_DIR/artix7/xc7a35tcsg324-1/part.yaml \
    --part_name xc7a35tcsg324-1 \
    --frm_file blinky.frames \
    --output_file blinky.bit
```

#### 6. 烧录到板子

```bash
# 烧到 SRAM（掉电丢失，调试用）
openFPGALoader -b arty blinky.bit

# 烧到 Flash（掉电保存，可配置为启动源）
openFPGALoader -b arty -f blinky.bit
```

## 开源 vs Vivado 对比

| | 本项目（开源工具链） | Vivado WebPack |
|---|---|---|
| **许可证** | ISC / Apache 2.0 | 专有 (Proprietary) |
| **费用** | 完全免费 | 免费（需注册） |
| **macOS 原生** | ✅ 是 | ❌ 不支持 |
| **磁盘占用** | ~2.5 GB | ~80 GB |
| **综合优化** | 良好 | 最优 |
| **时序约束** | 支持 (SDC → nextpnr) | 完善 |
| **IP 核** | 有限（开源社区） | 丰富（MicroBlaze 等） |
| **学习的透明度** | ⭐⭐⭐⭐⭐ 看源码 | ⭐⭐ 黑盒 |
| **便携性** | ✅ 目录独立，打包即走 | ❌ 需完整安装 |

## 当前状态 (2026-07-03)

全部就绪 ✅

| 组件 | 状态 | 备注 |
|------|------|------|
| Yosys 0.66+181 | ✅ | oss-cad-suite 预编译 |
| nextpnr-xilinx 0.8.2 | ✅ | 源码编译 (macOS arm64) |
| prjxray-db | ✅ | 724MB submodule |
| chipdb (xc7a35t.bin) | ✅ | 88MB，nextpnr 使用 |
| fasm Python 包 | ✅ | pip install fasm |
| prjxray 仓库 | ✅ | 含 fasm2frames |
| xc7frames2bit | ✅ | 746KB，源码编译 |
| openFPGALoader 1.1.1 | ✅ | oss-cad-suite 附带 |
| env.sh | ✅ | 一键激活所有工具 |

## 重建工具链

完整 SOP 文档：**[docs/SOP-macos-fpga-toolchain.md](docs/SOP-macos-fpga-toolchain.md)**

包含：
- 从零搭建的完整步骤
- macOS 上踩过的每一个坑和解决方法
- 一键安装脚本
- 验证清单

## 参考资料

- https://github.com/YosysHQ/oss-cad-suite-build — oss-cad-suite 预编译下载
- https://github.com/YosysHQ/yosys — Yosys RTL 综合器
- https://github.com/openXC7/nextpnr-xilinx — nextpnr Xilinx 后端
- https://github.com/f4pga/prjxray — Project X-Ray 比特流文档化
- https://github.com/trabucayre/openFPGALoader — FPGA 烧录工具
- https://digilent.com/reference/programmable-logic/arty-a7/start — Arty A7 官方文档
- https://www.clifford.at/yosys/ — Yosys 手册

---

*最后更新: 2026-07-03*
