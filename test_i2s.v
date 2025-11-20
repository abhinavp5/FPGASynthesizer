// endmodule
module i2s_audio_test_top (
    input wire i_Clk,           // 25 MHz clock input
    input wire i_Reset,         // Reset button (active high)
    output wire o_MCLK,         // I2S Master Clock
    output wire o_SCLK,         // I2S Serial Clock
    output wire o_LRCLK,        // I2S Left/Right Clock
    output wire o_SDIN          // I2S Serial Data
);

    // Parameters
    parameter ACC_WIDTH = 24;   // Phase accumulator width
    parameter DAC_WIDTH = 24;   // Sine ROM output width
    
    // Phase accumulator for 440 Hz tone
    reg [ACC_WIDTH-1:0] phase_acc;
    
    // Calculate phase increment for 440 Hz
    // phase_inc = (freq * 2^ACC_WIDTH) / clk_freq
    // = (440 * 2^32) / 25_000_000 ≈ 294_258
    localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ = 24'd294258;
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ = 32'd38654705;
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ   = 32'd450346149;  // MIDI 60, 261.63 Hz (Middle C)
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ   = 32'd505324586;  // MIDI 62, 293.66 Hz
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ  = 32'd567070004;  // MIDI 64, 329.63 Hz
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ   = 32'd600717926;  // MIDI 65, 349.23 Hz
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ   = 32'd674101215;  // MIDI 67, 392.00 Hz
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ   = 32'd754974720;  // MIDI 69, 440.00 Hz
    // localparam [ACC_WIDTH-1:0] PHASE_INC_440HZ   = 32'd847187114;  // MIDI 71, 493.88 Hz

    // // Octave below (3rd octave)
    // localparam [ACC_WIDTH-1:0] PHASE_INC_C3   = 32'd225173074;  // MIDI 48, 130.81 Hz
    // localparam [ACC_WIDTH-1:0] PHASE_INC_A3   = 32'd377487360;  // MIDI 57, 220.00 Hz

        
    // Sine wave output from ROM
    wire [DAC_WIDTH-1:0] sine_out;
    
    // Phase accumulator - generates continuously incrementing phase
    always @(posedge i_Clk) begin
        if (i_Reset) begin
            phase_acc <= 0;
        end else begin
            phase_acc <= phase_acc + PHASE_INC_440HZ;
        end
    end
    
    // Sine ROM lookup table
    sine_rom #(
        .ADDR_BITS(8),
        .DATA_BITS(DAC_WIDTH), 
        .FILE("sine_rom.hex")
    ) sine_rom_inst (
        .clk(i_Clk),
        .addr(phase_acc[ACC_WIDTH-1:ACC_WIDTH-8]),  // Use top 8 bits as address
        .data(sine_out)
    );
    
    
    // Extend 12-bit sine to 16-bit (left-aligned for better amplitude)
    wire [15:0] audio_data;
    // assign audio_data = {sine_out, 4'b0000};
    assign audio_data = sine_out;
    
    // I2S transmitter
    I2S #(
        .DIVISOR(520),              // Not used in your current implementation
        .NUM_OF_AMPLITUDE_BITS(16), 
        .M(256)                     // Not used in your current implementation
    ) i2s_transmitter (
        .i_Clk(i_Clk),
        .i_RX_Serial_Left(audio_data),   // Send same tone to left
        .i_RX_serial_Right(audio_data),  // Send same tone to right
        .o_MCLK(o_MCLK),
        .o_LRCLK(o_LRCLK),
        .o_SCLK(o_SCLK),
        .o_SDIN(o_SDIN)
    );

endmodule
