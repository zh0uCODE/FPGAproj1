## final_8: 4 switches in, seg[6:0] out to Pmod SSD straddling JA and JB
##
## The Pmod SSD has two 6-pin headers: J1 (AA-AD, GND, VCC) plugs into the
## TOP ROW of JA, and J2 (AE, AF, AG, CAT, GND, VCC) plugs into the TOP ROW
## of JB. So four of the signals live on JB pins 1-4, not JA's bottom row.
##
## The display glyphs are mounted 180 deg rotated as viewed on the Arty
## (decimal points sit top-left), so each module signal lights the segment
## diametrically opposite its name: AA = viewed bottom, AD = viewed top,
## AB = viewed lower-left, etc. The assignments below bake in both the
## JA/JB split and that rotation.
##
## top.v numbers segments 1-7 bottom-to-top (seg[0..6] = viewed D,C,E,G,B,F,A).
## If a segment still lights in the wrong position, permute these pin
## assignments rather than the top.v table.

## Switches (A2=SW3, A1=SW2, B2=SW1, B1=SW0)
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports { A2 }];
set_property -dict { PACKAGE_PIN C10   IOSTANDARD LVCMOS33 } [get_ports { A1 }];
set_property -dict { PACKAGE_PIN C11   IOSTANDARD LVCMOS33 } [get_ports { B2 }];
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { B1 }];

## Seven-segment outputs (viewed position -> module signal -> FPGA pin)
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { seg[0] }];  # viewed D (bottom)      -> AA -> JA1
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { seg[1] }];  # viewed C (lower-right) -> AF -> JB2
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { seg[2] }];  # viewed E (lower-left)  -> AB -> JA2
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { seg[3] }];  # viewed G (middle)      -> AG -> JB3
set_property -dict { PACKAGE_PIN E15   IOSTANDARD LVCMOS33 } [get_ports { seg[4] }];  # viewed B (upper-right) -> AE -> JB1
set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { seg[5] }];  # viewed F (upper-left)  -> AC -> JA3
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { seg[6] }];  # viewed A (top)         -> AD -> JA4

## Pmod SSD digit select (CAT on the module's J2 pin 4 = JB4, NOT JA10):
## picks which of the two digits is lit. top.v drives it constant.
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { C }];
