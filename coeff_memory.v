/* coeff_memory - 512 x 16-bit                  */
/* Uses single CO_MEM (SRAM1RW128x12 x4) macro  */
/* CO_MEM is 9-bit wide                         */
/* coeff values use 9 bits: [8]=add_sub, [7:0]=x_addr */

module coeff_memory (input wire enable, Sclk, wmode,
                     input wire [15:0] write_data,
                     input wire [8:0]  addr,
                     output wire [15:0] read_data);

   wire [8:0] rdata;

   CO_MEM coeff_mem (
      .RW0_addr  (addr),
      .RW0_clk   (Sclk),
      .RW0_wdata (write_data[8:0]),
      .RW0_rdata (rdata),
      .RW0_en    (enable),
      .RW0_wmode (wmode),
      .Start     (1'b0)
   );

   // Upper 7 bits zero-padded
   assign read_data = {7'b0, rdata};

endmodule
