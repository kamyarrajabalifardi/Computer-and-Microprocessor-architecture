`timescale 1ns/100ps
module fp_adder(
input [31:0]a,
input [31:0]b,
output[31:0]s
);
wire [7:0]exp_A,exp_B;
wire sign_A,sign_B;
wire [27:0]modified_frac_A,modified_frac_B; 
wire [7:0]modified_exp_A,modified_exp_B;
wire [7:0]exponent_difference;
wire [8:0]temp_frac; 
wire [27:0]left_frac,right_frac;
wire [27:0]modified_left_frac;
wire [7:0]exp_ans;
wire [28:0]add_ans;
wire [7:0]modified_exp_ans;
wire [4:0]msb_loc;
wire [24:0]part_add_ans;
wire [23:0]frac;
wire [7:0]modified_modified_exp_ans;

assign exp_A = a[30:23];
assign exp_B = b[30:23];
assign sign_A = a[31];
assign sign_B = b[31];
assign modified_frac_A = (exp_A==0) ? {sign_A,1'b0,a[22:0],3'b000} : {sign_A,1'b1,a[22:0],3'b000};
assign modified_frac_B = (exp_B==0) ? {sign_B,1'b0,b[22:0],3'b000} : {sign_B,1'b1,b[22:0],3'b000};
assign modified_exp_A = (exp_A==0) ? 1 : exp_A ;
assign modified_exp_B = (exp_B==0) ? 1 : exp_B ;
assign temp_frac = modified_exp_A + ~modified_exp_B + 1; // chap - rast
assign exponent_difference =(temp_frac[8]==0) ? temp_frac[7:0] : ~temp_frac[7:0] + 1;
assign left_frac = (temp_frac[8]==0) ? modified_frac_B: modified_frac_A;//check it
assign right_frac = (temp_frac[8]==1) ? modified_frac_B : modified_frac_A;//check it
assign exp_ans = (temp_frac[8]==1)? modified_exp_B : modified_exp_A; //doubt
 
sticky_bit uut1(
.a(left_frac[27:1]),
.b(exponent_difference),
.result(modified_left_frac)
);

leading_one_detector uut2(
.A(modified_left_frac),
.B(right_frac),
.exponent(exp_ans),
.modified__exponent(modified_exp_ans),
.msb__loc(msb_loc),
.shift__ans(add_ans)
);

rounding uut3(
.A(add_ans),
.msb_loc(msb_loc),
.B(part_add_ans)
);

assign frac = (part_add_ans[24]==1) ? part_add_ans[24:1] : part_add_ans[23:0];
assign modified_modified_exp_ans = (part_add_ans[24]==1) ? modified_exp_ans+1 : modified_exp_ans;
assign s[31] = add_ans[28];
assign s[30:23] = (frac[23]==0)? 0:modified_modified_exp_ans;
assign s[22:0] = frac[22:0];

endmodule
