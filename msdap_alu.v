/* MSDAP ALU - single channel instance */
/* Based on professor's solution       */

module msdap_alu (Sclk, en_ALU, Start, clear, rj, coeff, x, n_mod_256,
                  rj_address, coeff_address, x_address, y, done);
   input  Sclk, en_ALU, Start, clear;
   input  [15:0] rj, coeff, x;
   input  [7:0]  n_mod_256;
   output [3:0]  rj_address;
   output [8:0]  coeff_address;
   output [7:0]  x_address;
   output wire [39:0] y;
   output             done;

   wire shift_en;
   wire load, add_sub;
   wire [3:0] rj_address;
   wire [8:0] coeff_address;
   wire [7:0] x_address;
   wire       done;

   ALU_controller AC0(.Sclk(Sclk), .en_ALU(en_ALU), .Start(Start),
                      .clear(clear),
                      .rj(rj), .coeff(coeff), .n_mod_256(n_mod_256),
                      .rj_address(rj_address),
                      .coeff_address(coeff_address),
                      .x_address(x_address),
                      .shift_en(shift_en), .load(load),
                      .add_sub(add_sub), .done(done));

   ALU_datapath AD0(.Sclk(Sclk), .Start(Start), .x(x), .clear(clear),
                    .add_sub(add_sub),
                    .shift_en(shift_en), .load(load), .y(y));

endmodule


module ALU_controller (Sclk, en_ALU, Start, clear, rj, coeff, n_mod_256,
                       rj_address, coeff_address, x_address,
                       shift_en, load, add_sub, done);
   input  Sclk, en_ALU, clear, Start;
   input  [15:0] rj, coeff;
   input  [7:0]  n_mod_256;
   output reg [3:0]  rj_address;
   output reg [8:0]  coeff_address;
   output wire [7:0] x_address;
   output reg        shift_en, load;
   output wire       add_sub, done;

   reg [1:0] curr_state, next_state;
   reg [8:0] coeff_address_j;
   reg       clear_coeff;
   reg       coeff_increment, rj_increment;
   wire [8:0] x_address_9;

   localparam COMPUTE_U = 2'b01;
   localparam SHIFT     = 2'b10;
   localparam DONE      = 2'b11;

   always @(posedge Sclk or posedge Start) begin
      if (Start == 1)
         curr_state <= COMPUTE_U;
      else if (clear)
         curr_state <= COMPUTE_U;
      else
         curr_state <= next_state;
   end

   always @(*) begin
      next_state      = curr_state;
      shift_en        = 1'b0;
      clear_coeff     = 1'b0;
      rj_increment    = 1'b0;
      coeff_increment = 1'b0;
      load            = 1'b0;

      case (curr_state)
         COMPUTE_U : begin
            if ((coeff_address_j == (rj[8:0]-1)) & (coeff_address != 9'b1111_1111_1) & en_ALU) begin
               next_state      = COMPUTE_U;
               shift_en        = 1'b1;
               clear_coeff     = 1'b1;
               rj_increment    = 1'b1;
               coeff_increment = 1'b1;
               load            = 1'b1;
            end
            else if ((coeff_address_j == (rj[8:0]-1)) & (coeff_address == 9'b1111_1111_1) & en_ALU) begin
               next_state  = DONE;
               shift_en    = 1'b1;
               clear_coeff = 1'b1;
               load        = 1'b1;
            end
            else if (en_ALU) begin
               load            = 1'b1;
               coeff_increment = 1'b1;
               next_state      = COMPUTE_U;
            end
         end
         DONE : begin
            if (en_ALU)
               next_state = COMPUTE_U;
            else
               next_state = DONE;
         end
      endcase
   end

   assign add_sub    = coeff[8];
   assign x_address_9 = ({1'b1, n_mod_256} - {1'b0, coeff[7:0]});
   assign x_address  = clear ? 8'b0000_0000 : x_address_9[7:0];
   assign done       = (curr_state == DONE);

   always @(posedge Sclk or posedge Start) begin
      if (Start == 1)
         rj_address <= 3'b000;
      else if (clear)
         rj_address <= 3'b000;
      else if (en_ALU && rj_increment)
         rj_address <= rj_address + 4'b0001;
      else
         rj_address <= rj_address;
   end

   always @(posedge Sclk or posedge Start) begin
      if (Start == 1)
         coeff_address <= 9'b0_0000_0000;
      else if (clear)
         coeff_address <= 9'b0_0000_0000;
      else if (en_ALU && coeff_increment)
         coeff_address <= coeff_address + 9'b0000_0000_1;
      else
         coeff_address <= coeff_address;
   end

   always @(posedge Sclk or posedge Start) begin
      if (Start == 1)
         coeff_address_j <= 9'b0_0000_0000;
      else if (clear || clear_coeff)
         coeff_address_j <= 9'b0_0000_0000;
      else if (en_ALU && coeff_increment)
         coeff_address_j <= coeff_address_j + 8'b0000_0001;
      else
         coeff_address_j <= coeff_address_j;
   end

endmodule


module ALU_datapath(Sclk, Start, x, clear, add_sub, shift_en, load, y);
   input [15:0] x;
   input        Sclk, Start, add_sub, shift_en, load, clear;
   output reg [39:0] y;

   wire [23:0] x24;
   wire [23:0] add_sub_out;

   assign x24[23:16]  = {8{x[15]}};
   assign x24[15:0]   = x;
   assign add_sub_out = add_sub ? y[39:16] - x24 : y[39:16] + x24;

   always @(posedge Sclk or posedge Start) begin
      if (Start == 1)
         y <= 0;
      else if (clear)
         y <= 0;
      else if (load)
         y <= shift_en ? {add_sub_out[23], add_sub_out[23:0], y[15:1]}
                       : {add_sub_out, y[15:0]};
      else
         y <= y;
   end

endmodule
