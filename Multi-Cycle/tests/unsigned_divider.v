`timescale 1ns/1ns
module unsigned_divider //calculate B/A
(
   input clk,  
   input start,
   input [31:0] A, 
   input [31:0] B, 
   output reg [63:0] rem_quot,
   output ready
    ); 

//-----------------------Register deceleration
reg [31:0] divisor;
reg [32:0] counter;


//------------------------Wire deceleration
wire [31:0] sub_output;
wire sub_write_enable;
wire [63:0]rem_quot_shift;
wire [31:0]rem_quot_shift_half;
wire rem_quot_shift_half_eq_A;
wire rem_quot_shift_half_gt_A;
wire rem_quot_shift_half_lt_A;
wire [31:0]C;

//-----------------------assignments(combinational logic)
//-----------------------comparator unit

/*assign BeqA = &C; 
assign BgtA = (B[31]&(~A[31])) | (B[30]&(~A[30]))&C[31] | (B[29]&(~A[29]))&(&C[31:30]) | (B[28]&(~A[28]))&(&C[31:29]) | (B[27]&(~A[27]))&(&C[31:28]) | (B[26]&(~A[26]))&(&C[31:27]) | (B[25]&(~A[25]))&(&C[31:26]) | (B[24]&(~A[24]))&(&C[31:25]) | (B[23]&(~A[23]))&(&C[31:24]) | (B[22]&(~A[22]))&(&C[31:23]) | (B[21]&(~A[21]))&(&C[31:22]) | (B[20]&(~A[20]))&(&C[31:21]) | (B[19]&(~A[19]))&(&C[31:20]) | (B[18]&(~A[18]))&(&C[31:19]) | (B[17]&(~A[17]))&(&C[31:18]) | (B[16]&(~A[16]))&(&C[31:17]) | (B[15]&(~A[15]))&(&C[31:16]) | (B[14]&(~A[14]))&(&C[31:15]) | (B[13]&(~A[13]))&(&C[31:14]) | (B[12]&(~A[12]))&(&C[31:13]) | (B[11]&(~A[11]))&(&C[31:12]) | (B[10]&(~A[10]))&(&C[31:11]) | (B[9]&(~A[9]))&(&C[31:10]) | (B[8]&(~A[8]))&(&C[31:9]) | (B[7]&(~A[7]))&(&C[31:8]) | (B[6]&(~A[6]))&(&C[31:7]) | (B[5]&(~A[5]))&(&C[31:6]) | (B[4]&(~A[4]))&(&C[31:5]) | (B[3]&(~A[3]))&(&C[31:4]) | (B[2]&(~A[2]))&(&C[31:3]) | (B[1]&(~A[1]))&(&C[31:2]) | (B[0]&(~A[0]))&(&C[31:1]);
assign BltA = ~(BeqA ^ BgtA);*/  
assign rem_quot_shift = rem_quot << 1;
assign rem_quot_shift_half = rem_quot_shift[63:32];
//-----------------------comparator unit
assign C = ~(rem_quot_shift_half ^ A);
assign rem_quot_shift_half_eq_A = &C;
assign rem_quot_shift_half_gt_A = (rem_quot_shift_half[31]&(~A[31])) | (rem_quot_shift_half[30]&(~A[30]))&C[31] | (rem_quot_shift_half[29]&(~A[29]))&(&C[31:30]) | (rem_quot_shift_half[28]&(~A[28]))&(&C[31:29]) | (rem_quot_shift_half[27]&(~A[27]))&(&C[31:28]) | (rem_quot_shift_half[26]&(~A[26]))&(&C[31:27]) | (rem_quot_shift_half[25]&(~A[25]))&(&C[31:26]) | (rem_quot_shift_half[24]&(~A[24]))&(&C[31:25]) | (rem_quot_shift_half[23]&(~A[23]))&(&C[31:24]) | (rem_quot_shift_half[22]&(~A[22]))&(&C[31:23]) | (rem_quot_shift_half[21]&(~A[21]))&(&C[31:22]) | (rem_quot_shift_half[20]&(~A[20]))&(&C[31:21]) | (rem_quot_shift_half[19]&(~A[19]))&(&C[31:20]) | (rem_quot_shift_half[18]&(~A[18]))&(&C[31:19]) | (rem_quot_shift_half[17]&(~A[17]))&(&C[31:18]) | (rem_quot_shift_half[16]&(~A[16]))&(&C[31:17]) | (rem_quot_shift_half[15]&(~A[15]))&(&C[31:16]) | (rem_quot_shift_half[14]&(~A[14]))&(&C[31:15]) | (rem_quot_shift_half[13]&(~A[13]))&(&C[31:14]) | (rem_quot_shift_half[12]&(~A[12]))&(&C[31:13]) | (rem_quot_shift_half[11]&(~A[11]))&(&C[31:12]) | (rem_quot_shift_half[10]&(~A[10]))&(&C[31:11]) | (rem_quot_shift_half[9]&(~A[9]))&(&C[31:10]) | (rem_quot_shift_half[8]&(~A[8]))&(&C[31:9]) | (rem_quot_shift_half[7]&(~A[7]))&(&C[31:8]) | (rem_quot_shift_half[6]&(~A[6]))&(&C[31:7]) | (rem_quot_shift_half[5]&(~A[5]))&(&C[31:6]) | (rem_quot_shift_half[4]&(~A[4]))&(&C[31:5]) | (rem_quot_shift_half[3]&(~A[3]))&(&C[31:4]) | (rem_quot_shift_half[2]&(~A[2]))&(&C[31:3]) | (rem_quot_shift_half[1]&(~A[1]))&(&C[31:2]) | (rem_quot_shift_half[0]&(~A[0]))&(&C[31:1]);
assign rem_quot_shift_half_lt_A = ~(rem_quot_shift_half_gt_A ^ rem_quot_shift_half_eq_A);

assign sub_output = rem_quot_shift_half - divisor;
assign sub_write_enable = rem_quot_shift_half_lt_A;
//assign ready = (BltA==1) ? (counter==32) : (B[31]==1 || A==1) ? (counter == 40) : (counter == 60);
assign ready = (counter == 32);
//-------------------------sequential logic
always @(posedge clk)
  
  if(start) begin
    divisor <= A;
    rem_quot <= {32'h0000 , B };
    counter <= 32'h0000;
  end
  
  else if(!ready) begin
    counter <= counter + 1;
    if(sub_write_enable==1)
      rem_quot <= rem_quot << 1 ;
    if(sub_write_enable==0) begin
       rem_quot <= {sub_output , rem_quot_shift[31:0]} + 1;
    end
  end

endmodule
  

