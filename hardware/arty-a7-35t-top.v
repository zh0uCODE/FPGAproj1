// ============================================================
// Arty A7-35T Top-Level Verilog Template
// FPGA: XC7A35T-1CSG324C · 100MHz · LVCMOS33
//
// Usage:
//   1. Copy this file into your project directory
//   2. Delete the ports you don't need
//   3. Write your logic in the user_logic section
//   4. Use together with hardware/arty-a7-35t.xdc
// ============================================================

module arty_top (
    // ---- Clock & reset ----
    input  wire       clk,            // 100MHz system clock (E3)

    // ---- Monochrome LEDs ----
    output wire [3:0] led,            // LD4-LD7 (H5, J5, T9, T10)

    // ---- RGB LEDs (uncomment to enable) ----
    // output wire       led0_r, led0_g, led0_b,
    // output wire       led1_r, led1_g, led1_b,
    // output wire       led2_r, led2_g, led2_b,
    // output wire       led3_r, led3_g, led3_b,

    // ---- Slide switches (uncomment to enable) ----
    // input  wire [3:0] sw,

    // ---- Push buttons (uncomment to enable) ----
    // input  wire [3:0] btn,

    // ---- USB-UART (uncomment to enable) ----
    // output wire       uart_tx,       // FPGA → PC (D10)
    // input  wire       uart_rx,       // PC → FPGA (A9)

    // ---- Pmod JA (uncomment to enable) ----
    // inout  wire [7:0] ja,

    // ---- Pmod JB ----
    // inout  wire [7:0] jb,

    // ---- Pmod JC ----
    // inout  wire [7:0] jc,

    // ---- Pmod JD ----
    // inout  wire [7:0] jd

    // ---- See hardware/arty-a7-35t.xdc for more peripherals ----
);

    // ============================================================
    // User logic instantiation
    //   Wire up your actual modules here
    // ============================================================

    // Simple example: LED blinker
    // If your project doesn't need clk/led, just delete the code below
    reg [25:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign led[0] = counter[25];       // ~0.75Hz
    assign led[1] = counter[24];       // ~1.5Hz
    assign led[2] = counter[23];       // ~3Hz
    assign led[3] = counter[22];       // ~6Hz

endmodule
