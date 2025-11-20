module i2s_audio_test_top (
    input wire i_Clk,           // 25 MHz clock input
    input wire i_Reset,         // Reset button
    output wire o_MCLK,         
    output wire o_SCLK,         
    output wire o_LRCLK,        
    output wire o_SDIN          
);

    // Parameters
    parameter ACC_WIDTH = 24;   
    parameter SYSTEM_CLOCK_HZ = 25_000_000;
    
    // Phase accumulator
    reg [ACC_WIDTH-1:0] phase_acc;
    
    // 440Hz Increment for 25MHz Clock
    // localparam [ACC_WIDTH-1:0] PHASE_INC = 24'd294258;
    // Force 64-bit precision (64'd440) to prevent overflow
    localparam [ACC_WIDTH-1:0] PHASE_INC = (64'd440 * (2**ACC_WIDTH)) / SYSTEM_CLOCK_HZ;

    // Phase accumulator logic
    always @(posedge i_Clk) begin

        if (i_Reset) begin 
            phase_acc <= 0;
        end else begin
            phase_acc <= phase_acc + PHASE_INC;
        end
    end
    
    // --- SAWTOOTH GENERATOR (No ROM) ---
    // We take the top 16 bits of the counter. 
    // This creates a ramp wave (Sawtooth).
    wire [15:0] audio_data;
    assign audio_data = phase_acc[ACC_WIDTH-1 : ACC_WIDTH-16];
    
    // I2S transmitter
    I2S #(
        .DIVISOR(512),              // FIXED: 512 (Sample Rate ~48.8kHz)
        .NUM_OF_AMPLITUDE_BITS(16) 
    ) i2s_transmitter (
        .i_Clk(i_Clk),
        .i_RX_Serial_Left(audio_data),   
        .i_RX_Serial_Right(audio_data),  
        .o_MCLK(o_MCLK),
        .o_LRCLK(o_LRCLK),
        .o_SCLK(o_SCLK),
        .o_SDIN(o_SDIN)
    );

endmodule
