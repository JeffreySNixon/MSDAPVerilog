/* MSDAP top-level - dual channel */
/* Based on professor's solution */

module msdap_chip (Dclk, Sclk, Reset_n, Frame, Start, InputL, InputR, InReady, OutReady, OutputL, OutputR);
   input Dclk, Sclk, Reset_n, Frame, Start;
   input InputL, InputR;
   output    InReady, OutReady, OutputL, OutputR;

   wire [15:0] OutputL_S2P, OutputR_S2P;
   wire [39:0] InputL_P2S, InputR_P2S;
   wire        input_readyL, input_readyR;
   wire        en_S2P, en_P2S, en_ALU;
   wire [3:0]  rj_waddr, rj_raddrL, rj_raddrR, rj_addrL, rj_addrR;
   wire [8:0]  coeff_waddr, coeff_raddrL, coeff_raddrR, coeff_addrL, coeff_addrR;
   wire [7:0]  x_waddr, x_raddrL, x_raddrR, x_addrL, x_addrR;
   wire        rj_wmode, coeff_wmode, x_wmode;
   wire        rj_enable, coeff_enable, x_enable;
   wire        rj_clear, coeff_clear, x_clear;
   wire [15:0] rj_out_databusL, coeff_out_databusL, x_out_databusL;
   wire [15:0] rj_out_databusR, coeff_out_databusR, x_out_databusR;
   wire        alu_clear;
   wire        all_zerosL, all_zerosR, all_zeros, doneL, doneR;
   wire [7:0]  n_mod_256;
   wire        Frame_sync2_pulse;
   wire        clear_zeros, sleep_mode;
   wire        OutReadyL, OutReadyR;
   wire        Clear, Start_sync, Reset_n_sync;

   assign n_mod_256 = x_waddr - 8'b0000_0001;

   // MSDAP ALU
   msdap_alu ALU_L (.Sclk(Sclk), .en_ALU(en_ALU), .Start(Start_sync),
                    .clear(~Reset_n_sync|alu_clear|sleep_mode),
                    .rj(rj_out_databusL), .coeff(coeff_out_databusL),
                    .x(x_out_databusL), .n_mod_256(n_mod_256),
                    .rj_address(rj_raddrL), .coeff_address(coeff_raddrL),
                    .x_address(x_raddrL), .y(InputL_P2S), .done(doneL));
   msdap_alu ALU_R (.Sclk(Sclk), .en_ALU(en_ALU), .Start(Start_sync),
                    .clear(~Reset_n_sync|alu_clear|sleep_mode),
                    .rj(rj_out_databusR), .coeff(coeff_out_databusR),
                    .x(x_out_databusR), .n_mod_256(n_mod_256),
                    .rj_address(rj_raddrR), .coeff_address(coeff_raddrR),
                    .x_address(x_raddrR), .y(InputR_P2S), .done(doneR));

   // Interfaces
   s2p_converter S2PL(.Frame(Frame), .Dclk(Dclk),
                      .Start(Start_sync),
                      .Reset_n(Reset_n),
                      .InputSerial(InputL),
                      .OutputParallel(OutputL_S2P), .en_S2P(en_S2P),
                      .input_ready(input_readyL));
   s2p_converter S2PR(.Frame(Frame), .Dclk(Dclk),
                      .Start(Start_sync),
                      .Reset_n(Reset_n),
                      .InputSerial(InputR),
                      .OutputParallel(OutputR_S2P), .en_S2P(en_S2P),
                      .input_ready(input_readyR));

   p2s_converter P2SL(.Sclk(Sclk), .Start(Start_sync), .Reset_n(Reset_n_sync),
                      .Frame_sync2_pulse(Frame_sync2_pulse),
                      .InputParallel(InputL_P2S), .OutputSerial(OutputL),
                      .en_P2S(en_P2S), .Load(doneL), .OutReady(OutReadyL));
   p2s_converter P2SR(.Sclk(Sclk), .Start(Start_sync), .Reset_n(Reset_n_sync),
                      .Frame_sync2_pulse(Frame_sync2_pulse),
                      .InputParallel(InputR_P2S), .OutputSerial(OutputR),
                      .en_P2S(en_P2S), .Load(doneR), .OutReady(OutReadyR));

   assign OutReady = OutReadyL | OutReadyR;

   // Left Channel Memories
   assign rj_addrL = rj_wmode ? rj_waddr : Clear ? 4'b0000 : rj_raddrL;
   rj_memory RJMEML(.enable(rj_enable), .Sclk(Sclk), .wmode(rj_wmode),
                    .write_data(~{16{rj_clear}} & OutputL_S2P & {16{rj_wmode}}),
                    .addr(rj_addrL),
                    .read_data(rj_out_databusL));

   assign coeff_addrL = coeff_wmode ? coeff_waddr : Clear ? 9'b0000_0000_0 : coeff_raddrL;
   coeff_memory COEFFMEML(.enable(coeff_enable), .Sclk(Sclk), .wmode(coeff_wmode),
                          .write_data(~{16{coeff_clear}} & OutputL_S2P & {16{coeff_wmode}}),
                          .addr(coeff_addrL),
                          .read_data(coeff_out_databusL));

   assign x_addrL = x_wmode ? x_waddr : Clear ? 8'b0000_0000 : x_raddrL;
   data_memory XMEML(.enable(x_enable), .Sclk(Sclk), .wmode(x_wmode), .Start(Start),
                     .write_data(~{16{x_clear}} & OutputL_S2P & {16{x_wmode}}),
                     .addr(x_addrL), .clear(clear_zeros),
                     .read_data(x_out_databusL), .all_zeros(all_zerosL));

   // Right Channel Memories
   assign rj_addrR = rj_wmode ? rj_waddr : Clear ? 4'b0000 : rj_raddrR;
   rj_memory RJMEMR(.enable(rj_enable), .Sclk(Sclk), .wmode(rj_wmode),
                    .write_data(~{16{rj_clear}} & OutputR_S2P & {16{rj_wmode}}),
                    .addr(rj_addrR),
                    .read_data(rj_out_databusR));

   assign coeff_addrR = coeff_wmode ? coeff_waddr : Clear ? 9'b0000_0000 : coeff_raddrR;
   coeff_memory COEFFMEMR(.enable(coeff_enable), .Sclk(Sclk), .wmode(coeff_wmode),
                          .write_data(~{16{coeff_clear}} & OutputR_S2P & {16{coeff_wmode}}),
                          .addr(coeff_addrR),
                          .read_data(coeff_out_databusR));

   assign x_addrR = x_wmode ? x_waddr : Clear ? 8'b0000_0000 : x_raddrR;
   data_memory XMEMR(.enable(x_enable), .Sclk(Sclk), .wmode(x_wmode), .Start(Start),
                     .write_data(~{16{x_clear}} & OutputR_S2P & {16{x_wmode}}),
                     .addr(x_addrR), .clear(clear_zeros),
                     .read_data(x_out_databusR), .all_zeros(all_zerosR));

   assign all_zeros = all_zerosR & all_zerosL;

   // Main Controller
   msdap_controller MC0(.Sclk(Sclk), .Start(Start), .Clear(Clear),
                        .Reset_n(Reset_n), .Frame(Frame),
                        .Start_sync(Start_sync), .Reset_n_sync(Reset_n_sync),
                        .input_ready(input_readyL),
                        .all_zeros(all_zeros),
                        .en_S2P(en_S2P), .en_P2S(en_P2S),
                        .en_ALU(en_ALU),
                        .rj_waddr(rj_waddr), .coeff_waddr(coeff_waddr),
                        .x_waddr(x_waddr), .rj_enable(rj_enable),
                        .coeff_enable(coeff_enable), .x_enable(x_enable),
                        .rj_wmode(rj_wmode), .coeff_wmode(coeff_wmode),
                        .x_wmode(x_wmode), .rj_clear(rj_clear),
                        .coeff_clear(coeff_clear), .x_clear(x_clear),
                        .alu_clear(alu_clear), .clear_zeros(clear_zeros),
                        .InReady(InReady), .sleep_mode(sleep_mode),
                        .Frame_sync2_pulse(Frame_sync2_pulse));

endmodule
