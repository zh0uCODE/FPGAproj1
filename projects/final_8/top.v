module top (
  input wire A2, A1, B2, B1, //bits
  output reg [6:0] seg, //from 1 to 7
  output wire C //output wire
);
assign C = 1'b1; //for the SSD
always @(*) begin //recompute for changes in input
  case ({A2,A1,B2,B1}) //for four bits
  //rows
    4'b0000: seg = 7'b1110111; //D0 - 0
    4'b0001: seg = 7'b1110111; //D1 - 0
    4'b0010: seg = 7'b1110111; //D2 - 0
    4'b0011: seg = 7'b1110111; //D3 - 0
    4'b0100: seg = 7'b1110111; //D4 - 0
    4'b0101: seg = 7'b0010010; //D5 - 1
    4'b0110: seg = 7'b1011101; //D6 - 2
    4'b0111: seg = 7'b1011011; //D7 - 3
    4'b1000: seg = 7'b1110111; //D8 - 0
    4'b1001: seg = 7'b1011101; //D9 - 2
    4'b1010: seg = 7'b0111010; //D10 - 4
    4'b1011: seg = 7'b1101111; //D11 - 6
    4'b1100: seg = 7'b1110111; //D12 - 0
    4'b1101: seg = 7'b1011011; //D13 - 3
    4'b1110: seg = 7'b1101111; //D14 - 6
    4'b1111: seg = 7'b1111011; //D15 - 9
    default: seg = 7'b0000000; //do nothing - default
  endcase //end
end
endmodule

 
