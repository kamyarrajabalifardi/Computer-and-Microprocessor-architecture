
`timescale 1ns/1ns
module unsigned_multiplier #(parameter nb = 8'h8)
(
   input clk,  
   input start,
   input [nb-1:0] A, 
   input [nb-1:0] B, 
   output reg [2*nb-1:0] Product,
   output ready
    ); 

//-----------------------Register deceleration
reg [nb-1:0] multiplicand;
reg [nb:0] counter;


//------------------------Wire deceleration
wire [nb:0] adder_output;
wire adder_write_enable;

//-----------------------assignments(combinational logic)
//assign adder_output = (counter == nb-1) ? ((adder_write_enable) ? Product[2*nb-1:nb] - multiplicand : Product[2*nb-1:nb] ) : ((adder_write_enable) ? Product[2*nb-1:nb] + multiplicand : Product[15:8]);
//assign adder_output = (counter == nb-1) ? ((adder_write_enable) ? {Product[2*nb-1] , Product[2*nb-1:nb]} - {multiplicand[nb-1] , multiplicand} : {Product[2*nb-1] , Product[2*nb-1:nb]} ) : ((adder_write_enable) ? {Product[2*nb-1] , Product[2*nb-1:nb]} + {multiplicand[nb-1] , multiplicand} : {Product[2*nb-1] , Product[2*nb-1:nb]});
assign adder_output = Product[2*nb-1:nb] + multiplicand;
assign adder_write_enable = Product[0];
assign ready = (counter == nb);

//-------------------------sequential logic
always @(posedge clk)
  
  if(start) begin
    multiplicand <= A;
    Product <= {{nb{0}} , B };
    counter <= {nb{0}};
  end
  
  else if(!ready) begin
    counter <= counter + 1;
    Product <= Product >> 1;
    if(adder_write_enable)
      Product[2*nb-1:nb-1] <= adder_output;
   // Product[2*nb-1] <= (adder_output[8]==1) ? 1:multiplicand[7];
  end

endmodule
  
