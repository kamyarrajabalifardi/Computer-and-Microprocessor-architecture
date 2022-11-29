`timescale 1ns/1ns
module signed_divider //calculate B/A
(
   input clk,  
   input start,
   input [31:0] A, 
   input [31:0] B, 
   output [63:0] rem_quot,
   output ready
    ); 

//-----------------------Register deceleration
reg [31:0] divisor;
reg [32:0] counter;
reg [63:0] unsigned_result;

//------------------------Wire deceleration
wire [31:0] sub_output;
wire sub_write_enable;
wire [31:0]comparator;
wire sign_A , sign_B;
wire [31:0] mag_A , mag_B;  //magnitude of A and B
wire [31:0] rem , quot;
wire [63:0]unsigned_result_shift;
wire [31:0]unsigned_result_shift_half;
wire unsigned_result_shift_half_eq_mag_A;
wire unsigned_result_shift_half_gt_mag_A;
wire unsigned_result_shift_half_lt_mag_A;
wire [31:0]C;
//-----------------------assignments(combinational logic)
assign sign_A = A[31];
assign sign_B = B[31];
assign mag_A = (sign_A==1) ? ~A+1 : A;
assign mag_B = (sign_B==1) ? ~B+1 : B;
assign unsigned_result_shift = unsigned_result << 1;
assign unsigned_result_shift_half = unsigned_result_shift[63:32];

//-----------------------comparator unit
assign C = ~(unsigned_result_shift_half ^ mag_A); 
assign unsigned_result_shift_half_eq_mag_A = &C;
assign unsigned_result_shift_half_gt_mag_A = (unsigned_result_shift_half[31]&(~mag_A[31])) | (unsigned_result_shift_half[30]&(~mag_A[30]))&C[31] | (unsigned_result_shift_half[29]&(~mag_A[29]))&(&C[31:30]) | (unsigned_result_shift_half[28]&(~mag_A[28]))&(&C[31:29]) | (unsigned_result_shift_half[27]&(~mag_A[27]))&(&C[31:28]) | (unsigned_result_shift_half[26]&(~mag_A[26]))&(&C[31:27]) | (unsigned_result_shift_half[25]&(~mag_A[25]))&(&C[31:26]) | (unsigned_result_shift_half[24]&(~mag_A[24]))&(&C[31:25]) | (unsigned_result_shift_half[23]&(~mag_A[23]))&(&C[31:24]) | (unsigned_result_shift_half[22]&(~mag_A[22]))&(&C[31:23]) | (unsigned_result_shift_half[21]&(~mag_A[21]))&(&C[31:22]) | (unsigned_result_shift_half[20]&(~mag_A[20]))&(&C[31:21]) | (unsigned_result_shift_half[19]&(~mag_A[19]))&(&C[31:20]) | (unsigned_result_shift_half[18]&(~mag_A[18]))&(&C[31:19]) | (unsigned_result_shift_half[17]&(~mag_A[17]))&(&C[31:18]) | (unsigned_result_shift_half[16]&(~mag_A[16]))&(&C[31:17]) | (unsigned_result_shift_half[15]&(~mag_A[15]))&(&C[31:16]) | (unsigned_result_shift_half[14]&(~mag_A[14]))&(&C[31:15]) | (unsigned_result_shift_half[13]&(~mag_A[13]))&(&C[31:14]) | (unsigned_result_shift_half[12]&(~mag_A[12]))&(&C[31:13]) | (unsigned_result_shift_half[11]&(~mag_A[11]))&(&C[31:12]) | (unsigned_result_shift_half[10]&(~mag_A[10]))&(&C[31:11]) | (unsigned_result_shift_half[9]&(~mag_A[9]))&(&C[31:10]) | (unsigned_result_shift_half[8]&(~mag_A[8]))&(&C[31:9]) | (unsigned_result_shift_half[7]&(~mag_A[7]))&(&C[31:8]) | (unsigned_result_shift_half[6]&(~mag_A[6]))&(&C[31:7]) | (unsigned_result_shift_half[5]&(~mag_A[5]))&(&C[31:6]) | (unsigned_result_shift_half[4]&(~mag_A[4]))&(&C[31:5]) | (unsigned_result_shift_half[3]&(~mag_A[3]))&(&C[31:4]) | (unsigned_result_shift_half[2]&(~mag_A[2]))&(&C[31:3]) | (unsigned_result_shift_half[1]&(~mag_A[1]))&(&C[31:2]) | (unsigned_result_shift_half[0]&(~mag_A[0]))&(&C[31:1]);
assign unsigned_result_shift_half_lt_mag_A = ~(unsigned_result_shift_half_gt_mag_A ^ unsigned_result_shift_half_eq_mag_A);

assign sub_output = unsigned_result_shift_half - divisor;
assign sub_write_enable = unsigned_result_shift_half_lt_mag_A;
assign ready = (counter==32);
assign rem  = (ready==1) ? (sign_B==0) ? unsigned_result[63:32] : ~unsigned_result[63:32]+1 : 32'hxxxxxxxx ;
assign quot = (ready==1) ? (sign_A ^ sign_B ==1) ? ~unsigned_result[31:0]+1 : unsigned_result[31:0] : 32'hxxxxxxxx ;
assign rem_quot = {rem , quot};

//-------------------------sequential logic
always @(posedge clk)
  
  if(start) begin
    divisor <= mag_A;
    unsigned_result <= {32'h00000000 , mag_B };
    counter <= 32'h00000000;
  end
  
  else if(!ready) begin
    counter <= counter + 1;
    if(sub_write_enable==1)
      unsigned_result <= unsigned_result << 1 ;
    if(sub_write_enable==0) begin
       unsigned_result <= {sub_output , unsigned_result_shift[31:0]} + 1;
    end
  end

endmodule
