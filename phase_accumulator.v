//   phase_inc = freq_in * 2^ACC_WIDTH / CLK_FREQ
module phase_accumulator #(
    parameter ACC_WIDTH = 32,
    parameter CLK_FREQ  = 50_000_000
)(
    input wire clk,
    input wire reset,
    input wire [31:0] freq_in, // Hz from the MIDI freq ROM
    output reg  [ACC_WIDTH-1:0] phase = 0,
    output wire [ACC_WIDTH-1:0] phase_inc
);

    assign phase_inc = (freq_in << ACC_WIDTH) / CLK_FREQ;

    always @(posedge clk or posedge reset) begin
        if (reset)
            phase <= 0;
        else
            phase <= phase + phase_inc;
    end

endmodule