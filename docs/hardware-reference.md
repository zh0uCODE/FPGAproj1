# Arty A7-35T Hardware Reference Card

> Digilent Arty A7-35T (Rev. D/E) · Xilinx Artix-7 XC7A35T-1CSG324C · 33280 LUTs · 100MHz OSC

---

## 1. On-Board Basic I/O

### System Clock

| Signal | FPGA Pin | Frequency | I/O Standard |
|------|----------|------|---------|
| `CLK100MHZ` | **E3** | 100 MHz | LVCMOS33 |

### Push Buttons (4, high when pressed)

| Signal | FPGA Pin | Board Silkscreen |
|------|----------|---------|
| `btn[0]` | **D9** | BTN0 (rightmost) |
| `btn[1]` | **C9** | BTN1 |
| `btn[2]` | **B9** | BTN2 |
| `btn[3]` | **B8** | BTN3 (leftmost) |

### Switches (4, high when up)

| Signal | FPGA Pin | Board Silkscreen |
|------|----------|---------|
| `sw[0]` | **A8** | SW0 (rightmost) |
| `sw[1]` | **C11** | SW1 |
| `sw[2]` | **C10** | SW2 |
| `sw[3]` | **A10** | SW3 (leftmost) |

### Monochrome LEDs (4, active-high)

| Signal | FPGA Pin | Color | Silkscreen |
|------|----------|------|------|
| `led[0]` | **H5** | Green | LD4 |
| `led[1]` | **J5** | Green | LD5 |
| `led[2]` | **T9** | Green | LD6 |
| `led[3]` | **T10** | Green | LD7 |

### RGB LEDs (4, with 12 independently controlled bits)

| LED # | Red R | Green G | Blue B |
|----------|------|------|------|
| LD0 | G6 | F6 | E1 |
| LD1 | G3 | J4 | G4 |
| LD2 | J3 | J2 | H4 |
| LD3 | K1 | H6 | K2 |

### USB-UART

| Signal | FPGA Pin | Direction |
|------|----------|------|
| `uart_rxd_out` | **D10** | FPGA → PC (TX) |
| `uart_txd_in` | **A9** | PC → FPGA (RX) |

> ⚠️ Watch the naming: `uart_rxd_out` is an FPGA-side output (sent to the PC via the FTDI chip), `uart_txd_in` is an FPGA-side input (from the PC).

---

## 2. Pmod Expansion Connectors

> 4 Pmod headers, 8 bits each. 2.54mm pitch, compatible with standard Pmod peripherals.

### Pmod JA (top-right of the board)

| Bit | FPGA Pin |
|----|----------|
| `ja[0]` | G13 |
| `ja[1]` | B11 |
| `ja[2]` | A11 |
| `ja[3]` | D12 |
| `ja[4]` | D13 |
| `ja[5]` | B18 |
| `ja[6]` | A18 |
| `ja[7]` | K16 |

### Pmod JB (top-right, inner)

| Bit | FPGA Pin |
|----|----------|
| `jb[0]` | E15 |
| `jb[1]` | E16 |
| `jb[2]` | D15 |
| `jb[3]` | C15 |
| `jb[4]` | J17 |
| `jb[5]` | J18 |
| `jb[6]` | K15 |
| `jb[7]` | J15 |

### Pmod JC (bottom of the board, left)

| Bit | FPGA Pin |
|----|----------|
| `jc[0]` | U12 |
| `jc[1]` | V12 |
| `jc[2]` | V10 |
| `jc[3]` | V11 |
| `jc[4]` | U14 |
| `jc[5]` | V14 |
| `jc[6]` | T13 |
| `jc[7]` | U13 |

### Pmod JD (bottom of the board, right)

| Bit | FPGA Pin |
|----|----------|
| `jd[0]` | D4 |
| `jd[1]` | D3 |
| `jd[2]` | F4 |
| `jd[3]` | F3 |
| `jd[4]` | E2 |
| `jd[5]` | D2 |
| `jd[6]` | H2 |
| `jd[7]` | G2 |

---

## 3. Arduino / ChipKIT Interface

### SPI

| Signal | FPGA Pin |
|------|----------|
| `ck_miso` | G1 |
| `ck_mosi` | H1 |
| `ck_sck` | F1 |
| `ck_ss` | C1 |

### I2C

| Signal | FPGA Pin |
|------|----------|
| `ck_scl` | L18 |
| `ck_sda` | M18 |

### Digital I/O (30 bits total)

| Group | Signal Range | Pins |
|----|---------|------|
| Outer digital | `ck_io[0]` ~ `ck_io[13]` | V15, U16, P14, T11, R12, T14, T15, T16, N15, M16, V17, U18, R17, P17 |
| Inner digital | `ck_io[26]` ~ `ck_io[41]` | U11, V16, M13, R10, R11, R13, R15, P15, R16, N16, N14, U17, T18, R18, P18, N17 |

### Analog / Digital Shared Pins

| ChipKit Pin | Digital Mode | Analog Mode |
|-----------|---------|---------|
| A0 | `ck_a0` (F5) | `vaux4` (C6/C5) |
| A1 | `ck_a1` (D8) | `vaux5` (A6/A5) |
| A2 | `ck_a2` (C7) | `vaux6` (C4/B4) |
| A3 | `ck_a3` (E7) | `vaux7` (B1/A1) |
| A4 | `ck_a4` (D7) | `vaux15` (B3/B2) |
| A5 | `ck_a5` (D5) | `vaux0` (D14/C14) |
| A6 | `ck_a6` (B7) | `vaux12` (B7/B6) |
| A7 | `ck_a7` (B6) | `vaux12` (B6/B7) |
| A8 | `ck_a8` (E6) | `vaux13` (E6/E5) |
| A9 | `ck_a9` (E5) | `vaux13` (E5/E6) |
| A10 | `ck_a10` (A4) | `vaux14` (A4/A3) |
| A11 | `ck_a11` (A3) | `vaux14` (A3/A4) |

> ⚠️ Analog and digital modes **cannot be used at the same time** on the same pin.

### Other ChipKIT Signals

| Signal | FPGA Pin | Function |
|------|----------|------|
| `ck_ioa` | M17 | IO multiplexed |
| `ck_rst` | C2 | Reset |

---

## 4. On-Board Peripherals

### Ethernet (SMSC LAN8720A PHY, RMII)

| Signal | FPGA Pin | Direction |
|------|----------|------|
| `eth_ref_clk` | G18 | Input (50MHz) |
| `eth_rstn` | C16 | Output (reset, active-low) |
| `eth_mdc` | F16 | Output (MDIO clock) |
| `eth_mdio` | K13 | Bidirectional (MDIO data) |
| `eth_rx_clk` | F15 | Input |
| `eth_rx_dv` | G16 | Input (data valid) |
| `eth_rxd[0:3]` | D18, E17, E18, G17 | Input |
| `eth_rxerr` | C17 | Input |
| `eth_tx_clk` | H16 | Input |
| `eth_tx_en` | H15 | Output |
| `eth_txd[0:3]` | H14, J14, J13, H17 | Output |
| `eth_col` | D17 | Input |
| `eth_crs` | G14 | Input |

### QSPI Flash (Spansion S25FL128S, 16MB)

| Signal | FPGA Pin | Function |
|------|----------|------|
| `qspi_cs` | L13 | Chip select |
| `qspi_dq[0]` | K17 | IO0 (MOSI) |
| `qspi_dq[1]` | K18 | IO1 (MISO) |
| `qspi_dq[2]` | L14 | IO2 (WP#) |
| `qspi_dq[3]` | M14 | IO3 (HOLD#) |

### DDR3 (Micron MT41K128M16JT-125, 256MB)

> DDR3 has many pins; see the dedicated DDR3 constraint file. The MIG IP core generates them automatically.

---

## 5. FPGA Chip Summary

| Parameter | Value |
|------|-----|
| Part number | XC7A35T-1CSG324C |
| Package | CSG324 (324-pin BGA, 0.8mm) |
| Logic cells | 33,280 LUTs |
| Flip-flops | 41,600 FFs |
| Block RAM | 1,800 Kb (50 × 36Kb blocks) |
| DSP48E1 | 90 |
| PLL/MMCM | 5 MMCM + 5 PLL |
| Max user I/O | 210 |
| Speed grade | -1 |

---

## 6. Hardware Configuration

| Item | Setting |
|--------|------|
| Boot mode (JP1) | JTAG + QSPI |
| Clock source | 100MHz crystal (ASE-100.000MHZ-LR-T) |
| Power input | USB (J10) or 7-15V DC (J13) |
| Configuration | JTAG (on-board FT2232H) |
| Program storage | QSPI Flash (16MB), auto-load at power-up |

---

## 7. Jumper Settings

| Jumper | Default | Function |
|------|------|------|
| JP1 (MODE) | JTAG | Configuration mode select |
| JP2 | Closed | VCCIO3 set to 3.3V |
| JP3/JP4/JP5 | — | XADC reference voltage / analog input |

---

*References: Digilent Arty A7 Reference Manual · GitHub: digilent-xdc · Compiled on 2026-07-03*
