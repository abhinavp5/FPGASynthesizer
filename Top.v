module uut#(
    parameter integer ACC_WIDTH = 24,
    parameter integer SYSTEM_CLOCK_HZ = 25_000_000,
    parameter integer NUM_VOICES = 4
) (
    input wire i_Clk, //i_Clk -- PIN 15        
    input wire i_Switch_1, //i_Reset -- PIN 56 
    input wire i_Switch_2,
    input wire i_UART_RX, //i_RX_Serial -- PIN 73
    output wire io_PMOD_1, //o_MCLK -- PIN 65   
    output wire io_PMOD_3, //o_SCLK -- PIN 63 
    output wire io_PMOD_2, //o_LRCLK -- PIN 64
    output wire io_PMOD_4, //o_SDIN -- PIN 62
    output wire o_LED_2, //LED2 -- PIN 57
    output wire o_LED_3  //LED3 -- PIN 59
);

    wire rst;
    assign rst = i_Switch_1; 

    // --- Polyphonic Voice Wires (4 Voices) ---
    //wire arrays allow for easier access later (duplicating logic for 4 voices)
    wire [23:0] phase_inc_in_0, phase_inc_in_1, phase_inc_in_2, phase_inc_in_3;
    wire [ACC_WIDTH-1:0] phase_acc_0, phase_acc_1, phase_acc_2, phase_acc_3; 
    wire is_active_0, is_active_1, is_active_2, is_active_3;
    wire [23:0] phase_inc_in [3:0];
    assign phase_inc_in[0] = phase_inc_in_0;
    assign phase_inc_in[1] = phase_inc_in_1;
    assign phase_inc_in[2] = phase_inc_in_2;
    assign phase_inc_in[3] = phase_inc_in_3;
    wire [ACC_WIDTH-1:0] phase_acc [3:0];
    assign phase_acc[0] = phase_acc_0;
    assign phase_acc[1] = phase_acc_1;
    assign phase_acc[2] = phase_acc_2;
    assign phase_acc[3] = phase_acc_3;
    wire is_active [3:0];
    assign is_active[0] = is_active_0;
    assign is_active[1] = is_active_1;
    assign is_active[2] = is_active_2;
    assign is_active[3] = is_active_3;
    
    wire i_Toggle_Switch; //debounced signal from the pushbutton
    reg [1:0] r_Waveform_Select = 2'b00; //00 - Sawtooth, 01 - Square, 10 - Triangle
    reg [15:0] audio_data; //final mixed output (16-bit)
    
    //UART signals
    wire rx_dv;
    wire [7:0] rx_byte;

    //LED2: lights up when at least one note is active
    assign o_LED_2 = is_active_0 | is_active_1 | is_active_2 | is_active_3; 
    
    //LED3: blinks when a MIDI instruction is received
    reg [23:0] led_timer;
    reg led_state;
    
    always @(posedge i_Clk) begin
        if (rx_dv) begin
            led_timer <= 2500000; // Light up for ~0.1 seconds (25MHz clock)
            led_state <= 1;
        end else if (led_timer > 0) begin
            led_timer <= led_timer - 1;
            led_state <= 1;
        end else begin
            led_state <= 0;
        end
    end
    assign o_LED_3 = led_state;
    
    UART_RX uart_reader (
        .i_Clk(i_Clk),
        .i_RX_Serial(i_UART_RX),
        .o_RX_DV(rx_dv),
        .o_RX_Byte(rx_byte)
    );

    midi_interpreter midi_inst (
        .clk(i_Clk),
        .rst(rst),
        .rx_dv(rx_dv),
        .rx_byte(rx_byte),
        .note_to_voice_0(),
        .note_to_voice_1(), 
        .note_to_voice_2(), 
        .note_to_voice_3(),
        .phase_inc_0(phase_inc_in_0),
        .phase_inc_1(phase_inc_in_1),
        .phase_inc_2(phase_inc_in_2),
        .phase_inc_3(phase_inc_in_3),
        .is_active_0(is_active_0),
        .is_active_1(is_active_1),
        .is_active_2(is_active_2),
        .is_active_3(is_active_3)
    );

    //=========================================================
     // Debounce filter for waveform select button
    Debounce_Filter #(
        .DEBOUNCE_LIMIT(20) 
    ) debounce_inst (
        .i_Clk(i_Clk),
        .reset(i_Switch_1),
        .i_Bouncy(i_Switch_2),
        .o_Debounced(i_Toggle_Switch)
    );

    // waveform selection FSM 
    localparam TOGGLE_IDLE = 1'b0; 
    localparam TOGGLE_PRESSED = 1'b1; 
    reg r_Toggle_SM = TOGGLE_IDLE; 

    always @(posedge i_Clk) begin
        if (i_Switch_1) begin 
            r_Waveform_Select <= 2'b00; 
            r_Toggle_SM <= TOGGLE_IDLE;
        end else begin
            case (r_Toggle_SM)
                TOGGLE_IDLE: begin
                    if (i_Toggle_Switch) r_Toggle_SM <= TOGGLE_PRESSED;
                end
                
                TOGGLE_PRESSED: begin
                    if (~i_Toggle_Switch) begin
                        case (r_Waveform_Select)
                            2'b00: r_Waveform_Select <= 2'b01; 
                            2'b01: r_Waveform_Select <= 2'b10; 
                            2'b10: r_Waveform_Select <= 2'b00; 
                            default: r_Waveform_Select <= 2'b00;
                        endcase
                        r_Toggle_SM <= TOGGLE_IDLE;
                    end
                end
                default: r_Toggle_SM <= TOGGLE_IDLE;
            endcase
        end
    end
    //=========================================================
    
    //Phase Accumulators and Waveform Generators
    // ACC_WIDTH=24. Audio Output is 16 bits. Sign bit is [23]. Magnitude slice is 15 bits [22:8].
    localparam integer MAG_WIDTH = 15; 
    localparam [15:0] MAX_POS_SQUARE = 16'h7FFF; 
    localparam [15:0] MAX_NEG_SQUARE = 16'h8000; 

    // ----------------------------------------------------
    // VOICE 0
    // ----------------------------------------------------
    wire reset_0 = rst | ~is_active[0]; 
    phase_accumulator #(
        .ACC_WIDTH(ACC_WIDTH)
    ) phase_acc_inst_0 (
        .clk(i_Clk), .reset(reset_0), .phase_inc_in(phase_inc_in[0]), .phase(phase_acc_0)
    );
    
    wire [15:0] sawtooth_wave_0;
    wire [15:0] square_wave_0;
    wire [15:0] triangle_wave_0;
    
    //magnitude slice for all three waves
    wire [MAG_WIDTH-1:0] mag_slice_0 = phase_acc[0][ACC_WIDTH-2 : ACC_WIDTH-16];

    //sawtooth wave
    //the inverse MSB is the sign, followed by the magnitude slice.
    assign sawtooth_wave_0 = {~phase_acc[0][ACC_WIDTH-1], mag_slice_0};
    
    //square wave
    assign square_wave_0 = phase_acc[0][ACC_WIDTH-1] ? MAX_NEG_SQUARE : MAX_POS_SQUARE;
    
    //triangle wave
    wire [MAG_WIDTH-1:0] tri_magnitude_0;
    assign tri_magnitude_0 = phase_acc[0][ACC_WIDTH-1] ? 
                             ~mag_slice_0 : //invert magnitude in second half (0x8000 to 0xFFFF)
                             mag_slice_0;  //use magnitude as is in first half (0x0000 to 0x7FFF)
                             
    assign triangle_wave_0 = {phase_acc[0][ACC_WIDTH-1], tri_magnitude_0}; 

    reg [15:0] voice_output_0;
    always @(*) begin
        if (is_active[0]) begin
            case (r_Waveform_Select)
                2'b00: voice_output_0 = sawtooth_wave_0;
                2'b01: voice_output_0 = square_wave_0;
                2'b10: voice_output_0 = triangle_wave_0;
                default: voice_output_0 = 16'h0000;
            endcase
        end else voice_output_0 = 16'h0000; 
    end


    // ----------------------------------------------------
    // VOICE 1
    // ----------------------------------------------------
    wire reset_1 = rst | ~is_active[1];
    phase_accumulator #(
        .ACC_WIDTH(ACC_WIDTH)
    ) phase_acc_inst_1 (
        .clk(i_Clk), .reset(reset_1), .phase_inc_in(phase_inc_in[1]), .phase(phase_acc_1)
    );
    
    wire [15:0] sawtooth_wave_1;
    wire [15:0] square_wave_1;
    wire [15:0] triangle_wave_1;
    
    wire [MAG_WIDTH-1:0] mag_slice_1 = phase_acc[1][ACC_WIDTH-2 : ACC_WIDTH-16];

    assign sawtooth_wave_1 = {~phase_acc[1][ACC_WIDTH-1], mag_slice_1};
    assign square_wave_1 = phase_acc[1][ACC_WIDTH-1] ? MAX_NEG_SQUARE : MAX_POS_SQUARE;
    
    wire [MAG_WIDTH-1:0] tri_magnitude_1;
    assign tri_magnitude_1 = phase_acc[1][ACC_WIDTH-1] ? 
                             ~mag_slice_1 : 
                             mag_slice_1;
    assign triangle_wave_1 = {phase_acc[1][ACC_WIDTH-1], tri_magnitude_1};

    reg [15:0] voice_output_1;
    always @(*) begin
        if (is_active[1]) begin
            case (r_Waveform_Select)
                2'b00: voice_output_1 = sawtooth_wave_1;
                2'b01: voice_output_1 = square_wave_1;
                2'b10: voice_output_1 = triangle_wave_1;
                default: voice_output_1 = 16'h0000;
            endcase
        end else voice_output_1 = 16'h0000; 
    end
    

    // ----------------------------------------------------
    // VOICE 2
    // ----------------------------------------------------
    wire reset_2 = rst | ~is_active[2];
    phase_accumulator #(
        .ACC_WIDTH(ACC_WIDTH)
    ) phase_acc_inst_2 (
        .clk(i_Clk), .reset(reset_2), .phase_inc_in(phase_inc_in[2]), .phase(phase_acc_2)
    );
    
    wire [15:0] sawtooth_wave_2;
    wire [15:0] square_wave_2;
    wire [15:0] triangle_wave_2;

    wire [MAG_WIDTH-1:0] mag_slice_2 = phase_acc[2][ACC_WIDTH-2 : ACC_WIDTH-16];
    
    assign sawtooth_wave_2 = {~phase_acc[2][ACC_WIDTH-1], mag_slice_2};
    assign square_wave_2 = phase_acc[2][ACC_WIDTH-1] ? MAX_NEG_SQUARE : MAX_POS_SQUARE;
    
    wire [MAG_WIDTH-1:0] tri_magnitude_2;
    assign tri_magnitude_2 = phase_acc[2][ACC_WIDTH-1] ? 
                             ~mag_slice_2 : 
                             mag_slice_2;
    assign triangle_wave_2 = {phase_acc[2][ACC_WIDTH-1], tri_magnitude_2};

    reg [15:0] voice_output_2;
    always @(*) begin
        if (is_active[2]) begin
            case (r_Waveform_Select)
                2'b00: voice_output_2 = sawtooth_wave_2;
                2'b01: voice_output_2 = square_wave_2;
                2'b10: voice_output_2 = triangle_wave_2;
                default: voice_output_2 = 16'h0000;
            endcase
        end else voice_output_2 = 16'h0000; 
    end


    // ----------------------------------------------------
    // VOICE 3
    // ----------------------------------------------------
    wire reset_3 = rst | ~is_active[3];
    phase_accumulator #(
        .ACC_WIDTH(ACC_WIDTH)
    ) phase_acc_inst_3 (
        .clk(i_Clk), .reset(reset_3), .phase_inc_in(phase_inc_in[3]), .phase(phase_acc_3)
    );
    
    wire [15:0] sawtooth_wave_3;
    wire [15:0] square_wave_3;
    wire [15:0] triangle_wave_3;

    wire [MAG_WIDTH-1:0] mag_slice_3 = phase_acc[3][ACC_WIDTH-2 : ACC_WIDTH-16];
    
    assign sawtooth_wave_3 = {~phase_acc[3][ACC_WIDTH-1], mag_slice_3};
    assign square_wave_3 = phase_acc[3][ACC_WIDTH-1] ? MAX_NEG_SQUARE : MAX_POS_SQUARE;
    
    wire [MAG_WIDTH-1:0] tri_magnitude_3;
    assign tri_magnitude_3 = phase_acc[3][ACC_WIDTH-1] ? 
                             ~mag_slice_3 : 
                             mag_slice_3;
    assign triangle_wave_3 = {phase_acc[3][ACC_WIDTH-1], tri_magnitude_3};

    reg [15:0] voice_output_3;
    always @(*) begin
        if (is_active[3]) begin
            case (r_Waveform_Select)
                2'b00: voice_output_3 = sawtooth_wave_3;
                2'b01: voice_output_3 = square_wave_3;
                2'b10: voice_output_3 = triangle_wave_3;
                default: voice_output_3 = 16'h0000;
            endcase
        end else voice_output_3 = 16'h0000; 
    end

    
    // --- Audio Mixer ---
    //FIXED: Explicitly cast inputs to signed 18-bit before summing 
    wire signed [17:0] mixed_audio_18bit;
    reg signed [15:0] final_audio_out;
    
    assign mixed_audio_18bit = $signed({{2{voice_output_0[15]}}, voice_output_0}) + 
                               $signed({{2{voice_output_1[15]}}, voice_output_1}) + 
                               $signed({{2{voice_output_2[15]}}, voice_output_2}) + 
                               $signed({{2{voice_output_3[15]}}, voice_output_3});
                               
    // Division by 4 (Attenuation): Shift right by 2 bits. 
    //assign final_audio_out = mixed_audio_18bit[16:1]; 


    // //========================================================= 
    // // -------------------------------------------------------------------------
    // // DYNAMIC ATTENUATION LOGIC
    // // -------------------------------------------------------------------------
    // // Count how many voices are currently active
    // wire [2:0] active_voice_count;
    // assign active_voice_count = is_active[0] + is_active[1] + is_active[2] + is_active[3];

    // // Select Attenuation based on count:
    // assign final_audio_out = (active_voice_count >= 3) ? mixed_audio_18bit[17:2] :
    //                          (active_voice_count == 2) ? mixed_audio_18bit[16:1] :
    //                                                      mixed_audio_18bit[15:0];
    // //==========================================================

    // // Final output assignment to the I2S transmitter
    always @(*) begin
        audio_data = final_audio_out;
    end
    
    // //=========================================================

    always @(*) begin
        //if 18 bit signal has pos overflow, cut off to max
        if (mixed_audio_18bit > 18'sd32768) begin
            final_audio_out = 16'sd32768;
        end
        //if 18 bit signal has neg overflow, cut off to min
        else if (mixed_audio_18bit < -18'sd32768) begin
            final_audio_out = -16'sd32768;
        end
        else begin
            final_audio_out = mixed_audio_18bit[15:0];
        end
    end

    // I2S transmitter
    I2S #(
        .DIVISOR(512),              // FIXED: 512 (Sample Rate ~48.8kHz)
        .NUM_OF_AMPLITUDE_BITS(16) 
    ) i2s_transmitter (
        .i_Clk(i_Clk),
        .i_RX_Serial_Left(audio_data),   
        .i_RX_Serial_Right(audio_data),  
        .o_MCLK(io_PMOD_1),
        .o_LRCLK(io_PMOD_2),
        .o_SCLK(io_PMOD_3),
        .o_SDIN(io_PMOD_4)
    );

endmodule