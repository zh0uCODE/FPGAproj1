// ============================================================
// Arty A7-35T 顶层 Verilog 模板
// FPGA: XC7A35T-1CSG324C · 100MHz · LVCMOS33
//
// 用法:
//   1. 复制此文件到你的工程目录
//   2. 删掉不需要的端口
//   3. 在 user_logic 模块里写你的逻辑
//   4. 配合 hardware/arty-a7-35t.xdc 使用
// ============================================================

module arty_top (
    // ---- 时钟与复位 ----
    input  wire       clk,            // 100MHz 系统时钟 (E3)

    // ---- 单色 LED ----
    output wire [3:0] led,            // LD4-LD7 (H5, J5, T9, T10)

    // ---- RGB LED（取消注释以启用）----
    // output wire       led0_r, led0_g, led0_b,
    // output wire       led1_r, led1_g, led1_b,
    // output wire       led2_r, led2_g, led2_b,
    // output wire       led3_r, led3_g, led3_b,

    // ---- 拨码开关（取消注释以启用）----
    // input  wire [3:0] sw,

    // ---- 按钮（取消注释以启用）----
    // input  wire [3:0] btn,

    // ---- USB-UART（取消注释以启用）----
    // output wire       uart_tx,       // FPGA → PC (D10)
    // input  wire       uart_rx,       // PC → FPGA (A9)

    // ---- Pmod JA（取消注释以启用）----
    // inout  wire [7:0] ja,

    // ---- Pmod JB ----
    // inout  wire [7:0] jb,

    // ---- Pmod JC ----
    // inout  wire [7:0] jc,

    // ---- Pmod JD ----
    // inout  wire [7:0] jd

    // ---- 更多外设见 hardware/arty-a7-35t.xdc ----
);

    // ============================================================
    // 用户逻辑实例化
    //   在这里连线你的实际模块
    // ============================================================

    // 简单示例：LED 闪烁
    // 如果你的项目不需要 clk/led，删掉下面的代码即可
    reg [25:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign led[0] = counter[25];       // ~0.75Hz
    assign led[1] = counter[24];       // ~1.5Hz
    assign led[2] = counter[23];       // ~3Hz
    assign led[3] = counter[22];       // ~6Hz

endmodule
