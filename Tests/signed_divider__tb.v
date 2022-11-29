`timescale 1ns/1ns

module signed_divider__tb();

   parameter no_of_tests = 100;

//------------------generating clock signal in 100MHz
   reg clk = 1'b1;
   always @(clk)
      clk <= #5 ~clk;
//-----------------------------------------------------
 
//-------------------------------------- reg declaration 
   reg start;
   reg signed [31:0] A, B, C, D;
   reg signed [31:0] expected_division;
//----------------------------------------------------------    
   integer i, j, err = 0;
   
   initial begin
      start = 0;

      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      #1;
//------------------------------------------repeat the test no_of_tests times with different random numbers
      for(i=0; i<no_of_tests; i=i+1) begin

         A = $random();    
         B = $random() % 10000 + 1;
         expected_division = A / B;
         C = A;
         D = B;
      //----------------------------------generating start signal -------------------------------------------------------------     
         start = 1;
         @(posedge clk);
         #1;
         start = 0;
      //----------------------------------------------------------------------------------------------------------------------
         
      //-----------------------------------wait until multiplication become complete
         for(j=0; j<=32; j=j+1)        
            @(posedge clk);
         @(posedge clk);
      //------------------------------------------------------------------------------

         $write   ("%x (%0d) x %x (%0d) = %x (%0d) ", C, C, D, D, uut.rem_quot[31:0], uut.rem_quot[31:0]);

         if (expected_division === uut.rem_quot[31:0])
            $display(", OK");
         else 
            $display (", ERROR: expected %d, got %d", expected_division, uut.rem_quot[31:0]); 

      end

      $stop;
   end


    signed_divider uut (        // unsigned unit
        .clk(clk),
        .start(start),
        .A(B),
        .B(A),
        .rem_quot(),
      .ready()
    );


endmodule
