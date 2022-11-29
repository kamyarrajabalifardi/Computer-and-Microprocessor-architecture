`timescale 1ns/1ns
module fp_mult__tb();
integer i,j,k,n;
integer notests = 2000;
reg [31:0] A, B, D, data[0:6000];
reg start;
reg clk = 1'b1;
always @(clk)
	clk <= #5 ~clk;
wire [31:0] C;
initial begin
j = 0;
n = 0;
$readmemb("testdiv.hex",data);
if(data[0] === 'bx) begin
         $display("ERROR: fp.hex file is not read in properly");
         $display("Make sure this file is located in working directory");
         $stop;
      end
for(i = 0; i < notests; i = i + 1) begin
	A = data[i*3];
	B = data[i*3+1];
	D = data[i*3+2];
	#10;
	start = 1;
	#1;
	start = 0;
	for(k=0;k<=24;k =k+1)
		@(posedge clk);
	@(posedge clk);
	if( D != C) begin
		$write("\nThere's a probelm : %b * %b = $b but got : %b  ?\n", A , B, D, C);
		j = j + 1;
	end
	else
		$write("\nCorrect! fantastic!\n");
	n = n + 1;
end
	$write("Number of errors :%d in %d tests\n", j, n);
	$stop;
end

fp_mult fpm(
.A(A),
.B(B),
.C(C),
.clk(clk),
.start(start),
.ready()
);

endmodule