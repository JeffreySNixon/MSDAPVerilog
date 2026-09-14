

module R_MEM(
  input  [3:0]  RW0_addr,
  input         RW0_clk,
  input  [7:0]  RW0_wdata,
  output [7:0]  RW0_rdata,
  input         RW0_en,
  input         RW0_wmode
);
  wire [3:0] mem_0_0_A1;
  wire  mem_0_0_CE1; 
  wire [7:0] mem_0_0_I1;
  wire [7:0] mem_0_0_O1;
  wire  mem_0_0_CSB1;
  wire  mem_0_0_OEB1;
  wire  mem_0_0_WEB1;
  wire [3:0] mem_0_0_A2;
  wire  mem_0_0_CE2;
  wire [7:0] mem_0_0_I2;
  wire [7:0] mem_0_0_O2;
  wire  mem_0_0_CSB2;
  wire  mem_0_0_OEB2;
  wire  mem_0_0_WEB2;
  SRAM2RW16x8 mem_0_0 (
    .A1(mem_0_0_A1),
    .CE1(mem_0_0_CE1),
    .I1(mem_0_0_I1),
    .O1(mem_0_0_O1),
    .CSB1(mem_0_0_CSB1),
    .OEB1(mem_0_0_OEB1),
    .WEB1(mem_0_0_WEB1),
    .A2(mem_0_0_A2),
    .CE2(mem_0_0_CE2),
    .I2(mem_0_0_I2),
    .O2(mem_0_0_O2),
    .CSB2(mem_0_0_CSB2),
    .OEB2(mem_0_0_OEB2),
    .WEB2(mem_0_0_WEB2)
  );
  assign RW0_rdata = mem_0_0_O1;
  assign mem_0_0_A1 = RW0_addr;
  assign mem_0_0_CE1 = RW0_clk;
  assign mem_0_0_I1 = RW0_wdata[7:0];
  assign mem_0_0_CSB1 = ~RW0_en;
  assign mem_0_0_OEB1 = ~(~RW0_wmode & RW0_en);
  assign mem_0_0_WEB1 = ~RW0_wmode;
  assign mem_0_0_A2 = RW0_addr;
  assign mem_0_0_CE2 = 'b1;
  assign mem_0_0_I2 = RW0_wdata[7:0];
  assign mem_0_0_CSB2 = 'b1;
  assign mem_0_0_OEB2 = 'b1;
  assign mem_0_0_WEB2 = 'b1;
endmodule

module CO_MEM(
  input  [8:0]  RW0_addr,
  input         RW0_clk,
  input  [8:0] RW0_wdata,
  output [8:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input Start
);
  wire [11:0] mem_0_O,mem_1_O,mem_2_O,mem_3_O;
  wire mem_OEB;
//   reg mem_OEB_reg;
   
  wire mem_WEB;
  wire mem_0_CSB, mem_1_CSB, mem_2_CSB, mem_3_CSB;
//   reg mem_0_CSB_reg, mem_1_CSB_reg, mem_2_CSB_reg, mem_3_CSB_reg;
  
  SRAM1RW128x12 mem_0_0 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I( {3'b000, RW0_wdata} ),
    .O(mem_0_O),
    .CSB(mem_0_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  SRAM1RW128x12 mem_0_1 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I( {3'b000, RW0_wdata} ),
    .O(mem_1_O),
    .CSB(mem_1_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  SRAM1RW128x12 mem_0_2 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I( {3'b000, RW0_wdata} ),
    .O(mem_2_O),
    .CSB(mem_2_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  SRAM1RW128x12 mem_0_3 (
    .A(RW0_addr[6:0]),
    .CE(RW0_clk),
    .I( {3'b000, RW0_wdata} ),
    .O(mem_3_O),
    .CSB(mem_3_CSB),
    .OEB(mem_OEB),
    .WEB(mem_WEB)
  );
  assign RW0_rdata = {9{~mem_OEB}} & (({9{~mem_0_CSB}} & mem_0_O[8:0]) | ({9{~mem_1_CSB}} & mem_1_O[8:0]) | ({9{~mem_2_CSB}} & mem_2_O[8:0]) | ({9{~mem_3_CSB}} & mem_3_O[8:0]));
  assign mem_OEB = ~(RW0_en & ~RW0_wmode);
  assign mem_WEB = ~(RW0_en & RW0_wmode);

/*   always @(posedge RW0_clk or posedge Start) begin
      if (Start)
	{mem_0_CSB_reg, mem_1_CSB_reg, mem_2_CSB_reg, mem_3_CSB_reg, mem_OEB_reg} <= 5'b00000;
      else
	{mem_0_CSB_reg, mem_1_CSB_reg, mem_2_CSB_reg, mem_3_CSB_reg, mem_OEB_reg} <= {mem_0_CSB, mem_1_CSB, mem_2_CSB, mem_3_CSB, mem_OEB};
   end  */
   
  assign mem_0_CSB = ~(RW0_addr[8:7] == 2'd0);
  assign mem_1_CSB = ~(RW0_addr[8:7] == 2'd1);
  assign mem_2_CSB = ~(RW0_addr[8:7] == 2'd2);
  assign mem_3_CSB = ~(RW0_addr[8:7] == 2'd3);
endmodule

module X_MEM(
  input [7:0] 	RW0_addr,
  input 	RW0_clk,
  input [15:0] 	RW0_wdata,
  output [15:0] RW0_rdata,
  input 	RW0_en,
  input 	RW0_wmode,
  input 	Start,
  input clear,
  output wire all_zeros 	
);
   parameter SLEEP_NUM_ZEROS = 12'd800;
   parameter ClearZeros = 2'b00, IncrementZeros = 2'b01, 
     HoldZeros = 2'b10, HoldMax = 2'b11;
   
   reg [1:0] 			       curr_state, next_state;
   reg [11:0] 			       count_zero;

  wire [7:0] mem_0_0_A;
  wire  mem_0_0_CE;
  wire [7:0] mem_0_0_I;
  wire [7:0] mem_0_0_O;
  wire  mem_0_0_CSB;
  wire  mem_0_0_OEB;
  wire  mem_0_0_WEB;
  wire [7:0] mem_0_1_A;
  wire  mem_0_1_CE;
  wire [7:0] mem_0_1_I;
  wire [7:0] mem_0_1_O;
  wire  mem_0_1_CSB;
  wire  mem_0_1_OEB;
  wire  mem_0_1_WEB;
  SRAM1RW256x8 mem_0_0 (
    .A(mem_0_0_A),
    .CE(mem_0_0_CE),
    .I(mem_0_0_I),
    .O(mem_0_0_O),
    .CSB(mem_0_0_CSB),
    .OEB(mem_0_0_OEB),
    .WEB(mem_0_0_WEB)
  );
  SRAM1RW256x8 mem_0_1 (
    .A(mem_0_1_A),
    .CE(mem_0_1_CE),
    .I(mem_0_1_I),
    .O(mem_0_1_O),
    .CSB(mem_0_1_CSB),
    .OEB(mem_0_1_OEB),
    .WEB(mem_0_1_WEB)
  );
  assign RW0_rdata = {mem_0_1_O,mem_0_0_O};
  assign mem_0_0_A = RW0_addr;
  assign mem_0_0_CE = RW0_clk;
  assign mem_0_0_I = RW0_wdata[7:0];
  assign mem_0_0_CSB = ~RW0_en;
  assign mem_0_0_OEB = ~(~RW0_wmode & RW0_en);
  assign mem_0_0_WEB = ~RW0_wmode;
  assign mem_0_1_A = RW0_addr;
  assign mem_0_1_CE = RW0_clk;
  assign mem_0_1_I = RW0_wdata[15:8];
  assign mem_0_1_CSB = ~RW0_en;
  assign mem_0_1_OEB = ~(~RW0_wmode & RW0_en);
  assign mem_0_1_WEB = ~RW0_wmode;

   assign all_zeros = (curr_state == HoldMax);   
		     
   always @(posedge RW0_clk or posedge Start) begin
      if (Start == 1) 
	curr_state <= ClearZeros;
      else if (clear)
	curr_state <= ClearZeros;
      else
	curr_state <= next_state;
   end

   always @(*) begin // defaults
      next_state = curr_state;
      case (curr_state)
	ClearZeros : begin
	   if ((RW0_wdata == 16'h0000) & RW0_en & RW0_wmode)
	     next_state = IncrementZeros;
	   else
	     next_state = ClearZeros;
	end
	IncrementZeros : begin
	   next_state = HoldZeros;
	end
	HoldZeros : begin
	   if ((RW0_wdata == 16'h0000) & RW0_en & RW0_wmode & (count_zero != SLEEP_NUM_ZEROS))
	     next_state = IncrementZeros;
	   else if ((RW0_wdata != 16'h0000) & RW0_en & RW0_wmode)
	     next_state = ClearZeros;
	   else if ((RW0_wdata == 16'h0000) & RW0_en & RW0_wmode & (count_zero == SLEEP_NUM_ZEROS))
	     next_state = HoldMax;
	   else
	     next_state = HoldZeros;	   
	end
	HoldMax : begin
	   if ((RW0_wdata != 16'h0000) & RW0_en & RW0_wmode)
	     next_state = ClearZeros;
	   else
	     next_state = HoldMax;
	   end
      endcase // case (curr_state)
   end // always @ (*)
      
   // count_zero counters
      always @(posedge RW0_clk or posedge Start) begin
	 if (Start == 1) 
	    count_zero <= 12'd0;
	 else if (clear)
	   count_zero <= 12'd0;
	 else if (curr_state == ClearZeros)
	   count_zero <= 12'd0;
	 else if (curr_state == IncrementZeros)
	   count_zero <= count_zero + 12'd1;
	 else
	   count_zero <= count_zero;
      end

endmodule



