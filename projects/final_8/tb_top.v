`timescale 1ns/1ps
// Testbench for the 4-to-16 decoder (2-bit x 2-bit -> seven-segment).
// Sweeps all 16 input combinations, prints seg for each, and dumps a VCD
// waveform for GTKWave. It does not judge pass/fail -- check the printed
// patterns against your case table in top.v.
module tb_top;
    reg A2, A1, B2, B1;
    wire [6:0] seg;
    integer i;

    top dut (
        .A2  (A2),
        .A1  (A1),
        .B2  (B2),
        .B1  (B1),
        .seg (seg)
    );

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        $display("  A2 A1 B2 B1 |   seg[6:0]");
        $display("  ------------+-----------");
        for (i = 0; i < 16; i = i + 1) begin
            {A2, A1, B2, B1} = i[3:0];
            #10;
            $display("   %b  %b  %b  %b | %b", A2, A1, B2, B1, seg);
        end

        $finish;
    end
endmodule
