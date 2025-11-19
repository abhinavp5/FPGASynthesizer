module synth_top #(
    parameter integer ACC_WIDTH = 16,
    parameter integer DAC_WIDTH = 12,
    parameter integer CLK_FREQ  = 50_000_000
    parameter integer SIN_ADDR_BITS = 8
)(
    input  wire i_Clk,
    input  wire reset,
    // input  wire [31:0] note_freq, // integer Hz (e.g., 440 for A4)
    input  wire [1:0] waveform_sel, // 00=sawtooth, 01=square, 10=triangle, 11=sine
    output wire [DAC_WIDTH-1:0] audio_out
);
    
    
    //UART Receiver for MIDI
    wire rx_dv;
    wire [7:0] rx_byte;
    //IMPORTANT:
    //UART defaults to CLKS_PER_BIT = 217.
    //If system clock is different, change it here.
    UART_RX #(
        .CLKS_PER_BIT(217) //<<< match FPGA clock & MIDI baud
    ) uart_rx_inst (
        .i_Clk(i_Clk), //NOTE: not rst
        .i_RX_Serial(midi_in),
        .o_RX_DV(rx_dv),
        .o_RX_Byte(rx_byte)
    );

    //midi interpreter
    midi_interpreter midi_inst (
        .clk(i_Clk),
        .rst(rst),

        .rx_dv(rx_dv),
        .rx_byte(rx_byte),

        .note_on(note_on),
        .note_off(note_off),
        .current_note(current_note),
        .freq_out(freq),
        .note_valid(note_valid)
    );

    // phase accumulator
    wire [ACC_WIDTH-1:0] phase_inc;
    assign phase_inc = (freq_in << ACC_WIDTH) / CLK_FREQ;

    // // Generate phase increment from desired frequency
    // wire [ACC_WIDTH-1:0] phase_inc;
    // phase_accumulator #(
    //     .ACC_WIDTH(ACC_WIDTH),
    //     .CLK_FREQ(CLK_FREQ)
    // ) phase_acc (
    //     .clk(i_Clk),
    //     .reset(rst),
    //     .freq_in(freq),
    //     .phase(phase),
    //     .phase_inc(phase_inc)
    // );

    // Four phase accumulators (current state logic)
    reg [ACC_WIDTH-1:0] phase_saw, phase_sq, phase_tri, phase_sin;

    always @(posedge i_Clk or posedge reset) begin
        if (reset) begin
            phase_saw <= 0;
            phase_sq  <= 0;
            phase_tri <= 0;
            phase_sin <= 0;
        end else begin
            phase_saw <= phase_saw + phase_inc;
            phase_sq  <= phase_sq  + phase_inc;
            phase_tri <= phase_tri + phase_inc;
            phase_sin <= phase_sin + phase_inc;
        end
    end

    // Waveform generation (phase -> amplitude conversion)
    wire [DAC_WIDTH-1:0] saw_out   = phase_saw[ACC_WIDTH-1 -: DAC_WIDTH];
    wire [DAC_WIDTH-1:0] square_out = phase_sq[ACC_WIDTH-1] ? (DAC_WIDTH-1) : 0;
    wire [DAC_WIDTH-1:0] tri_out   = phase_tri[ACC_WIDTH-1] ?
                                     ~phase_tri[ACC_WIDTH-2 -: DAC_WIDTH] :
                                      phase_tri[ACC_WIDTH-2 -: DAC_WIDTH];

    // Sine wave lookup ROM
    wire [DAC_WIDTH-1:0] sine_out;
    sine_rom #(
        .ADDR_BITS(SIN_ADDR_BITS),
        .DATA_BITS(DAC_WIDTH)
    ) sine_table (
        .clk(i_Clk),
        .addr(phase_sin[ACC_WIDTH-1 -: SIN_ADDR_BITS]), //top SIN_ADDR_BITS bits = address to read from
        .data(sine_out)
    );

    // waveform selector
    reg [DAC_WIDTH-1:0] wave_mux;
    always @(*) begin
        case (waveform_sel)
            2'b00: wave_mux = saw_out;
            2'b01: wave_mux = square_out;
            2'b10: wave_mux = tri_out;
            2'b11: wave_mux = sine_out;
            default: wave_mux = 0;
        endcase
    end

    assign audio_out = wave_mux;


    // i2s_tx i2s_out (
    // .mclk(clk_12mhz288),
    // .reset(reset),
    // .left_sample(audio_out),   // 12-bit sample from waveform selector
    // .right_sample(audio_out),  // mono -> both channels
    // .lrck(D_A_LRCK),
    // .sclk(D_A_SCLK),
    // .sdin(D_A_SDIN)
// );

// MCLK = clk_12mhz288 -> connect to D/A_MCLK (Pmod pin 1)

endmodule
