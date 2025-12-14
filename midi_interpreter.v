//MIDI Parser + Note Allocation and Management (NAM)

module midi_interpreter (
    input wire clk,
    input wire rx_dv,
    input wire rst,
    input wire [7:0] rx_byte,

    //duplicate outputs 4 times for 4 voices
    output wire [6:0] note_to_voice_0,
    output wire [6:0] note_to_voice_1,
    output wire [6:0] note_to_voice_2,
    output wire [6:0] note_to_voice_3,

    output wire [23:0] phase_inc_0,
    output wire [23:0] phase_inc_1,
    output wire [23:0] phase_inc_2,
    output wire [23:0] phase_inc_3,

    output wire is_active_0,
    output wire is_active_1,
    output wire is_active_2,
    output wire is_active_3
);

    //MIDI message parser. this is an FSM that reads incoming MIDI data and figures out whether it's a note on or off message
    reg [1:0] state = 0;
    reg [7:0] status_byte;
    reg [7:0] data_note;
    reg [7:0] data_vel;

    //pulses when a full 3-byte msg is parsed and we can now process another
    reg msg_ready = 0; 

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            status_byte <= 0;
            data_note <= 0;
            data_vel <= 0;
            msg_ready <= 0;
        end else begin
            msg_ready <= 0;
            if (rx_dv) begin
                case (state)
                    0: begin
                        //status byte (0x80 for off, 0x90 for on)
                        if (rx_byte >= 8'h80) begin
                            status_byte <= rx_byte;
                            state <= 1;
                        end
                    end
                    1: begin
                        //first data byte — NOTE number (0–127)
                        if (rx_byte < 8'h80) begin
                            data_note <= rx_byte;
                            state <= 2;
                        end
                    end
                    2: begin
                        //second data byte — velocity (no implementation to handle this (yet?) )
                        if (rx_byte < 8'h80) begin
                            data_vel <= rx_byte;
                            //once we've processed velocity, the full message is ready!
                            msg_ready <= 1;
                        end
                        //always return to status byte after full message processed
                        state <= 0;
                    end
                endcase
            end
        end
    end

    localparam NUM_VOICES = 4;
    //tracks the MIDI note number held by each voice slot.
    reg [6:0] active_notes [NUM_VOICES-1:0]; 
    reg [23:0] phase_incs [NUM_VOICES-1:0];
    reg [3:0] voice_active;

    //in out note on logic, if all voices are busy, we steal from this index and update it by incrementing
    reg [1:0] next_voice_idx = 2'd0;
    
    //registers to hold the fully parsed MIDI command for one clock cycle
    reg msg_valid = 0; //(indicates that note and status are ready)
    reg msg_valid_final = 0; //pitch is ready 2 cycles after msg_ready because we need to look up pitch
    reg [7:0] status_reg = 0;
    reg [6:0] processed_note = 7'd0;
    reg [7:0] velocity_reg = 0;
    
    //phase increment ROM lookup (reads status_reg to know when to look up)
    wire [23:0] note_on_inc;
    midi_freq_rom freq_rom_inst (
        .i_Clk(clk),
        .note(processed_note),
        .phase_inc(note_on_inc)
    );
    
    //VOICE ALLOCATION AND LOOKUP LOGIC
    
    //check if we found an already active note
    wire found_note;
    assign found_note = (active_notes[0] == processed_note) |
                        (active_notes[1] == processed_note) |
                        (active_notes[2] == processed_note) |
                        (active_notes[3] == processed_note);

    //    //find the first free voice index via combinational logic
    wire [3:0] free_mask = ~voice_active; 
    wire free_voice_found = |free_mask;
    wire [1:0] free_voice_idx_comb;
    assign free_voice_idx_comb = 
        free_mask[0] ? 2'd0 :
        free_mask[1] ? 2'd1 :
        free_mask[2] ? 2'd2 :
        2'd3; 
    wire [1:0] allocation_idx;
    //if free voice found, use that index, else use next_voice_idx
    assign allocation_idx = free_voice_found ? free_voice_idx_comb : next_voice_idx;

    // --- MAIN VOICE MANAGEMENT LOGIC (Sequential) ---
    always @(posedge clk) begin
        if (rst) begin
            voice_active <= 4'b0;
            next_voice_idx <= 2'd0;
            active_notes[0] <= 7'd0;
            active_notes[1] <= 7'd0;
            active_notes[2] <= 7'd0;
            active_notes[3] <= 7'd0;
            phase_incs[0] <= 24'd0;
            phase_incs[1] <= 24'd0;
            phase_incs[2] <= 24'd0;
            phase_incs[3] <= 24'd0;
            msg_valid <= 1'b0;
            msg_valid_final <= 1'b0;
            status_reg <= 8'd0;
            processed_note <= 7'd0;
            velocity_reg <= 8'd0;
        end else begin
            msg_valid <= msg_ready;
            //ended up not needing to wait an extra cycle, this works fine
            msg_valid_final <= msg_valid;
            
            //this is redundant but would be useful if time waiting for rom lookup caused problems
            if (msg_ready) begin
                status_reg <= status_byte;
                processed_note <= data_note[6:0];
                velocity_reg <= data_vel;
            end
            
            //process message
            if (msg_valid_final) begin
                //NOTE ON (Status 0x90, Velocity > 0)
                if ((status_reg & 8'hF0) == 8'h90 && velocity_reg != 0) begin
                    
                    //if note is found, update its pitch
                    if (found_note) begin
                        if (active_notes[0] == processed_note) phase_incs[0] <= note_on_inc;
                        if (active_notes[1] == processed_note) phase_incs[1] <= note_on_inc;
                        if (active_notes[2] == processed_note) phase_incs[2] <= note_on_inc;
                        if (active_notes[3] == processed_note) phase_incs[3] <= note_on_inc;
                    end 
                    
                    //if note is new (not found), allocate a voice
                    else begin
                        //allocation_idx is already calculated with combinational logic
                        active_notes[allocation_idx] <= processed_note;
                        phase_incs[allocation_idx] <= note_on_inc;
                        voice_active[allocation_idx] <= 1'b1;
                        
                        //update index ONLY if all were voices were busy and we 'stole' one
                        if (!free_voice_found) begin
                           next_voice_idx <= next_voice_idx + 2'd1;
                        end
                    end
                end
                
                //NOTE OFF (Status 0x80 OR Status 0x90, Velocity == 0)
                else if ((status_reg & 8'hF0) == 8'h80 || ((status_reg & 8'hF0) == 8'h90 && velocity_reg == 0)) begin
                    
                    //release the voice slot(s) holding this note (repeat 4 times)
                    if (active_notes[0] == processed_note) begin
                        active_notes[0] <= 7'd0;
                        phase_incs[0] <= 24'd0; 
                        voice_active[0] <= 1'b0;
                    end
                    
                    if (active_notes[1] == processed_note) begin
                        active_notes[1] <= 7'd0;
                        phase_incs[1] <= 24'd0; 
                        voice_active[1] <= 1'b0;
                    end
                    
                    if (active_notes[2] == processed_note) begin
                        active_notes[2] <= 7'd0;
                        phase_incs[2] <= 24'd0; 
                        voice_active[2] <= 1'b0;
                    end
                    
                    if (active_notes[3] == processed_note) begin
                        active_notes[3] <= 7'd0;
                        phase_incs[3] <= 24'd0; 
                        voice_active[3] <= 1'b0;
                    end
                end
            end
        end
    end
    
    assign note_to_voice_0 = active_notes[0];
    assign note_to_voice_1 = active_notes[1];
    assign note_to_voice_2 = active_notes[2];
    assign note_to_voice_3 = active_notes[3];
    
    assign phase_inc_0 = phase_incs[0];
    assign phase_inc_1 = phase_incs[1];
    assign phase_inc_2 = phase_incs[2];
    assign phase_inc_3 = phase_incs[3];
    
    assign is_active_0 = voice_active[0];
    assign is_active_1 = voice_active[1];
    assign is_active_2 = voice_active[2];
    assign is_active_3 = voice_active[3];
    
endmodule