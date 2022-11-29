/*this module get two 28 bit sign & magnitude numbers and add them.it also get exponent of
bigger number(manzooram ooni ke samte raste madare).The output is a 29 bit sign and magnitude
number and it is normalized.The other output is exponent after normalization*/
`timescale 1ns/100ps
module leading_one_detector
(
  input [27:0]A,
  input [27:0]B,
  input [7:0]exponent,
  output [4:0]msb__loc,
  output [7:0]modified__exponent,
  output [28:0]shift__ans  
);
  wire signed[27:0]modified__A;
  wire signed[27:0]modified__B;
  wire signed[28:0]ans;
  wire [28:0]simag__ans;
  wire [28:0]simag__ans2;
  
  assign modified__A = (A[27]==1) ? {A[27],~A[26:0]+1} : A ;
  assign modified__B = (B[27]==1) ? {B[27],~B[26:0]+1} : B ;
  assign ans = modified__A + modified__B;
  assign simag__ans = (ans[28]==1) ? {ans[28],~ans[27:0]+1}: ans ;
  assign msb__loc = (simag__ans[27]==1) ? 27 : (simag__ans[26]==1) ? 26 : (simag__ans[25]==1) ? 25 : (simag__ans[24]==1) ? 24 : (simag__ans[23]==1) ? 23 : (simag__ans[22]==1) ? 22 : (simag__ans[21]==1) ? 21 : (simag__ans[20]==1) ? 20 : (simag__ans[19]==1) ? 19 : (simag__ans[18]==1) ? 18 : (simag__ans[17]==1) ? 17 : (simag__ans[16]==1) ? 16 : (simag__ans[15]==1) ? 15 : (simag__ans[14]==1) ? 14 : (simag__ans[13]==1) ? 13 : (simag__ans[12]==1) ? 12 : (simag__ans[11]==1) ? 11 : (simag__ans[10]==1) ? 10 : (simag__ans[9]==1) ? 9 : (simag__ans[8]==1) ? 8 : (simag__ans[7]==1) ? 7 : (simag__ans[6]==1) ? 6 : (simag__ans[5]==1) ? 5 : (simag__ans[4]==1) ? 4 : (simag__ans[3]==1) ? 3 : (simag__ans[2]==1) ? 2 : (simag__ans[1]==1) ? 1 : 0;
  assign modified__exponent = (msb__loc == 27) ? exponent + 1 : (27-msb__loc < exponent) ? exponent - (27-msb__loc) + 1: 1;  
  assign simag__ans2 =(27-msb__loc < exponent) ? simag__ans << 27-msb__loc : simag__ans << exponent;
  assign shift__ans = {ans[28],simag__ans2[27:0]};
  
endmodule



