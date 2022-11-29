`timescale 1ns/100ps

   `define ADD  3'b000
   `define SUB  3'b001
   `define SLT  3'b010
   `define SLTU 3'b011
   `define AND  3'b100
   `define XOR  3'b101
   `define OR   3'b110
   `define NOR  3'b111
     
     /*`define ADD   5'b00000
     `define ADDU  5'b00001
     `define SUB   5'b00010
     `define SUBU  5'b00011
     `define AND   5'b00100
     `define OR    5'b00101
     `define XOR   5'b00110
     `define NOR   5'b00111
     `define SLT   5'b01000
     `define SLTU  5'b01001
     `define JR    5'b01010
     `define JALR  5'b01011
     `define MULTU 5'b01100
     `define MFHI  5'b01101
     `define MFLO  5'b01110
     `define LUI   5'b01111
     `define J     5'b10000
     `define JAL   5'b10001 
	 */
module multi_cycle_mips(

   input clk,
   input reset,

   // Memory Ports
   output  [31:0] mem_addr,
   input   [31:0] mem_read_data,
   output  [31:0] mem_write_data,
   output         mem_read,
   output         mem_write,
   //our poor output
   output [1:0]  mem_write_data_src
);

   // Data Path Registers
   reg MRE, MWE;
   reg [31:0] A, B, PC, IR, MDR, MAR;
   
   // Data Path Control Lines, donot forget, regs are not always regs !!
   reg setMRE, clrMRE, setMWE, clrMWE;
   reg Awrt, Bwrt, RFwrt, PCwrt, IRwrt, MDRwrt, MARwrt;
   
   // Our poor Control lines
   reg LOwrt, HIwrt;
   reg start_mu, start_ms, start_du, start_ds;
   reg signed [31:0] signed_B; 
   reg [1:0]us; //Mux selector for Mult or Multu or Div or Divu
   reg [63:0] Mult_Div_Source;
   reg [1:0] data_src;
   reg BorBfp;
   
   //our poor floating point control lines and registers(fp_unit)
   reg [31:0]A_fp,B_fp;
   reg A_fp_wrt,B_fp_wrt,RF_fp_wrt;
   wire [31:0]rfRD1_fp,rfRD2_fp;
   reg RegDst_fp;
   reg [2:0]MemtoReg_fp;
   wire [31:0]alu_fp_adder_result,alu_fp_mult_Result, alu_fp_div_Result;
   wire ready_fp;
   reg start_fp, start_dfp;
   
   // Memory Ports Binding
   assign mem_addr = MAR;
   assign mem_read = MRE;
   assign mem_write = MWE;
   assign mem_write_data =(BorBfp==1) ? B : B_fp;
   assign mem_write_data_src = data_src;
   
   // Our poor declerations
   reg [1:0]PCsel;
   reg [31:0]PCsrc , hi, lo;
   reg [2:0]  MDR_src;
   
   // Mux & ALU Control Lines
   reg [2:0] aluOp, MemtoReg;
   reg [1:0] aluSelB,RegDst, IorD; // case(IorD) 00: MAR <= PC; 01: MAR <= aluResult; 10: MAR <= $rs(for jr)
   reg SgnExt, aluSelA;
   //reg SgnExt, aluSelA, MemtoReg, RegDst, IorD;
   
   // Wiring
   wire aluZero;
   wire [31:0] aluResult, rfRD1, rfRD2;
   
   // Our poor wiring
   wire [63:0] aluMultResult_u, aluMultResult_s, aluDivResult_u, aluDivResult_s;
   wire [31:0] shift; //for sll,slv,srl,...
   wire ready_mu, ready_ms, ready_du, ready_ds; //for mult(u) and div(u) operations
   wire [31:0]V,U;
   wire [31:0] MDR_result;
   
   //our poor U & V
   always @(*)
   begin
    signed_B=B;
   end
   
   assign V=signed_B>>>IR[10:6];
   assign U=signed_B>>>A[4:0];
   
   // Clocked Registers
   always @( posedge clk ) begin
      if( reset )
         PC <= #0.1 32'h00000000;
      else if( PCwrt )
         PC <= #0.1 PCsrc;

      if( Awrt ) A <= #0.1 rfRD1;
      if( Bwrt ) B <= #0.1 rfRD2;
      //our poor A & B reg(fp_unit)
      if( A_fp_wrt ) A_fp <= #0.1 rfRD1_fp;
      if( B_fp_wrt ) B_fp <= #0.1 rfRD2_fp;
        
      if( MARwrt ) MAR <= #0.1 (IorD == 2'b11) ? {PC[31:28], IR[25:0], 2'b00} :(IorD == 2'b10) ? rfRD1 : (IorD == 2'b01) ? aluResult : PC;

      if( IRwrt ) IR <= #0.1 mem_read_data;
      if( MDRwrt ) MDR <= #0.1 mem_read_data;

      if( reset | clrMRE ) MRE <= #0.1 1'b0;
          else if( setMRE) MRE <= #0.1 1'b1;

      if( reset | clrMWE ) MWE <= #0.1 1'b0;
          else if( setMWE) MWE <= #0.1 1'b1;
		  
	  
	  // Our poor clocked registers
	  if(HIwrt) hi <= #0.1 Mult_Div_Source[63:32];
	  if(LOwrt) lo <= #0.1 Mult_Div_Source[31:0] ;
   end

   // Register File
   reg_file rf(
      .clk( clk ),
      .write( RFwrt ),

      .RR1( IR[25:21] ),
      .RR2( IR[20:16] ),
      .RD1( rfRD1 ),
      .RD2( rfRD2 ),
		// Our poor regfile input muxes
      .WR( (RegDst == 2'b11 | RegDst == 2'b10) ? 5'b11111 : (RegDst == 2'b01) ? IR[15:11] : IR[20:16] ),
      .WD( (MemtoReg == 3'b110) ? shift : (MemtoReg == 3'b101) ? hi : (MemtoReg == 3'b100) ? lo : (MemtoReg == 3'b011) ? {IR[15:0] , 16'h0000} : (MemtoReg == 3'b010) ? PC : (MemtoReg == 3'b001) ? MDR_result : aluResult )
   );

  // our poor Register file(fp_unit)
  reg_file_fp rf_fp(
      .clk( clk ),
      .write( RF_fp_wrt ),
      
      .RR1( IR[15:11] ),
      .RR2( IR[20:16] ),
      .RD1( rfRD1_fp ),
      .RD2( rfRD2_fp ),
      
      .WR( (RegDst_fp == 0) ? IR[10:6] : IR[20:16]),    
      .WD( (MemtoReg_fp == 3'b000) ? MDR : (MemtoReg_fp == 3'b001) ? alu_fp_adder_result : (MemtoReg_fp == 3'b010) ? {~A_fp[31],A_fp[30:0]} : (MemtoReg_fp == 3'b011) ? {1'b0,A_fp[30:0]} : (MemtoReg_fp == 3'b100) ? alu_fp_mult_Result : (MemtoReg_fp == 3'b101) ? alu_fp_div_Result : 32'hxxxxxxxx )
  );
  
unsigned_multiplier #(.nb(32)) um (
 .clk(clk) ,
 .start(start_mu) ,
 .A(rfRD1) ,
 .B(rfRD2) ,
 .Product(aluMultResult_u) ,
 .ready(ready_mu)
 );
 
 signed_multiplier #(.nb(32)) sm (
 .clk(clk) ,
 .start(start_ms) ,
 .A(rfRD1) ,
 .B(rfRD2) ,
 .Product(aluMultResult_s) ,
 .ready(ready_ms)
 );

unsigned_divider  ud(
 .clk(clk) ,
 .start(start_du) ,
 .A(rfRD2) ,
 .B(rfRD1) , 
 .rem_quot(aluDivResult_u) , 
 .ready(ready_du)
);

signed_divider  sd(
 .clk(clk) ,
 .start(start_ds) ,
 .A(rfRD2) ,
 .B(rfRD1) , 
 .rem_quot(aluDivResult_s) , 
 .ready(ready_ds)
);

fp_mult fp_mult (
 .clk(clk) ,
 .start(start_fp) ,
 .A(rfRD1_fp) ,
 .B(rfRD2_fp) ,
 .C(alu_fp_mult_Result) ,
 .ready(ready_fp)
 );

fp_adder fp_add(
.a(rfRD1_fp),
.b((IR[0]==0) ? rfRD2_fp : {~rfRD2_fp[31],rfRD2_fp[30:0]}),
.s(alu_fp_adder_result)
);

fp_div fpd(
.clk(clk),
.start(start_dfp),
.A(rfRD1_fp),
.B(rfRD2_fp),
.C(alu_fp_div_Result),
.ready(ready_dfp)
);
   // Sign/Zero Extension
   wire [31:0] SZout = SgnExt ? {{16{IR[15]}}, IR[15:0]} : {16'h0000, IR[15:0]};

   // ALU-A Mux
   wire [31:0] aluA = aluSelA ? A : PC;

   // ALU-B Mux
   reg [31:0] aluB;
   always @(*)
   case (aluSelB)
      2'b00: aluB = B;
      2'b01: aluB = 32'h4;
      2'b10: aluB = SZout;
      2'b11: aluB = SZout << 2;
   endcase
   
   // PC Mux
   always @(*)
   case(PCsel)
      2'b00:PCsrc = aluResult;
      2'b01:PCsrc = {PC[31:28], IR[25:0], 2'b00};
   	  2'b10:PCsrc = rfRD1;
   endcase
   
   //our poor Mult/Div Mux
   always @(*)
   case(us)
		2'b00:Mult_Div_Source = aluMultResult_u;
		2'b01:Mult_Div_Source = aluMultResult_s;
		2'b10:Mult_Div_Source = aluDivResult_u;
		2'b11:Mult_Div_Source = aluDivResult_s;
	endcase
   
    //MDR DEMUX;)
   assign MDR_result = (MDR_src==3'b000) /*lw*/ ? MDR : (MDR_src==3'b001)/*lbu*/ ? {24'b000000000000000000000000,MDR[7:0]} : (MDR_src==3'b010)/*lb*/ ? {{24{MDR[7]}},MDR[7:0]} : (MDR_src==3'b011)/*lh*/ ? {{16{MDR[15]}},MDR[15:0]} : (MDR_src==3'b100)/*lhu*/ ? {16'b0000000000000000,MDR[15:0]} : 'hx ;
  
   //Our poor shift
   assign shift = (IR[5:0]==6'b000_000) ? B<<IR[10:6] : (IR[5:0]==6'b000_010) ? B>>IR[10:6] : (IR[5:0]==6'b000_100) ? B<<A[4:0] : (IR[5:0]==6'b000_110) ? B>>A[4:0] : (IR[5:0]==6'b000_011) ? V : U;
 
   my_alu2 alu(
      .A( aluA ),
      .B( aluB ),
      .Op( aluOp ),

      .X( aluResult ),
      .Z( aluZero )
	  //.MultOut(aluMultResult) // Our poor alu instanciation
   );


   // Controller Starts Here

   // Controller State Registers
   reg [5:0] state, nxt_state;

   // State Names & Numbers
   localparam
      RESET = 0, FETCH1 = 1, FETCH2 = 2, FETCH3 = 3, DECODE = 4,
      EX_ALU_R = 7, EX_ALU_I = 8,
      EX_LW_1 = 11, EX_LW_2 = 12, EX_LW_3 = 13, EX_LW_4 = 14, EX_LW_5 = 15,
      EX_SW_1 = 21, EX_SW_2 = 22, EX_SW_3 = 23,
      EX_BRA_1 = 25, EX_BRA_2 = 26, EX_BRA_3 = 27, EX_BRA_4 = 28, EX_MULTU = 60, EX_MULT = 61, EX_DIVU = 62, EX_DIV = 63,
      EX_SHIFTS = 30, EX_LW_FP_1 = 31, EX_LW_FP_2 = 32, EX_LW_FP_3 = 33, EX_LW_FP_4 = 34, EX_LW_FP_5 = 35,
      EX_SW_FP_1 = 36, EX_SW_FP_2 = 37, EX_SW_FP_3 = 38, EX_FP_ADDER = 39, EX_NEG = 40, EX_ABS = 41, EX_FP_MULT = 42, EX_FP_DIV = 43;
	  
//=======================================================================================
   // State Clocked Register 
   always @(posedge clk)
      if(reset)
         state <= #0.1 RESET;
      else
         state <= #0.1 nxt_state;

   task PrepareFetch;
      begin
         IorD = 2'b00;
         setMRE = 1;
         MARwrt = 1;
         nxt_state = FETCH1;
      end
   endtask

   // State Machine Body Starts Here
   always @( * ) begin

      nxt_state = 'bx;

      SgnExt = 'bx; IorD = 'bx;
      MemtoReg = 'bx; RegDst = 'bx;
      aluSelA = 'bx; aluSelB = 'bx; aluOp = 'bx; PCsel = 'bx;
      MDR_src = 'bx;
      RegDst_fp = 'bx; MemtoReg_fp = 'bx;
      
      PCwrt = 0;
      Awrt = 0; Bwrt = 0;
      RFwrt = 0; IRwrt = 0;
      MDRwrt = 0; MARwrt = 0;
      setMRE = 0; clrMRE = 0;
      setMWE = 0; clrMWE = 0;
      HIwrt = 0; LOwrt = 0;
      A_fp_wrt = 0; B_fp_wrt = 0;
      RF_fp_wrt = 0;
      
      case(state)

         RESET:
            PrepareFetch;


         FETCH1:
            nxt_state = FETCH2;

         FETCH2:
            nxt_state = FETCH3;

         FETCH3: begin
            IRwrt = 1;
            PCwrt = 1;
            clrMRE = 1;
            aluSelA = 0;
            aluSelB = 2'b01;
            PCsel = 2'b00;
            aluOp = `ADD;
            nxt_state = DECODE;
         end

         DECODE: begin
            Awrt = 1;
            Bwrt = 1;
            A_fp_wrt = 1;
            B_fp_wrt = 1;
            
            case( IR[31:26] )
               6'b000_000:             // R-format
                  case( IR[5:0] )
                     6'b100000, 
                     6'b100001,
                     6'b100010, 
                     6'b100011, 
                     6'b100100, 
                     6'b100101,
                     6'b100110, 
                     6'b100111, 
                     6'b101010, 
                     6'b101011:                 
                          nxt_state = EX_ALU_R; 
				   6'b001000: begin // jr
						PCwrt = 1;
						PCsel = 2'b10;
						MARwrt = 1;
						IorD = 2'b10;
						setMRE = 1;
						nxt_state = FETCH1;
					 end
					 6'b001001: begin // jalr
						PCwrt = 1;
						PCsel = 2'b10;
						MARwrt = 1;
						IorD = 2'b10;
						RFwrt = 1;
						RegDst = 2'b10;
						MemtoReg = 3'b010;
						setMRE = 1;
						nxt_state = FETCH1;
					 end

					6'b011000: begin  //MULT
					nxt_state = EX_MULT;
					start_ms = 1;
					end
					
					6'b011001: begin     //MULTU
          nxt_state = EX_MULTU;
          start_mu = 1;
				  end
				  
				  6'b011010: begin     //Div
				  nxt_state = EX_DIV;
				  start_ds = 1;
				  end
				  
				  6'b011011: begin
				  nxt_state = EX_DIVU; //DIVU
				  start_du = 1;
				  end
				    
           6'b010000:begin       //MFHI
              RFwrt = 1;
              MemtoReg = 3'b101;
              RegDst = 2'b01;
              PrepareFetch;
              end
                        
           6'b010010:begin       //MFLO
              RFwrt = 1;
              MemtoReg = 3'b100;
              RegDst = 2'b01;
              PrepareFetch;
              end
						          
					 6'b000000,      //ALL SHIFTS
					 6'b000010,
					 6'b000100,
					 6'b000011,
					 6'b000111,
					 6'b000110:            
						  nxt_state = EX_SHIFTS;
						            
           endcase

               6'b001_000,    //I-format
               6'b001_001,
               6'b001_010,
               6'b001_011,
               6'b001_100,
               6'b001_101,
               6'b001_110:
                  nxt_state = EX_ALU_I;
                  
               6'b100_000, //lb
               6'b100_001, //lh
               6'b100_100, //lbu
               6'b100_101, //lhu
               6'b100_011: //lw 
                  nxt_state = EX_LW_1;
                  
               6'b101_000, //sb
               6'b101_001, //sh
               6'b101_011:
                  nxt_state = EX_SW_1;
 
               6'b000_100: nxt_state = EX_BRA_1;    //beq
               6'b000_101: nxt_state = EX_BRA_3;    //bne
			   
			         6'b001_111:begin          //lui
                  RFwrt = 1;
                  MemtoReg = 3'b011;
                  RegDst = 2'b00;
                  PrepareFetch;
                end
               
               6'b000_010: begin    //jump
                 MARwrt = 1;
                 PCwrt = 1;
                 PCsel = 2'b01;
				         IorD = 2'b11;
                 setMRE = 1;
				         nxt_state = FETCH1;
               end   
			   
			           6'b000_011: begin      //jal
				         MARwrt = 1;
                 PCwrt = 1;
                 PCsel = 2'b01;
				         IorD = 2'b11;
                 setMRE = 1;
                 RFwrt = 1;
				         RegDst = 2'b10;
				         MemtoReg = 3'b010;
				         nxt_state = FETCH1;
				        end
				          
				         6'b110_001:  //lwc1
				          nxt_state = EX_LW_FP_1;
			           
			           6'b111_001:  //swc1
			            nxt_state = EX_SW_FP_1;
                  
                 6'b010_001:begin
                  if(IR[25:21]==5'b10000)begin
                    
                    if(IR[5:0]==6'b000000 || IR[5:0]==6'b000001)
                      nxt_state = EX_FP_ADDER; //add.s & sub.s;
                      
                    if(IR[5:0]==6'b000101)
                      nxt_state = EX_ABS; //abs
                      
                    if(IR[5:0]==6'b000111)
                      nxt_state = EX_NEG; //neg 
                       
                    if(IR[5:0]==6'b000010)begin
                      nxt_state = EX_FP_MULT; //mul.s
                      start_fp = 1;  
                    end
					if(IR[5:0]==6'b000011) begin
					  nxt_state = EX_FP_DIV;
					  start_dfp = 1;
					end
                  end
                 end
               // rest of instructiones should be decoded here

            endcase
         end

         EX_ALU_R: begin
           case(IR[5:0])
                     6'b100000: begin aluOp = `ADD;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100001: begin aluOp = `ADD;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100010: begin aluOp = `SUB;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100011: begin aluOp = `SUB;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100100: begin aluOp = `AND;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100101: begin aluOp = `OR;    aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100110: begin aluOp = `XOR;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b100111: begin aluOp = `NOR;   aluSelB = 2'b00;  aluSelA = 1; end
                     6'b101010: begin aluOp = `SLT;   aluSelB = 2'b00;  aluSelA = 1; end 
                     6'b101011: begin aluOp = `SLTU;  aluSelB = 2'b00;  aluSelA = 1; end
            endcase
             RFwrt = 1;
             RegDst = 2'b01;
             MemtoReg = 3'b000;
             PrepareFetch;
         end

         EX_FP_ADDER: begin
             RF_fp_wrt = 1;
             RegDst_fp = 0;
             MemtoReg_fp = 3'b001;
             PrepareFetch;
         end

         EX_ALU_I: begin
           case( IR[28:26] )
             3'b000: begin aluOp = `ADD;  SgnExt = 1; aluSelB = 2'b10 ; aluSelA = 1; end             // addi
             3'b001: begin aluOp = `ADD;  SgnExt = 1; aluSelB = 2'b10 ; aluSelA = 1; end             // addiu
             3'b010: begin aluOp = `SLT;  SgnExt = 1; aluSelB = 2'b10 ; aluSelA = 1; end             // slti
             3'b011: begin aluOp = `SLTU; SgnExt = 1; aluSelB = 2'b10 ; aluSelA = 1; end             // sltiu
             3'b100: begin aluOp = `AND;  SgnExt = 0; aluSelB = 2'b10 ; aluSelA = 1; end             // andi
             3'b101: begin aluOp = `OR;   SgnExt = 0; aluSelB = 2'b10 ; aluSelA = 1; end             // ori
             3'b110: begin aluOp = `XOR;  SgnExt = 0; aluSelB = 2'b10 ; aluSelA = 1; end             // xori
           endcase
             RegDst = 2'b00;
             MemtoReg = 3'b000;
             RFwrt = 1;
             PrepareFetch;
         end
          
         
         EX_LW_1: begin
            SgnExt = 1;
            aluSelA = 1;
            aluSelB = 2'b10;
            aluOp = `ADD;
            IorD = 2'b01;
            MARwrt = 1;
            setMRE=1;
            nxt_state = EX_LW_2;
         end
         EX_LW_2: begin
            nxt_state = EX_LW_3;
         end
         EX_LW_3: begin
            nxt_state = EX_LW_4;
         end
         EX_LW_4: begin
            clrMRE = 1;
            MDRwrt = 1;
            nxt_state = EX_LW_5;
         end
         EX_LW_5: begin
            RFwrt = 1;
            MDR_src = (IR[31:26]==6'b100_011)/*lw*/ ? 3'b000 : (IR[31:26]==6'b100_000)/*lb*/ ? 3'b010 : (IR[31:26]==6'b100_100)/*lbu*/ ? 3'b001 : (IR[31:26]==6'b100_001)/*lh*/ ? 3'b011 : /*lhu*/3'b100;
            MemtoReg = 3'b001;
            RegDst = 2'b00;
            PrepareFetch;
         end
         
         EX_LW_FP_1: begin
            SgnExt = 1;
            aluSelA = 1;
            aluSelB = 2'b10;
            aluOp = `ADD;
            IorD = 2'b01;
            MARwrt = 1;
            setMRE = 1;
            nxt_state = EX_LW_FP_2;
         end 
         EX_LW_FP_2: begin
            nxt_state = EX_LW_FP_3;
         end
         EX_LW_FP_3: begin
            nxt_state = EX_LW_FP_4;
         end
         EX_LW_FP_4: begin
            clrMRE = 1;
            MDRwrt = 1;
            nxt_state = EX_LW_FP_5;
         end
         EX_LW_FP_5: begin
            RF_fp_wrt = 1;
            //MDR_src = (IR[31:26]==6'b100_011)/*lw*/ ? 3'b000 : (IR[31:26]==6'b100_000)/*lb*/ ? 3'b010 : (IR[31:26]==6'b100_100)/*lbu*/ ? 3'b001 : (IR[31:26]==6'b100_001)/*lh*/ ? 3'b011 : /*lhu*/3'b100;
            //MemtoReg = 3'b001;
            RegDst_fp = 1;
            MemtoReg_fp = 3'b000;
            PrepareFetch;
         end
         
         EX_SW_FP_1: begin
           setMWE = 1;
           SgnExt = 1;
           MARwrt = 1;
           IorD = 2'b01;
           aluSelA = 1;
           aluSelB = 2'b10;
           aluOp = `ADD;
           nxt_state = EX_SW_FP_2;
         end
         
         EX_SW_FP_2 : begin
           clrMWE = 1;
           data_src = 2'b00 ;
           BorBfp = 0;
           nxt_state = EX_SW_FP_3;
         end
         
         EX_SW_FP_3:
          PrepareFetch;
         
         
         EX_SW_1: begin
           setMWE = 1;
           SgnExt = 1;
           MARwrt = 1;
           IorD = 2'b01;
           aluSelA = 1;
           aluSelB = 2'b10;
           aluOp = `ADD;
           nxt_state = EX_SW_2;
         end
         
         EX_SW_2 : begin
           clrMWE = 1;
           data_src = (IR[31:26]==6'b101_011)/*sw*/ ? 2'b00 : (IR[31:26]==6'b101_000) ? 2'b01 : 2'b10 ;
           BorBfp = 1;
           nxt_state = EX_SW_3;
         end
         
         EX_SW_3:
          PrepareFetch; 
         
         EX_BRA_1: begin
            aluOp = `SUB;
            aluSelA = 1;
            aluSelB = 2'b00;
            if(aluZero)
              nxt_state = EX_BRA_2;
            else
              PrepareFetch;  
          end
         
         EX_BRA_2: begin
           MARwrt = 1;
           setMRE = 1;
           PCwrt = 1;
		       SgnExt = 1;
           PCsel = 2'b00;
           IorD = 2'b01;   
           MARwrt = 1;
           aluOp =`ADD;
           aluSelA = 0;
           aluSelB = 2'b11;
           nxt_state = FETCH1;
         end
         
         EX_BRA_3: begin
            aluOp = `SUB;
            aluSelA = 1;
            aluSelB = 2'b00;
            if(aluZero)
              PrepareFetch;
            else
              nxt_state = EX_BRA_4;
         end
         
         EX_BRA_4: begin
           MARwrt = 1;
           setMRE = 1;
           PCwrt = 1;
           PCsel = 2'b00;
		       SgnExt = 1;
           IorD = 2'b01;  
           MARwrt = 1; 
           aluOp = `ADD;
           aluSelA = 0;
           aluSelB = 2'b11;
           nxt_state = FETCH1;
         end
		 
		     EX_MULTU:begin
           /*LOwrt = 1;
           HIwrt = 1;
           aluSelA = 1;
           aluSelB = 2'b00;
           PrepareFetch;*/
			     start_mu = 0;
			  if(ready_mu) begin
				   HIwrt = 1;
				   LOwrt = 1;
				   us = 2'b00;
				   PrepareFetch;
				//start_u = 1;
			end
			else
				nxt_state = EX_MULTU;
         end
		 
		 EX_MULT: begin
		 start_ms = 0;
		 if(ready_ms) begin
			HIwrt = 1;
			LOwrt = 1;
			us = 2'b01;
			PrepareFetch;
			//start_s = 1;
		end
			else
				nxt_state = EX_MULT;
		end
		
		EX_FP_MULT: begin
		 start_fp = 0;
		 if(ready_fp) begin
			RegDst_fp = 0;
			RF_fp_wrt = 1;
			MemtoReg_fp = 3'b100;
			PrepareFetch;
		end
			else
				nxt_state = EX_FP_MULT;
		end
		
     /*EX_DIVU: begin
		 start_du = 0;
		 if(ready_du) begin
			HIwrt = 1;
			LOwrt = 1;
			us = 2'b10;
			PrepareFetch;
		end
			else
				nxt_state = EX_DIVU;
		end*/

	EX_DIVU:begin
           /*LOwrt = 1;
           HIwrt = 1;
           aluSelA = 1;
           aluSelB = 2'b00;
           PrepareFetch;*/
			     start_du = 0;
			  if(ready_du) begin
				   HIwrt = 1;
				   LOwrt = 1;
				   us = 2'b10;
				   PrepareFetch;
				//start_u = 1;
			end
			else
				nxt_state = EX_DIVU;
         end
          
     EX_DIV: begin
		 start_ds = 0;
		 if(ready_ds) begin
			HIwrt = 1;
			LOwrt = 1;
			us = 2'b11;
			PrepareFetch;
		end
			else
				nxt_state = EX_DIV;
		end
	 
	 EX_FP_DIV: begin
		start_dfp = 0;
		if(ready_dfp) begin
			RegDst_fp = 0;
			RF_fp_wrt = 1;
			MemtoReg_fp = 3'b101;
			PrepareFetch;
			end
		else
			nxt_state = EX_FP_DIV;
		end
              
		     EX_SHIFTS:begin
		       RFwrt = 1;
		       MemtoReg = 3'b110;
		       RegDst = 2'b01;
		       PrepareFetch;
		     end
		     
		     EX_NEG:begin
		       RF_fp_wrt = 1;
		       MemtoReg_fp = 3'b010;
		       RegDst_fp = 0;
		       PrepareFetch;
		     end
		     
		     EX_ABS:begin
		       RF_fp_wrt = 1;
		       MemtoReg_fp = 3'b011;
		       RegDst_fp = 0;
		       PrepareFetch;
		     end
      endcase
    
   end

endmodule

//==============================================================================

module my_alu2(
   input [2:0] Op,
   input [31:0] A,
   input [31:0] B,

   output [31:0] X,
   output        Z
  // output [63:0] MultOut
);

   wire sub = Op != `ADD;

   wire [31:0] bb = sub ? ~B : B;

   wire [32:0] sum = A + bb + sub;

   wire sltu = ! sum[32];

   wire v = sub ? 
        ( A[31] != B[31] && A[31] != sum[31] )
      : ( A[31] == B[31] && A[31] != sum[31] );

   wire slt = v ^ sum[31];

   reg [31:0] x;

   always @( * )
      case( Op )
         `ADD  : x = sum;
         `SUB  : x = sum;
         `SLT  : x = slt;
         `SLTU : x = sltu;
         `AND  : x =   A & B;
         `OR   : x =   A | B;
         `NOR  : x = ~(A | B);
         `XOR  : x =   A ^ B;
         default : x = 32'hxxxxxxxx;
      endcase

   assign #2 X = x;
   assign #2 Z = x == 32'h00000000;
   // Our poor alu operation
   //assign #2 MultOut = A * B;

endmodule

//==============================================================================

module reg_file(
   input clk,
   input write,
   input [4:0] WR,
   input [31:0] WD,
   input [4:0] RR1,
   input [4:0] RR2,
   output [31:0] RD1,
   output [31:0] RD2
);

   reg [31:0] rf_data [0:31];

   assign #2 RD1 = rf_data[ RR1 ];
   assign #2 RD2 = rf_data[ RR2 ];   

   always @( posedge clk ) begin
      if ( write )
         rf_data[ WR ] <= WD;

      rf_data[0] <= 32'h00000000;
   end

endmodule

//==============================================================================

//our poor Reg_file_fp(fp_unit)
//==============================================================================

module reg_file_fp(
   input clk,
   input write,
   input [4:0] WR,
   input [31:0] WD,
   input [4:0] RR1,
   input [4:0] RR2,
   output [31:0] RD1,
   output [31:0] RD2
);

   reg [31:0] rf_data [0:31];

   assign #2 RD1 = rf_data[ RR1 ];
   assign #2 RD2 = rf_data[ RR2 ];   

   always @( posedge clk ) begin
      if ( write )
         rf_data[ WR ] <= WD;
   end

endmodule

//==============================================================================