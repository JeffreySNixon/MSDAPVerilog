/* data_memory - 256 x 16-bit                        */
/* Wraps X_MEM (ASAP7 SRAM1RW256x8 x2)               */
/* X_MEM already contains all_zeros sleep logic       */

module data_memory (input wire enable, Sclk, wmode, clear, Start,
                    input wire [15:0] write_data,
                    input wire [7:0]  addr,
                    output wire [15:0] read_data,
                    output wire        all_zeros);

   X_MEM xmem (
      .RW0_addr  (addr),
      .RW0_clk   (Sclk),
      .RW0_wdata (write_data),
      .RW0_rdata (read_data),
      .RW0_en    (enable),
      .RW0_wmode (wmode),
      .Start     (Start),
      .clear     (clear),
      .all_zeros (all_zeros)
   );

endmodule
