module uut#(
    parameter integer ACC_WIDTH = 24,
    parameter integer SYSTEM_CLOCK_HZ = 25_000_000
) (
    input wire i_Clk,           
    input wire i_Reset,         
    input wire i_RX_Serial,
    output wire o_MCLK,         
    output wire o_SCLK,         
    output wire o_LRCLK,        
    output wire o_SDIN          
);
    //internal signals
    wire rx_dv;
    wire [7:0] rx_byte;
    wire [ACC_WIDTH-1:0] phase_inc_rom;
    wire note_on, note_off, note_valid;
    wire [6:0] current_note;
    
    // UART Receiver for MIDI
    UART_RX uart_reader (
        .i_Clk(i_Clk),
        .i_RX_Serial(i_RX_Serial),
        .o_RX_DV(rx_dv),
        .o_RX_Byte(rx_byte)
    );
    
    // MIDI interpreter
    midi_interpreter midi_inst (
        .clk(i_Clk),
        .rst(i_Reset),
        .rx_dv(rx_dv),
        .rx_byte(rx_byte),
        .note_on(note_on),
        .note_off(note_off),
        .current_note(current_note),
        .phase_inc_out(phase_inc_rom),
        .note_valid(note_valid)
    );
    
    // Phase accumulator
    wire [ACC_WIDTH-1:0] phase_acc;
    phase_accumulator #(
        .ACC_WIDTH(ACC_WIDTH)
    ) phase_acc_inst (
        .clk(i_Clk),
        .reset(i_Reset),
        .phase_inc_in(phase_inc_rom),
        .phase(phase_acc)
    );
    
    // Sawtooth Generator 
    // We take the top 16 bits of the counter. 
    // This creates a ramp wave (Sawtooth).
    wire [15:0] audio_data;
    assign audio_data = {~phase_acc[ACC_WIDTH-1], phase_acc[ACC_WIDTH-2 : ACC_WIDTH-16]};
    
    // TODO: Add waveform selector and add the other wave forms
    // TODO: Add multi note functionality/Chord Generator
    // TODO: Add button functionality to select between waveforms

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
