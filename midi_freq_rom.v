// Input:  note[6:0] (0–127 MIDI note number)
// Output: freq[31:0] (integer frequency in Hz)

module midi_freq_rom (
    input  wire [6:0] note,
    output reg  [31:0] freq
);

    always @(*) begin
        case (note)
            7'd0:   freq = 8;      // C(-1)
            7'd1:   freq = 9;
            7'd2:   freq = 9;
            7'd3:   freq = 10;
            7'd4:   freq = 11;
            7'd5:   freq = 12;
            7'd6:   freq = 13;
            7'd7:   freq = 14;
            7'd8:   freq = 15;
            7'd9:   freq = 16;
            7'd10:  freq = 17;
            7'd11:  freq = 18;

            7'd12:  freq = 16;     // C0
            7'd13:  freq = 17;
            7'd14:  freq = 18;
            7'd15:  freq = 19;
            7'd16:  freq = 21;
            7'd17:  freq = 22;
            7'd18:  freq = 23;
            7'd19:  freq = 25;
            7'd20:  freq = 26;
            7'd21:  freq = 28;
            7'd22:  freq = 29;
            7'd23:  freq = 31;

            7'd24:  freq = 33;     // C1
            7'd25:  freq = 35;
            7'd26:  freq = 37;
            7'd27:  freq = 39;
            7'd28:  freq = 41;
            7'd29:  freq = 44;
            7'd30:  freq = 46;
            7'd31:  freq = 49;
            7'd32:  freq = 52;
            7'd33:  freq = 55;
            7'd34:  freq = 58;
            7'd35:  freq = 62;

            7'd36:  freq = 65;     // C2
            7'd37:  freq = 69;
            7'd38:  freq = 73;
            7'd39:  freq = 78;
            7'd40:  freq = 82;
            7'd41:  freq = 87;
            7'd42:  freq = 93;
            7'd43:  freq = 98;
            7'd44:  freq = 104;
            7'd45:  freq = 110;
            7'd46:  freq = 117;
            7'd47:  freq = 123;

            7'd48:  freq = 131;    // C3
            7'd49:  freq = 139;
            7'd50:  freq = 147;
            7'd51:  freq = 156;
            7'd52:  freq = 165;
            7'd53:  freq = 175;
            7'd54:  freq = 185;
            7'd55:  freq = 196;
            7'd56:  freq = 208;
            7'd57:  freq = 220;
            7'd58:  freq = 233;
            7'd59:  freq = 247;

            7'd60:  freq = 262;    // C4 (middle C)
            7'd61:  freq = 277;
            7'd62:  freq = 294;
            7'd63:  freq = 311;
            7'd64:  freq = 330;
            7'd65:  freq = 349;
            7'd66:  freq = 370;
            7'd67:  freq = 392;
            7'd68:  freq = 415;
            7'd69:  freq = 440;    // A4
            7'd70:  freq = 466;
            7'd71:  freq = 494;

            7'd72:  freq = 523;    // C5
            7'd73:  freq = 554;
            7'd74:  freq = 587;
            7'd75:  freq = 622;
            7'd76:  freq = 659;
            7'd77:  freq = 698;
            7'd78:  freq = 740;
            7'd79:  freq = 784;
            7'd80:  freq = 831;
            7'd81:  freq = 880;
            7'd82:  freq = 932;
            7'd83:  freq = 988;

            7'd84:  freq = 1047;   // C6
            7'd85:  freq = 1109;
            7'd86:  freq = 1175;
            7'd87:  freq = 1245;
            7'd88:  freq = 1319;
            7'd89:  freq = 1397;
            7'd90:  freq = 1480;
            7'd91:  freq = 1568;
            7'd92:  freq = 1661;
            7'd93:  freq = 1760;
            7'd94:  freq = 1865;
            7'd95:  freq = 1976;

            7'd96:  freq = 2093;   // C7
            7'd97:  freq = 2217;
            7'd98:  freq = 2349;
            7'd99:  freq = 2489;
            7'd100: freq = 2637;
            7'd101: freq = 2794;
            7'd102: freq = 2960;
            7'd103: freq = 3136;
            7'd104: freq = 3322;
            7'd105: freq = 3520;
            7'd106: freq = 3729;
            7'd107: freq = 3951;

            7'd108: freq = 4186;   // C8
            7'd109: freq = 4435;
            7'd110: freq = 4699;
            7'd111: freq = 4978;
            7'd112: freq = 5274;
            7'd113: freq = 5588;
            7'd114: freq = 5920;
            7'd115: freq = 6272;
            7'd116: freq = 6645;
            7'd117: freq = 7040;
            7'd118: freq = 7459;
            7'd119: freq = 7902;

            7'd120: freq = 8372;    // C9
            7'd121: freq = 8870;
            7'd122: freq = 9397;
            7'd123: freq = 9956;
            7'd124: freq = 10548;
            7'd125: freq = 11175;
            7'd126: freq = 11840;
            7'd127: freq = 12544;

            default: freq = 0;
        endcase
    end

endmodule
