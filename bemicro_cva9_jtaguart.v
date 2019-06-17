/*
  Copyright (c) 2015, miya
  Copyright (c) 2019, Tommy Thorn
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
 
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
  FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.  */

module bemicro_cva9_jtaguart
  (
   input        CLK_24MHZ,
   output [7:0] USER_LED
   );

   wire         clock = CLK_24MHZ;
   wire         reset = 0;


   reg          tx_valid = 1;
   wire         tx_ready;
   reg  [7:0]   tx_data = 8'd65;
   wire         rx_valid;
   wire         rx_ready = 1;
   wire [7:0]   rx_data;

   reg [28:0]   sample_period = 1'd0;
   reg [28:0] 	count_tx = 1'd0;
   reg [ 7:0] 	spedometer = 8'd0;

   /* Counting bytes for one seconds gives us B/s, thus counting bytes
      for one us (1e-3) gives us kB/s.  At 24 MHz, we get one ms every
      24,000 ticks.

      To average it out a bit, we run for 1024*24,000 cycles and shift
      the result down.
    
    Meassured with
      nios2-terminal |dd of=/dev/null status=progress bs=65536
    I see ~ 53.0 kB/s
     */

   always @(posedge clock) begin
      if (tx_valid & tx_ready) begin
	 tx_data <= tx_data == 8'd127 ? 8'd32 : tx_data + 8'd1;
	 count_tx <= count_tx + 1'd1;
      end

      if (sample_period[28]) begin
	 spedometer <= count_tx[28:18] ? ~0 : count_tx[17:10];
	 count_tx <= 0;
	 sample_period <= 1024*24000-2;
      end else
	sample_period <= sample_period - 1'd1;

      if (rx_valid) begin
         // XXX Technically isn't allowed.  Should only lower valid once
         // ready is asserted
         tx_valid <= !tx_valid;
      end
   end
   
   axi_jtaguart axi_jtaguart_inst
     ( .clock           (clock)
     , .reset           (reset)

     , .tx_ready        (tx_ready)
     , .tx_valid        (tx_valid)
     , .tx_data         (tx_data)

     , .rx_ready        (rx_ready)
     , .rx_valid        (rx_valid)
     , .rx_data         (rx_data)
     );

  assign {
          USER_LED[0],
          USER_LED[1],
          USER_LED[2],
          USER_LED[3],
          USER_LED[4],
          USER_LED[5],
          USER_LED[6],
          USER_LED[7]
          } = tx_valid ? ~spedometer : 0;
endmodule
