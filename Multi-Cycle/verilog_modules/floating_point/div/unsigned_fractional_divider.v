`timescale 1ns/1ns
module unsigned_fractional_divider #(parameter ni=23, parameter no = 25)(
input clk,
input start,
input [0:-ni] a,
input [0:-ni] b,
output reg [0:-no] q,
output Reminder,
output ready
);

reg [9:0] counter;
reg [1:-ni] pr;
reg [0:-ni] br;
wire borrow; 
wire [0:-ni] sub;

assign {borrow,sub} = pr - br;
assign ready = !counter;
assign Reminder = |(pr);

always @(posedge clk)
if(start) begin	
	br <= b;
	pr <= a;
	counter <= no + 1;
	q <= 0;
	end
else if(counter) begin
	counter = counter - 1;
	q <= ((q<<1)|(borrow ? 1'b0 : 1'b1));
	pr <= (borrow ? pr : sub) << 1;
	end
endmodule
	