//MIDI Parser + Note On/Off Detector + Phase Increment Lookup

module midi_interpreter (
    input wire clk,
    input wire rx_dv, //From UART_RX
    input wire rst, //Reset signal
    input wire [7:0] rx_byte, //From UART_RX

    output reg note_on, //Pulses for Note On
    output reg note_off, //Pulses for Note Off
    output reg  [6:0]  current_note, //The active MIDI note number
    output wire [23:0] phase_inc_out, //Output phase increment (24-bit)
    output reg note_valid //Pulses when new note frequency is ready
);

    //MIDI message parser (3-byte: status, note, velocity)
    reg [1:0] state = 0;
    reg [7:0] status_byte;
    reg [7:0] data_note;
    reg [7:0] data_vel;

    reg msg_ready = 0; //Pulses when a full 3-byte msg is parsed

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            status_byte <= 0;
            data_note <= 0;
            data_vel <= 0;
            msg_ready <= 0;
        end else begin
            msg_ready <= 0; //default
            if (rx_dv) begin
                case (state)
                    0: begin
                        //STATUS byte (0x80 for off, 0x90 for on)
                        if (rx_byte >= 8'h80) begin
                            status_byte <= rx_byte;
                            state <= 1;
                        end
                    end

                    1: begin
                        //First DATA byte — NOTE number (0–127)
                        if (rx_byte < 8'h80) begin
                            data_note <= rx_byte;
                            state <= 2;
                        end
                    end

                    2: begin
                        //Second DATA byte — VELOCITY
                        if (rx_byte < 8'h80) begin
                            data_vel <= rx_byte;
                            msg_ready <= 1; //full message ready!!!!
                        end
                        state <= 0; //always return to status after full message processed
                    end
                endcase
            end
        end
    end

    //Interpret whether the note is on or off
    //Note On: status 0x90 && velocity > 0
    //Note Off: status 0x80 OR velocity == 0

    always @(posedge clk) begin
        if (rst) begin
            note_on <= 0;
            note_off <= 0;
            note_valid <= 0;
            current_note <= 0;
        end else begin
            note_on <= 0;
            note_off <= 0;
            note_valid <= 0;
            if (msg_ready) begin
                //NOTE ON
                if ((status_byte & 8'hF0) == 8'h90 && data_vel != 0) begin
                    current_note <= data_note[6:0];
                    note_on <= 1;
                    note_valid <= 1;
                end

                //NOTE OFF
                else if ((status_byte & 8'hF0) == 8'h80 || ((status_byte & 8'hF0) == 8'h90 && data_vel == 0)) begin
                    current_note <= data_note[6:0];
                    note_off <= 1;
                    note_valid <= 1;
                end
            end
        end
    end
    //Phase increment ROM lookup
    midi_freq_rom freq_rom_inst (
        .i_Clk(clk),
        .note(current_note),
        .phase_inc(phase_inc_out)
    );

endmodule
