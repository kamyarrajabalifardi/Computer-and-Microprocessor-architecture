
`timescale 1ns/1ns
module signed_multiplier #(parameter nb = 8'h8)
(
   input clk,  
   input start,
   input signed[31:0] A, 
   input signed[31:0] B, 
   output reg signed[63:0] Product,
   output ready
    ); 

//-----------------------Register deceleration
reg signed[31:0] multiplicand;
reg [32:0] counter;


//------------------------Wire deceleration
wire signed[32:0] adder_output;
wire adder_write_enable;

//-----------------------assignments(combinational logic)
//assign adder_output = (counter == nb-1) ? ((adder_write_enable) ? Product[2*nb-1:nb] - multiplicand : Product[2*nb-1:nb] ) : ((adder_write_enable) ? Product[2*nb-1:nb] + multiplicand : Product[15:8]);
assign adder_output = (counter == 31) ? ((adder_write_enable) ? {Product[63] , Product[63:32]} - {multiplicand[31] , multiplicand} : {Product[63] , Product[63:32]} ) : ((adder_write_enable) ? {Product[63] , Product[63:32]} + {multiplicand[31] , multiplicand} : {Product[63] , Product[63:32]});
assign adder_write_enable = Product[0];
assign ready = (counter == 32);

//-------------------------sequential logic
always @(posedge clk)
  
  if(start) begin
    multiplicand <= A;
    Product <= {32'h0000 , B };
    counter <= 32'h0000;
  end
  
  else if(!ready) begin
    counter <= counter + 1;
    Product <= Product >>> 1;
    if(adder_write_enable)
      Product[63:31] <= adder_output;
   // Product[2*nb-1] <= (adder_output[8]==1) ? 1:multiplicand[7];
  end

endmodule
  
