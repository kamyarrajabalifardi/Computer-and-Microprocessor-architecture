`timescale 1ns/1ns
module fp_mult(
input clk,
input start,
input [31:0] A,
input [31:0] B,
output [31:0] C,
output ready
);

wire sign_A, sign_B, sign_C;
wire [7:0] exp_A, exp_B, exp_C;
wire [22:0] frac_A, frac_B, frac_C;
wire [23:0] sig_A, sig_B, sig_C;

wire sticky_bit;
wire [7:0] exp_add, exp_add2, exp_add3;
wire [47:0] sig_mult;
wire [48:0] shifted_sig_mult, extended_sig_mult; //changed
wire [5:0] msb_loc, msb_shift;
wire [25:0] sig_ans, sig_ans2, sig_ans3;
// initial assigning
assign sign_A = A[31];
assign sign_B = B[31];
assign exp_A = A[30:23];
assign exp_B = B[30:23];
assign frac_A = A[22:0];
assign frac_B = B[22:0];
assign sig_A = (exp_A == 0) ? {1'b0, frac_A} : {1'b1, frac_A};
assign sig_B = (exp_B == 0) ? {1'b0, frac_B} : {1'b1, frac_B};

assign sign_C = !(sign_A == sign_B);
assign exp_add = exp_A + exp_B - 127;
//assign sig_mult = sig_A * sig_B;
assign extended_sig_mult = {sig_mult,1'b0};
//assign msb_shift = 48 - msb_loc;
assign exp_add2 = (msb_loc == 48) ? exp_add + 1 : (msb_loc == 47) ? exp_add : exp_add + (msb_loc - 46);
assign shifted_sig_mult = (msb_loc == 48) ? extended_sig_mult >> 1 : (msb_loc == 47) ? extended_sig_mult : extended_sig_mult << (47 - msb_loc);
assign sig_ans = {1'b0 , shifted_sig_mult[47:23]};
assign sticky_bit = |(shifted_sig_mult[22:0]);
assign sig_ans2 = (shifted_sig_mult[23] == 0) ? sig_ans : (sticky_bit == 1) ? sig_ans + 1 : sig_ans + sig_ans[0];
assign sig_ans3 = (sig_ans2[25] == 1) ? sig_ans2 >> 1 : sig_ans2;
assign exp_add3 = (sig_ans2[25] == 1) ? exp_add2 + 1 : exp_add2;

assign frac_C = sig_ans3[23:1];
assign exp_C = exp_add3;
assign C = {sign_C, exp_C, frac_C};


leading_one lo(
.A(extended_sig_mult),
.msb_loc(msb_loc)
);

unsigned_multiplier #(.nb(24)) ufpm (
.A(sig_A),
.B(sig_B),
.Product(sig_mult),
.clk(clk),
.start(start),
.ready(ready)
);
endmodule