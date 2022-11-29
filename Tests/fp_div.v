`timescale 1ns/1ns
module fp_div( // calculates A/B
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

wire [7:0] exp_diff, exp_diff_2;
wire [4:0] shift_A, shift_B, posone_A, posone_B;
wire [23:0] shifted_sig_A, shifted_sig_B;
wire [25:0] sig_C_1;
wire [24:0] sig_C_2;
wire [24:0] sig_C_3;
wire rc;

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
assign exp_diff = exp_A - exp_B;
assign shift_A = 23 - posone_A;
assign shift_B = 23 - posone_B;
assign shifted_sig_A = (shift_A) ? sig_A << shift_A : sig_A;
assign shifted_sig_B = (shift_B) ? sig_B << shift_B : sig_B;
assign sig_C_2 = (sig_C_1[25] == 1) ? sig_C_1[25:1] : sig_C_1[24:0];
assign exp_diff_2 = (sig_C_1[25]) ? exp_diff + shift_B - shift_A : exp_diff + shift_B - shift_A - 1;
assign sig_C_3 = sig_C_2[0] ? (rc ? sig_C_2[24:1] + 1 : sig_C_2[24:1] + sig_C_2[1]) : sig_C_2[24:1];
assign sig_C = sig_C_3[24] ? sig_C_3[24:1] : sig_C_3[23:0];
assign exp_C = sig_C_3[24] ? exp_diff_2 + 128 : exp_diff_2 + 127;
assign frac_C = sig_C[22:0];

assign C = {sign_C,exp_C,frac_C};

leading_one_div lo1(
.A(sig_A),
.msb_loc(posone_A)
);
leading_one_div lo2(
.A(sig_B),
.msb_loc(posone_B)
);
unsigned_fractional_divider ufd_fp(
.clk(clk),
.start(start),
.a(shifted_sig_A),
.b(shifted_sig_B),
.q(sig_C_1),
.ready(ready),
.Reminder(rc)
);
endmodule