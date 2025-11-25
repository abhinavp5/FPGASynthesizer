module uut#(
    parameter integer ACC_WIDTH = 24,
    parameter integer SYSTEM_CLOCK_HZ = 25_000_000
) (
    input wire i_Clk,           
    input wire i_Reset,         
    input wire i_RX_Serial,
    input wire i_Switch_1,
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
    //waveform selection signals
    wire i_Toggle_Switch; //debounced signal from the pushbutton
    reg [1:0] r_Waveform_Select = 2'b00; //00 - Sawtooth, 01 - Square, 10 - Triangle
    
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

    //debounce filter for waveform select button
    Debounce_Filter #(
        .DEBOUNCE_LIMIT(20) 
    ) debounce_inst (
        .i_Clk(i_Clk),
        .reset(i_Reset),
        .i_Bouncy(i_Switch_1),
        .o_Debounced(i_Toggle_Switch)
    );

    //waveform selection logic
    reg [ACC_WIDTH-1:0] phase_acc; //needs to be declared here for the always block
    reg [15:0] audio_data; //needs to be declared here for the always block

    always @(posedge i_Clk) begin
        if (i_Reset) begin
            r_Waveform_Select <= 2'b00; //reset to sawtooth
        end else begin
            //cycle the waveform on a debounced rising edge
            if (i_Toggle_Switch) begin
                case (r_Waveform_Select)
                    2'b00: r_Waveform_Select <= 2'b01; //sawtooth -> square
                    2'b01: r_Waveform_Select <= 2'b10; //square -> triangle
                    2'b10: r_Waveform_Select <= 2'b00; //triangle -> sawtooth
                    default: r_Waveform_Select <= 2'b00;
                endcase
            end
        end
    end
    
    //phase accumulator
    //wire [ACC_WIDTH-1:0] phase_acc;
    phase_accumulator #(
        .ACC_WIDTH(ACC_WIDTH)
    ) phase_acc_inst (
        .clk(i_Clk),
        .reset(i_Reset),
        .phase_inc_in(phase_inc_rom),
        .phase(phase_acc)
    );
    
    //waveform generator (24-bit phase to 16-bit audio_data)
    wire [15:0] sawtooth_wave;
    wire [15:0] square_wave;
    wire [15:0] triangle_wave;

    //sawtooth wave
    //inverts MSB for two's complement-like output, then truncates to the top 16 bits
    assign sawtooth_wave = {~phase_acc[ACC_WIDTH-1], phase_acc[ACC_WIDTH-2 : ACC_WIDTH-16]}; 

    //square wave (MSB of phase accumulator) - scaled to full range (16-bit) 
    assign square_wave = {phase_acc[ACC_WIDTH-1], {15{phase_acc[ACC_WIDTH-1]}}};

    //triangle wave
    //if MSB is 1, invert the lower 15 bits, otherwise use the lower 15 bits.
    assign triangle_wave = phase_acc[ACC_WIDTH-1] ? 
                        {~phase_acc[ACC_WIDTH-2 : ACC_WIDTH-17], phase_acc[ACC_WIDTH-17]} : //invert when MSB is high
                        {phase_acc[ACC_WIDTH-2 : ACC_WIDTH-17], phase_acc[ACC_WIDTH-17]}; //keep as is when MSB is low

    //waveform selector
    always @(*) begin
        case (r_Waveform_Select)
            2'b00: audio_data = sawtooth_wave;
            2'b01: audio_data = square_wave;
            2'b10: audio_data = triangle_wave;
            default: audio_data = 16'h0000;
        endcase
    end
    
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
