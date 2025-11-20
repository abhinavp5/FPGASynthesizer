// Input:  note[6:0] (0–127 MIDI note number)
// Output: freq[31:0] (integer frequency in Hz)

module midi_freq_rom (
    input i_Clk,
    input  wire [6:0] note,
    output reg  [23:0] phase_inc
);

    // Constants for phase increment calculation
    localparam integer ACC_WIDTH = 24;
    localparam integer SAMPLE_RATE = 25_000_000;  // 25 MHz / 512

    always @(posedge i_Clk) begin
        case (note)
            7'd0:   phase_inc <= (64'd8 * (2**ACC_WIDTH)) / SAMPLE_RATE;      // C(-1)
            7'd1:   phase_inc <= (64'd9 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd2:   phase_inc <= (64'd9 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd3:   phase_inc <= (64'd10 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd4:   phase_inc <= (64'd11 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd5:   phase_inc <= (64'd12 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd6:   phase_inc <= (64'd13 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd7:   phase_inc <= (64'd14 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd8:   phase_inc <= (64'd15 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd9:   phase_inc <= (64'd16 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd10:  phase_inc <= (64'd17 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd11:  phase_inc <= (64'd18 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd12:  phase_inc <= (64'd16 * (2**ACC_WIDTH)) / SAMPLE_RATE;     // C0
            7'd13:  phase_inc <= (64'd17 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd14:  phase_inc <= (64'd18 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd15:  phase_inc <= (64'd19 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd16:  phase_inc <= (64'd21 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd17:  phase_inc <= (64'd22 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd18:  phase_inc <= (64'd23 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd19:  phase_inc <= (64'd25 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd20:  phase_inc <= (64'd26 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd21:  phase_inc <= (64'd28 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd22:  phase_inc <= (64'd29 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd23:  phase_inc <= (64'd31 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd24:  phase_inc <= (64'd33 * (2**ACC_WIDTH)) / SAMPLE_RATE;     // C1
            7'd25:  phase_inc <= (64'd35 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd26:  phase_inc <= (64'd37 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd27:  phase_inc <= (64'd39 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd28:  phase_inc <= (64'd41 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd29:  phase_inc <= (64'd44 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd30:  phase_inc <= (64'd46 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd31:  phase_inc <= (64'd49 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd32:  phase_inc <= (64'd52 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd33:  phase_inc <= (64'd55 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd34:  phase_inc <= (64'd58 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd35:  phase_inc <= (64'd62 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd36:  phase_inc <= (64'd65 * (2**ACC_WIDTH)) / SAMPLE_RATE;     // C2
            7'd37:  phase_inc <= (64'd69 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd38:  phase_inc <= (64'd73 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd39:  phase_inc <= (64'd78 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd40:  phase_inc <= (64'd82 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd41:  phase_inc <= (64'd87 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd42:  phase_inc <= (64'd93 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd43:  phase_inc <= (64'd98 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd44:  phase_inc <= (64'd104 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd45:  phase_inc <= (64'd110 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd46:  phase_inc <= (64'd117 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd47:  phase_inc <= (64'd123 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd48:  phase_inc <= (64'd131 * (2**ACC_WIDTH)) / SAMPLE_RATE;    // C3
            7'd49:  phase_inc <= (64'd139 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd50:  phase_inc <= (64'd147 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd51:  phase_inc <= (64'd156 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd52:  phase_inc <= (64'd165 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd53:  phase_inc <= (64'd175 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd54:  phase_inc <= (64'd185 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd55:  phase_inc <= (64'd196 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd56:  phase_inc <= (64'd208 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd57:  phase_inc <= (64'd220 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd58:  phase_inc <= (64'd233 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd59:  phase_inc <= (64'd247 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd60:  phase_inc <= (64'd262 * (2**ACC_WIDTH)) / SAMPLE_RATE;    // C4 (middle C)
            7'd61:  phase_inc <= (64'd277 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd62:  phase_inc <= (64'd294 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd63:  phase_inc <= (64'd311 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd64:  phase_inc <= (64'd330 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd65:  phase_inc <= (64'd349 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd66:  phase_inc <= (64'd370 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd67:  phase_inc <= (64'd392 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd68:  phase_inc <= (64'd415 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd69:  phase_inc <= (64'd440 * (2**ACC_WIDTH)) / SAMPLE_RATE;    // A4
            7'd70:  phase_inc <= (64'd466 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd71:  phase_inc <= (64'd494 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd72:  phase_inc <= (64'd523 * (2**ACC_WIDTH)) / SAMPLE_RATE;    // C5
            7'd73:  phase_inc <= (64'd554 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd74:  phase_inc <= (64'd587 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd75:  phase_inc <= (64'd622 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd76:  phase_inc <= (64'd659 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd77:  phase_inc <= (64'd698 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd78:  phase_inc <= (64'd740 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd79:  phase_inc <= (64'd784 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd80:  phase_inc <= (64'd831 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd81:  phase_inc <= (64'd880 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd82:  phase_inc <= (64'd932 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd83:  phase_inc <= (64'd988 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd84:  phase_inc <= (64'd1047 * (2**ACC_WIDTH)) / SAMPLE_RATE;   // C6
            7'd85:  phase_inc <= (64'd1109 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd86:  phase_inc <= (64'd1175 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd87:  phase_inc <= (64'd1245 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd88:  phase_inc <= (64'd1319 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd89:  phase_inc <= (64'd1397 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd90:  phase_inc <= (64'd1480 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd91:  phase_inc <= (64'd1568 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd92:  phase_inc <= (64'd1661 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd93:  phase_inc <= (64'd1760 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd94:  phase_inc <= (64'd1865 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd95:  phase_inc <= (64'd1976 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd96:  phase_inc <= (64'd2093 * (2**ACC_WIDTH)) / SAMPLE_RATE;   // C7
            7'd97:  phase_inc <= (64'd2217 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd98:  phase_inc <= (64'd2349 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd99:  phase_inc <= (64'd2489 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd100: phase_inc <= (64'd2637 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd101: phase_inc <= (64'd2794 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd102: phase_inc <= (64'd2960 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd103: phase_inc <= (64'd3136 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd104: phase_inc <= (64'd3322 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd105: phase_inc <= (64'd3520 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd106: phase_inc <= (64'd3729 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd107: phase_inc <= (64'd3951 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd108: phase_inc <= (64'd4186 * (2**ACC_WIDTH)) / SAMPLE_RATE;   // C8
            7'd109: phase_inc <= (64'd4435 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd110: phase_inc <= (64'd4699 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd111: phase_inc <= (64'd4978 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd112: phase_inc <= (64'd5274 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd113: phase_inc <= (64'd5588 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd114: phase_inc <= (64'd5920 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd115: phase_inc <= (64'd6272 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd116: phase_inc <= (64'd6645 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd117: phase_inc <= (64'd7040 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd118: phase_inc <= (64'd7459 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd119: phase_inc <= (64'd7902 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            7'd120: phase_inc <= (64'd8372 * (2**ACC_WIDTH)) / SAMPLE_RATE;    // C9
            7'd121: phase_inc <= (64'd8870 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd122: phase_inc <= (64'd9397 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd123: phase_inc <= (64'd9956 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd124: phase_inc <= (64'd10548 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd125: phase_inc <= (64'd11175 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd126: phase_inc <= (64'd11840 * (2**ACC_WIDTH)) / SAMPLE_RATE;
            7'd127: phase_inc <= (64'd12544 * (2**ACC_WIDTH)) / SAMPLE_RATE;

            default: phase_inc <= 0;
        endcase
    end

endmodule
