// LED Demo: LED0 and LED3 on, LED1 and LED2 off
module top (
    output wire [3:0] led
);
    assign led[0] = 1'b1;  // on
    assign led[1] = 1'b0;  // off
    assign led[2] = 1'b0;  // off
    assign led[3] = 1'b1;  // on
endmodule
