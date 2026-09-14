// Serial to Parallel converter (S2P)
// Based on professor's solution
// Operates in Dclk domain

module s2p_converter (Frame, Dclk, Start, Reset_n, InputSerial,
                      OutputParallel, en_S2P, input_ready);
   input  wire Frame, Dclk, Start, Reset_n, InputSerial, en_S2P;
   output reg  [15:0] OutputParallel;
   output wire        input_ready;

   reg [3:0] count_bit;
   reg       shift_en;
   wire      Start_sync, Reset_n_sync;

   assign input_ready = count_bit == 4'b0000 & en_S2P;

   always @(negedge Dclk or posedge Start_sync or negedge Reset_n_sync) begin
      if (Start_sync == 1) begin
         shift_en  <= 1'b0;
         count_bit <= 4'd15;
      end
      else if (Reset_n_sync == 1'b0) begin
         shift_en  <= 1'b0;
         count_bit <= 4'd15;
      end
      else if (Frame == 1'b1 & en_S2P) begin
         shift_en  <= 1'b1;
         count_bit <= 4'd15;
      end
      else if (count_bit == 4'b0 & en_S2P) begin
         shift_en  <= 0;
         count_bit <= 4'd15;
      end
      else if (count_bit != 4'b0 & en_S2P) begin
         shift_en  <= 1'b1;
         count_bit <= count_bit - 4'b0001;
      end
      else begin
         shift_en  <= 1'b0;
         count_bit <= 4'd15;
      end
   end

   always @(negedge Dclk or posedge Start_sync or negedge Reset_n_sync) begin
      if (Start_sync == 1'b1)
         OutputParallel <= 16'h0000;
      else if (Reset_n_sync == 1'b0)
         OutputParallel <= 16'h0000;
      else if ((shift_en == 1'b1) & en_S2P)
         OutputParallel <= {OutputParallel[14:0], InputSerial};
      else if ((Frame == 1'b1) & en_S2P)
         OutputParallel <= {15'h0000, InputSerial};
      else
         OutputParallel <= OutputParallel;
   end

   // Reset synchronizers in Dclk domain
   reset_synchronizer_neg reset_n_sync2_0(.clk(Dclk), .rst_n_async(Reset_n),
                                          .rst_n_sync(Reset_n_sync));
   reset_synchronizer_pos start_sync2_0(.clk(Dclk), .rst_async(Start),
                                        .rst_sync(Start_sync));

endmodule
