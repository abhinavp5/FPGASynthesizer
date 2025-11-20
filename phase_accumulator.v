// Phase accumulator - accumulates phase using phase increment from ROM
module phase_accumulator #(
    parameter ACC_WIDTH = 24
)(
    input wire clk,
    input wire reset,
    input wire [ACC_WIDTH-1:0] phase_inc_in, // Phase increment from MIDI freq ROM
    output reg  [ACC_WIDTH-1:0] phase = 0
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            phase <= 0;
        else
            phase <= phase + phase_inc_in;
    end

endmodule
