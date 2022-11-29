/*this module round a 28 bit number based on ieee rounding*/
`timescale 1ns/100ps
module rounding(
input [28:0]A,  
input [4:0]msb_loc,
output [24:0]B
);

assign B = (msb_loc == 27) ? (A[3]==0) ? {1'b0,A[27:4]} : (A[2]==1) ? A[27:4]+1 : (A[1] || A[0]==1) ? A[27:4]+1 : (A[4]==0) ? {1'b0,A[27:4]} : A[27:4]+1 :
           (msb_loc == 26) ? (A[3]==0) ? {1'b0,A[27:4]} : (A[2]==1) ? A[27:4]+1 : (A[1]==1) ? A[27:4]+1 : (A[4]==0) ? {1'b0,A[27:4]} : A[27:4]+1 :
           (msb_loc == 25) ? (A[3]==0) ? {1'b0,A[27:4]} : (A[2]==1) ? A[27:4]+1 : (A[4]==0) ? {1'b0,A[27:4]} : A[27:4]+1 : {1'b0,A[27:4]};                     
endmodule
