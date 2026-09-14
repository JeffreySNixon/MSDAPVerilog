/* rj_memory - 16 x 16-bit                     */
/* Uses single R_MEM (SRAM2RW16x8) macro        */
/* R_MEM is 8-bit wide - upper 8 bits unused    */
/* rj values are small (max 9-bit), fits in 8b  */

module rj_memory (input wire enable, Sclk, wmode,
                  input wire [15:0] write_data,
                  input wire [3:0]  addr,
                  output wire [15:0] read_data);

   wire [7:0] rdata;

   R_MEM rj_mem (
      .RW0_addr  (addr),
      .RW0_clk   (Sclk),
      .RW0_wdata (write_data[7:0]),
      .RW0_rdata (rdata),
      .RW0_en    (enable),
      .RW0_wmode (wmode)
   );

   // Upper 8 bits sign-extended from bit 7
   assign read_data = {{8{rdata[7]}}, rdata};

endmodule
