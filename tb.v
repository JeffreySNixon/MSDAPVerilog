`timescale 1ns / 1ps
module tb;
   // Inputs
   reg Dclk;
   reg Sclk;
   reg Reset_n;
   reg Frame;
   reg Start;
   reg InputL, InputR;
   // Outputs
   wire InReady;
   wire OutReady;
   wire OutputL, OutputR;
   // Misc
   integer dataindex=0, input_bitpos=15, out_byte=0;
   integer output_bitpos=40;
   integer output_file;

   msdap_chip uut (
      .Dclk(Dclk),
      .Sclk(Sclk),
      .Reset_n(Reset_n),
      .Frame(Frame),
      .Start(Start),
      .InputL(InputL),
      .InputR(InputR),
      .InReady(InReady),
      .OutReady(OutReady),
      .OutputL(OutputL),
      .OutputR(OutputR));

   reg [15:0] data [0:15055];
   reg [39:0] reg_OutL, reg_OutR;
   reg reset_flag = 0;

   // Plusarg-selectable input/output files
   // Usage: vsim work.tb +IN=data1_final.in +OUT=data1_generated.out
   // Default: data2_final.in / data2_memory_netlist.out
   reg [255:0] in_file;
   reg [255:0] out_file;

   parameter Dclk_Time = 1302;
   parameter Sclk_Time = 30;

   always begin
      #(Dclk_Time) Dclk = ~Dclk;
   end

   always begin
      #(Sclk_Time) Sclk = ~Sclk;
   end

   initial begin
      if (!$value$plusargs("IN=%s",  in_file))  in_file  = "data2_final.in";
      if (!$value$plusargs("OUT=%s", out_file)) out_file = "data2_memory_netlist.out";

      $readmemh (in_file, data);
      output_file = $fopen (out_file, "w+");

      Dclk    = 1;
      Sclk    = 1;
      Frame   = 0;
      InputL  = 0;
      InputR  = 0;
      Reset_n = 1;

      Start = 1'b1;
      #61; Start = 1'b0;
   end

   // Feed inputs from file
   always @(posedge Dclk) begin
      if (dataindex < 15056) begin
         if (((dataindex == 9456) || (dataindex == 13056)) && (reset_flag == 0)) begin
            Reset_n    = 0;
            dataindex  = dataindex + 2;
            reset_flag = 1;
         end
         else if ((InReady) && (reset_flag == 0)) begin
            if (input_bitpos == 15) begin
               Frame        = 1'b1;
               InputL       = data[dataindex][input_bitpos];
               InputR       = data[dataindex+1][input_bitpos];
               input_bitpos <= input_bitpos - 1;
            end
            else if (input_bitpos == 0) begin
               Frame        = 1'b0;
               InputL       = data[dataindex][input_bitpos];
               InputR       = data[dataindex+1][input_bitpos];
               input_bitpos <= 15;
               dataindex    = dataindex + 2;
            end
            else begin
               Frame        = 1'b0;
               InputL       = data[dataindex][input_bitpos];
               InputR       = data[dataindex+1][input_bitpos];
               input_bitpos <= input_bitpos - 1;
            end
         end
         else begin
            Reset_n      = 1;
            reset_flag   = 0;
            InputL       = data[dataindex][input_bitpos];
            InputR       = data[dataindex+1][input_bitpos];
            input_bitpos <= 15;
         end
      end
      else begin
         if (InReady) begin
            if (input_bitpos == 15) begin
               Frame        = 1'b1;
               input_bitpos <= input_bitpos - 1;
            end
            else if (input_bitpos == 0) begin
               Frame        = 1'b0;
               input_bitpos <= 15;
            end
            else begin
               Frame        = 1'b0;
               input_bitpos <= input_bitpos - 1;
            end
         end
      end
   end

   // Capture output
   always @(posedge Sclk) begin
      if (OutReady == 1) begin
         if (output_bitpos > 1) begin
            reg_OutL[output_bitpos-1] = OutputL;
            reg_OutR[output_bitpos-1] = OutputR;
            output_bitpos = output_bitpos - 1;
         end
         else if (output_bitpos == 1) begin
            reg_OutL[output_bitpos-1] = OutputL;
            reg_OutR[output_bitpos-1] = OutputR;
            $fdisplay(output_file, "%010H      %010H", reg_OutL, reg_OutR);
            $display("%d %d, %010H  %010H", out_byte, dataindex, reg_OutL, reg_OutR);
            out_byte      = out_byte + 1;
            output_bitpos = 40;
         end
      end
      else begin
         output_bitpos = 40;
         reg_OutL      = 40'b0;
         reg_OutR      = 40'b0;
      end
   end

   always @(posedge Sclk) begin
      if (out_byte == 6394) begin
         $display("Closing file");
         $fclose(output_file);
         $finish;
      end
   end

endmodule
