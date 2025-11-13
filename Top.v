module Top (
    input  i_Clk,
    input  i_RX_Serial,
    output S1_A,
    output S1_B,
    output S1_C,
    output S1_D,
    output S1_E,
    output S1_F,
    output S1_G,
    output S2_A,
    output S2_B,
    output S2_C,
    output S2_D,
    output S2_E,
    output S2_F,
    output S2_G
);

  wire [7:0] w_byte;
  wire w_dv;
  reg [7:0] r_byte = 8'b0;

  always @(posedge i_Clk) begin
    if (w_dv) r_byte <= w_byte;
  end

  UART_RX uart_reader (
      .i_Clk(i_Clk),
      .i_RX_Serial(i_RX_Serial),
      .o_RX_DV(w_dv),
      .o_RX_Byte(w_byte)
  );

  SevenSegDisplay ssd_out (
      .i_byte(r_byte),
      .S1_A  (S2_A),
      .S1_B  (S2_B),
      .S1_C  (S2_C),
      .S1_D  (S2_D),
      .S1_E  (S2_E),
      .S1_F  (S2_F),
      .S1_G  (S2_G),
      .S2_A  (S1_A),
      .S2_B  (S1_B),
      .S2_C  (S1_C),
      .S2_D  (S1_D),
      .S2_E  (S1_E),
      .S2_F  (S1_F),
      .S2_G  (S1_G)
  );

endmodule
