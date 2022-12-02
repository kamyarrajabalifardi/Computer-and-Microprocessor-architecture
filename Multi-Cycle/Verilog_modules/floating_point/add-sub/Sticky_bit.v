/*This module gets a 27 bits number and a number between 1 and 32.The result is a 28 bit number with OR
of discarded numbers(after shifting (b) bits to right) in LSB(sticky bit)*/
`timescale 1ns/100ps
module sticky_bit
(
input [26:0]a,
input [7:0]b,
output [27:0]result
);
wire [25:0]temp_a;
wire [25:0]temp;
wire [25:0]temp1,temp2;
wire bit_sticky;

assign temp_a = a[25:0];
assign temp1 = temp_a>>b;
assign temp2 = temp1 <<b;
assign temp = temp_a - temp2;
assign bit_sticky = (|temp);
assign result = {a[26],temp1, bit_sticky};

endmodule