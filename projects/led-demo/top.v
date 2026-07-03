// LED Demo: LED0 和 LED3 亮，LED1 和 LED2 灭
module top (
    output wire [3:0] led
);
    assign led[0] = 1'b1;  // 亮
    assign led[1] = 1'b0;  // 灭
    assign led[2] = 1'b0;  // 灭
    assign led[3] = 1'b1;  // 亮
endmodule
