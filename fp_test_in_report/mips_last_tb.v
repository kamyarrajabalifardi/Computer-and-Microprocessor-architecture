

`timescale 1ns/10ps

module mips_last_tb;

   reg clk = 1;
   always @(clk)
      clk <= #1.25 ~clk;

   reg reset;
   initial begin
      reset = 1;
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      #0.2;
      reset = 0;
   end

   initial
      $readmemh("fp_test.hex", mem.mem_data);

   parameter end_pc = 32'h200; // This is the address of OS, where the functino is called
   
always @(cpu.PC) begin
   if(cpu.PC == end_pc) begin
		//$write("$s0 = %d", cpu.rf.rf_data[16]);
		$stop;
	end
end


   multi_cycle_mips cpu(
      .clk( clk ),
      .reset( reset ),
      .mem_addr( ),
      .mem_read_data( mem.read_data ),
      .mem_write_data(),
      .mem_read( ),
      .mem_write( ),
      //our poor instantiation
      .mem_write_data_src( )
   );

   async_mem mem(
      .clk( clk ),
      .read( cpu.mem_read ),
      .write( cpu.mem_write ),
      .address( cpu.mem_addr ),
      .write_data( cpu.mem_write_data ),
      //our poor instantiation
      .write_data_src( cpu.mem_write_data_src ),
      .read_data()
      );

endmodule

//==============================================================================

module async_mem(
   input clk,
   input read,
   input write,
   input [31:0] address,
   input [31:0] write_data,
   //our poor input
   input [1:0]  write_data_src,
   
   output [31:0] read_data
);

   reg [31:0] mem_data [0:1023];

   assign #7 read_data = read ? mem_data[ address[11:2] ] : 32'bxxxxxxxx;

   always @( posedge clk )
      if ( write )begin
        if(write_data_src==2'b00)
          mem_data[ address[11:2] ] <= write_data;
        if(write_data_src==2'b01)//sb
          mem_data[ address[11:2] ][7:0] <= write_data[7:0];
        if(write_data_src==2'b10)//sh
          mem_data[ address[11:2] ][15:0]<= write_data[15:0];    
      end
endmodule

//==============================================================================
