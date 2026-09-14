// Main Controller FSM
// Based on professor's solution

module msdap_controller(input Sclk, Start, Reset_n, Frame,
                        input          input_ready, all_zeros,
                        output wire    Start_sync, Reset_n_sync,
                        output reg     en_S2P, en_P2S, en_ALU, Clear,
                        output reg [3:0]  rj_waddr,
                        output reg [8:0]  coeff_waddr,
                        output reg [7:0]  x_waddr,
                        output reg        rj_enable, coeff_enable, x_enable,
                        output reg        rj_wmode, coeff_wmode, x_wmode,
                        output reg        rj_clear, coeff_clear, x_clear,
                        output reg        InReady, alu_clear, sleep_mode,
                        output wire       clear_zeros, Frame_sync2_pulse);

   reg                rj_load, coeff_load, x_load;
   wire               Frame_sync2;

   reg rj_clearing_done, coeff_clearing_done, x_clearing_done;
   reg rj_loading_done, coeff_loading_done, x_loading_done;
   wire input_ready_sync2;
   wire input_ready_pulse;

   reg [3:0] curr_state, next_state;
   reg [2:0] rj_addr_curr_state,    rj_addr_next_state;
   reg [2:0] coeff_addr_curr_state, coeff_addr_next_state;
   reg [2:0] x_addr_curr_state,     x_addr_next_state;

   parameter [3:0] Initialization  = 4'd0,
                   Wait_for_Rj     = 4'd1, Reading_Rj    = 4'd2,
                   Wait_for_Coeff  = 4'd3, Reading_Coeff = 4'd4,
                   Wait_for_Input  = 4'd5, Reading_Input = 4'd6,
                   Working_mode    = 4'd7, Clearing_mode = 4'd8,
                   Sleeping_mode   = 4'd9;

   assign clear_zeros = (curr_state == Initialization) | (curr_state == Clearing_mode);

   // Main FSM state register
   always @(posedge Sclk or posedge Start_sync) begin
      if (Start_sync == 1)
         curr_state <= Initialization;
      else
         curr_state <= next_state;
   end

   // Main FSM next-state & output logic
   always @(*) begin
      next_state   = curr_state;
      InReady      = 1'b0;
      Clear        = 1'b0;
      en_S2P       = 1'b0;
      en_P2S       = 1'b0;
      en_ALU       = 1'b0;
      rj_enable    = 1'b0;
      coeff_enable = 1'b0;
      x_enable     = 1'b0;
      rj_clear     = 1'b0;
      coeff_clear  = 1'b0;
      x_clear      = 1'b0;
      alu_clear    = 1'b0;
      rj_load      = 1'b0;
      coeff_load   = 1'b0;
      x_load       = 1'b0;
      sleep_mode   = 1'b0;

      case (curr_state)
         Initialization : begin
            Clear        = 1'b1;
            rj_enable    = 1'b1;
            rj_clear     = 1'b1;
            coeff_enable = 1'b1;
            coeff_clear  = 1'b1;
            x_enable     = 1'b1;
            x_clear      = 1'b1;
            if (rj_clearing_done & coeff_clearing_done & x_clearing_done)
               next_state = Wait_for_Rj;
            else
               next_state = Initialization;
         end
         Wait_for_Rj : begin
            InReady  = 1'b1;
            en_S2P   = 1'b1;
            if (Frame_sync2)
               next_state = Reading_Rj;
            else
               next_state = Wait_for_Rj;
         end
         Reading_Rj : begin
            en_S2P    = 1'b1;
            InReady   = 1'b1;
            rj_enable = 1'b1;
            rj_load   = 1'b1;
            if (rj_loading_done)
               next_state = Wait_for_Coeff;
            else
               next_state = Reading_Rj;
         end
         Wait_for_Coeff : begin
            InReady  = 1'b1;
            en_S2P   = 1'b1;
            if (Frame_sync2)
               next_state = Reading_Coeff;
            else
               next_state = Wait_for_Coeff;
         end
         Reading_Coeff : begin
            en_S2P       = 1'b1;
            InReady      = 1'b1;
            coeff_enable = 1'b1;
            coeff_load   = 1'b1;
            if (coeff_loading_done)
               next_state = Wait_for_Input;
            else
               next_state = Reading_Coeff;
         end
         Wait_for_Input : begin
            InReady   = 1'b1;
            en_S2P    = 1'b1;
            alu_clear = 1'b1;
            x_enable  = 1'b1;
            if (Reset_n == 1'b0)
               next_state = Clearing_mode;
            else if (Frame_sync2)
               next_state = Reading_Input;
            else
               next_state = Wait_for_Input;
         end
         Reading_Input : begin
            InReady  = 1'b1;
            en_S2P   = 1'b1;
            x_enable = 1'b1;
            x_load   = 1'b1;
            if (x_loading_done)
               next_state = Working_mode;
            else
               next_state = Reading_Input;
         end
         Working_mode : begin
            InReady      = 1'b1;
            en_S2P       = 1'b1;
            en_ALU       = 1'b1;
            en_P2S       = 1'b1;
            rj_enable    = 1'b1;
            coeff_enable = 1'b1;
            x_enable     = 1'b1;
            x_load       = 1'b1;
            if (Reset_n == 1'b0) begin
               Clear      = 1'b1;
               next_state = Clearing_mode;
            end
            else if (all_zeros == 1'b1)
               next_state = Sleeping_mode;
            else if (x_loading_done) begin
               next_state = Working_mode;
               alu_clear  = 1'b1;
            end
            else
               next_state = Working_mode;
         end
         Clearing_mode : begin
            Clear    = 1'b1;
            x_clear  = 1'b1;
            x_enable = 1'b1;
            if (Reset_n == 1'b0)
               next_state = Clearing_mode;
            else if (x_clearing_done)
               next_state = Wait_for_Input;
            else
               next_state = Clearing_mode;
         end
         Sleeping_mode : begin
            InReady    = 1'b1;
            en_S2P     = 1'b1;
            x_enable   = 1'b1;
            x_load     = 1'b1;
            sleep_mode = 1'b1;
            if (Reset_n == 1'b0)
               next_state = Clearing_mode;
            else if (all_zeros == 1'b0)
               next_state = Working_mode;
            else
               next_state = Sleeping_mode;
         end
      endcase
   end

   // ----------------------------------------------------------------
   // RJ address sub-FSM
   // ----------------------------------------------------------------
   parameter [2:0] Waiting               = 3'd0,
                   Increment_rj_clearing = 3'd1,
                   Clearing_done         = 3'd2,
                   Waiting_input_ready   = 3'd3,
                   Increment_rj_loading  = 3'd4,
                   Loading_done          = 3'd5;

   always @(posedge Sclk or posedge Start_sync) begin
      if (Start_sync == 1)
         rj_addr_curr_state <= Waiting;
      else
         rj_addr_curr_state <= rj_addr_next_state;
   end

   always @(posedge Sclk or posedge Start_sync) begin
      if (Start_sync == 1)
         rj_waddr <= 4'b0000;
      else if (rj_addr_curr_state == Increment_rj_clearing)
         rj_waddr <= rj_waddr + 4'b0001;
      else if (rj_addr_curr_state == Increment_rj_loading)
         rj_waddr <= rj_waddr + 4'b0001;
      else
         rj_waddr <= rj_waddr;
   end

   always @(*) begin
      rj_addr_next_state = rj_addr_curr_state;
      rj_clearing_done   = 1'b0;
      rj_loading_done    = 1'b0;
      rj_wmode           = 1'b0;
      case (rj_addr_curr_state)
         Waiting : begin
            if (rj_clear)
               rj_addr_next_state = Increment_rj_clearing;
            else
               rj_addr_next_state = Waiting;
         end
         Increment_rj_clearing : begin
            rj_wmode = 1'b1;
            if (rj_waddr == 4'b1111)
               rj_addr_next_state = Clearing_done;
            else
               rj_addr_next_state = Increment_rj_clearing;
         end
         Clearing_done : begin
            rj_wmode         = 1'b0;
            rj_clearing_done = 1'b1;
            if (rj_load)
               rj_addr_next_state = Waiting_input_ready;
            else
               rj_addr_next_state = Clearing_done;
         end
         Waiting_input_ready : begin
            if (input_ready_pulse == 1'b1)
               rj_addr_next_state = Increment_rj_loading;
            else
               rj_addr_next_state = Waiting_input_ready;
         end
         Increment_rj_loading : begin
            rj_wmode = 1'b1;
            if (rj_waddr == 4'b1111)
               rj_addr_next_state = Loading_done;
            else
               rj_addr_next_state = Waiting_input_ready;
         end
         Loading_done : begin
            rj_wmode        = 1'b0;
            rj_loading_done = 1'b1;
            rj_addr_next_state = Waiting;
         end
      endcase
   end

   // ----------------------------------------------------------------
   // COEFF address sub-FSM
   // ----------------------------------------------------------------
   parameter [2:0] Waiting_coeff              = 3'd0,
                   Increment_coeff_clearing   = 3'd1,
                   Clearing_coeff_done        = 3'd2,
                   Waiting_coeff_input_ready  = 3'd3,
                   Increment_coeff_loading    = 3'd4,
                   Loading_coeff_done         = 3'd5;

   always @(posedge Sclk or posedge Start_sync) begin
      if (Start_sync == 1)
         coeff_addr_curr_state <= Waiting_coeff;
      else
         coeff_addr_curr_state <= coeff_addr_next_state;
   end

   always @(posedge Sclk or posedge Start_sync) begin
      if (Start_sync)
         coeff_waddr <= 9'b0000_0000_0;
      else if (coeff_addr_curr_state == Increment_coeff_clearing)
         coeff_waddr <= coeff_waddr + 9'b0000_0000_1;
      else if (coeff_addr_curr_state == Increment_coeff_loading)
         coeff_waddr <= coeff_waddr + 9'b0000_0000_1;
      else
         coeff_waddr <= coeff_waddr;
   end

   always @(*) begin
      coeff_addr_next_state = coeff_addr_curr_state;
      coeff_clearing_done   = 1'b0;
      coeff_loading_done    = 1'b0;
      coeff_wmode           = 1'b0;
      case (coeff_addr_curr_state)
         Waiting_coeff : begin
            if (coeff_clear)
               coeff_addr_next_state = Increment_coeff_clearing;
            else
               coeff_addr_next_state = Waiting_coeff;
         end
         Increment_coeff_clearing : begin
            coeff_wmode = 1'b1;
            if (coeff_waddr == 9'b1111_1111_1)
               coeff_addr_next_state = Clearing_coeff_done;
            else
               coeff_addr_next_state = Increment_coeff_clearing;
         end
         Clearing_coeff_done : begin
            coeff_wmode         = 1'b0;
            coeff_clearing_done = 1'b1;
            if (coeff_load)
               coeff_addr_next_state = Waiting_coeff_input_ready;
            else
               coeff_addr_next_state = Clearing_coeff_done;
         end
         Waiting_coeff_input_ready : begin
            if (input_ready_pulse == 1'b1)
               coeff_addr_next_state = Increment_coeff_loading;
            else
               coeff_addr_next_state = Waiting_coeff_input_ready;
         end
         Increment_coeff_loading : begin
            coeff_wmode = 1'b1;
            if (coeff_waddr == 9'b1111_1111_1)
               coeff_addr_next_state = Loading_coeff_done;
            else
               coeff_addr_next_state = Waiting_coeff_input_ready;
         end
         Loading_coeff_done : begin
            coeff_wmode        = 1'b0;
            coeff_loading_done = 1'b1;
            coeff_addr_next_state = Waiting_coeff;
         end
      endcase
   end

   // ----------------------------------------------------------------
   // X address sub-FSM
   // ----------------------------------------------------------------
   parameter [2:0] Waiting_x             = 3'd0,
                   Increment_x_clearing  = 3'd1,
                   Clearing_x_done       = 3'd2,
                   Waiting_x_input_ready = 3'd3,
                   Increment_x_loading   = 3'd4,
                   Loading_x_done        = 3'd5;

   always @(posedge Sclk or posedge Start_sync or negedge Reset_n_sync) begin
      if (Start_sync == 1)
         x_addr_curr_state <= Waiting_x;
      else if (!Reset_n_sync)
         x_addr_curr_state <= Waiting_x;
      else
         x_addr_curr_state <= x_addr_next_state;
   end

   always @(posedge Sclk or posedge Start_sync or negedge Reset_n_sync) begin
      if (Start_sync == 1)
         x_waddr <= 8'b0000_0000;
      else if (!Reset_n_sync)
         x_waddr <= 8'b0000_0000;
      else if (x_addr_curr_state == Increment_x_clearing)
         x_waddr <= x_waddr + 8'b0000_0001;
      else if (x_addr_curr_state == Increment_x_loading)
         x_waddr <= x_waddr + 8'b0000_0001;
      else
         x_waddr <= x_waddr;
   end

   always @(*) begin
      x_addr_next_state = x_addr_curr_state;
      x_clearing_done   = 1'b0;
      x_loading_done    = 1'b0;
      x_wmode           = 1'b0;
      case (x_addr_curr_state)
         Waiting_x : begin
            if (x_clear)
               x_addr_next_state = Increment_x_clearing;
            else
               x_addr_next_state = Waiting_x;
         end
         Increment_x_clearing : begin
            x_wmode = 1'b1;
            if (x_waddr == 8'b1111_1111)
               x_addr_next_state = Clearing_x_done;
            else
               x_addr_next_state = Increment_x_clearing;
         end
         Clearing_x_done : begin
            x_wmode         = 1'b0;
            x_clearing_done = 1'b1;
            if (x_load)
               x_addr_next_state = Waiting_x_input_ready;
            else
               x_addr_next_state = Clearing_x_done;
         end
         Waiting_x_input_ready : begin
            if (input_ready_pulse == 1'b1)
               x_addr_next_state = Increment_x_loading;
            else
               x_addr_next_state = Waiting_x_input_ready;
         end
         Increment_x_loading : begin
            x_wmode = 1'b1;
            x_addr_next_state = Loading_x_done;
         end
         Loading_x_done : begin
            x_wmode        = 1'b0;
            x_loading_done = 1'b1;
            x_addr_next_state = Waiting_x_input_ready;
         end
      endcase
   end

   // ----------------------------------------------------------------
   // CDC Synchronizers
   // ----------------------------------------------------------------
   dff_sync2_pulse dff_sync2_0(.clk(Sclk), .rst(Start_sync), .d(Frame),
                                .q_synced(Frame_sync2),
                                .q_synced_pulse(Frame_sync2_pulse));

   dff_sync2_pulse dff_sync2_1(.clk(Sclk), .rst(Start_sync), .d(input_ready),
                                .q_synced(input_ready_sync2),
                                .q_synced_pulse(input_ready_pulse));

   reset_synchronizer_neg reset_n_sync2_0(.clk(Sclk), .rst_n_async(Reset_n),
                                          .rst_n_sync(Reset_n_sync));

   reset_synchronizer_pos start_sync2_0(.clk(Sclk), .rst_async(Start),
                                        .rst_sync(Start_sync));

endmodule


// ----------------------------------------------------------------
// CDC helper modules
// ----------------------------------------------------------------
module dff_sync2_pulse(
   input  clk,
   input  rst,
   input  d,
   output wire q_synced,
   output wire q_synced_pulse
);
   reg sync_flop1, sync_flop2, sync_flop3;

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         sync_flop1 <= 1'b0;
         sync_flop2 <= 1'b0;
         sync_flop3 <= 1'b0;
      end
      else begin
         sync_flop1 <= d;
         sync_flop2 <= sync_flop1;
         sync_flop3 <= sync_flop2;
      end
   end

   assign q_synced       = sync_flop2;
   assign q_synced_pulse = ~sync_flop3 & sync_flop2;
endmodule


module dff_sync2(
   input  clk,
   input  rst,
   input  d,
   output wire q_synced
);
   reg sync_flop1, sync_flop2;

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         sync_flop1 <= 1'b0;
         sync_flop2 <= 1'b0;
      end
      else begin
         sync_flop1 <= d;
         sync_flop2 <= sync_flop1;
      end
   end

   assign q_synced = sync_flop2;
endmodule


module reset_synchronizer_neg (
   input  wire clk,
   input  wire rst_n_async,
   output wire rst_n_sync
);
   reg [1:0] sync_ff;

   always @(posedge clk or negedge rst_n_async) begin
      if (!rst_n_async)
         sync_ff <= 2'b00;
      else
         sync_ff <= {sync_ff[0], 1'b1};
   end

   assign rst_n_sync = sync_ff[1];
endmodule


module reset_synchronizer_pos (
   input  wire clk,
   input  wire rst_async,
   output wire rst_sync
);
   reg [1:0] sync_ff;

   always @(posedge clk or posedge rst_async) begin
      if (rst_async)
         sync_ff <= 2'b11;
      else
         sync_ff <= {sync_ff[0], 1'b0};
   end

   assign rst_sync = sync_ff[1];
endmodule
