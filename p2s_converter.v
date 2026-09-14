// Parallel to Serial converter (P2S)
// Based on professor's solution
// Operates in Sclk domain

module p2s_converter (Sclk, Start, Reset_n, Frame_sync2_pulse,
                      InputParallel, OutputSerial, en_P2S, Load, OutReady);
   input  wire        Sclk, Start, Reset_n, en_P2S, Frame_sync2_pulse, Load;
   input  wire [39:0] InputParallel;
   output wire        OutputSerial;
   output wire        OutReady;

   reg [5:0]  count_bit;
   reg [39:0] register_piso;
   reg [1:0]  curr_state, next_state;

   parameter InitOutput  = 2'b00;
   parameter LoadOutput  = 2'b01;
   parameter ShiftOutput = 2'b10;

   assign OutputSerial = register_piso[39];
   assign OutReady     = (curr_state == ShiftOutput);

   always @(posedge Sclk or posedge Start or negedge Reset_n) begin
      if (Start)
         curr_state <= InitOutput;
      else if (!Reset_n)
         curr_state <= InitOutput;
      else
         curr_state <= next_state;
   end

   always @(*) begin
      next_state = curr_state;
      case (curr_state)
         InitOutput : begin
            if (Load)
               next_state = LoadOutput;
            else
               next_state = InitOutput;
         end
         LoadOutput : begin
            if (Frame_sync2_pulse)
               next_state = ShiftOutput;
            else
               next_state = LoadOutput;
         end
         ShiftOutput : begin
            if (count_bit == 6'd1)
               next_state = InitOutput;
            else
               next_state = ShiftOutput;
         end
      endcase
   end

   always @(posedge Sclk or posedge Start or negedge Reset_n) begin
      if (Start == 1'b1)
         count_bit <= 6'd40;
      else if (Reset_n == 1'b0)
         count_bit <= 6'd40;
      else if (curr_state == ShiftOutput)
         count_bit <= count_bit - 6'b00_0001;
      else
         count_bit <= count_bit;
   end

   always @(posedge Sclk or posedge Start or negedge Reset_n) begin
      if (Start == 1'b1)
         register_piso <= 40'h0000_0000_00;
      else if (Reset_n == 1'b0)
         register_piso <= 40'h0000_0000_00;
      else if (Load & en_P2S)
         register_piso <= InputParallel;
      else if ((curr_state == ShiftOutput) & en_P2S)
         register_piso <= {register_piso[38:0], 1'b0};
      else if (curr_state == InitOutput)
         register_piso <= 40'h0000_0000_00;
      else
         register_piso <= register_piso;
   end

endmodule
