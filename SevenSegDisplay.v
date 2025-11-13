module SevenSegDisplay (
    input [7:0] i_byte, // 1 byte input 
    output S1_A, 
    output S1_B,
    output S1_C, 
    output S1_D,
    output S1_E, 
    output S1_F, 
    output S1_G,
    output S2_A, 
    output S2_B,
    output S2_C, 
    output S2_D,
    output S2_E, 
    output S2_F, 
    output S2_G
); 

    reg [6:0] r_hex_encoding_d0; 
    reg [6:0] r_hex_encoding_d1; 
    
    // Decode lower nibble (bits 3:0) for display 1
    always @(*) begin
        case (i_byte[3:0])
            4'b0000 : r_hex_encoding_d0 = 7'h7E;
            4'b0001 : r_hex_encoding_d0 = 7'h30;
            4'b0010 : r_hex_encoding_d0 = 7'h6D;
            4'b0011 : r_hex_encoding_d0 = 7'h79;
            4'b0100 : r_hex_encoding_d0 = 7'h33;
            4'b0101 : r_hex_encoding_d0 = 7'h5B;
            4'b0110 : r_hex_encoding_d0 = 7'h5F;
            4'b0111 : r_hex_encoding_d0 = 7'h70;
            4'b1000 : r_hex_encoding_d0 = 7'h7F;
            4'b1001 : r_hex_encoding_d0 = 7'h7B;
            4'b1010 : r_hex_encoding_d0 = 7'h77;
            4'b1011 : r_hex_encoding_d0 = 7'h1F;
            4'b1100 : r_hex_encoding_d0 = 7'h4E;
            4'b1101 : r_hex_encoding_d0 = 7'h3D;
            4'b1110 : r_hex_encoding_d0 = 7'h4F;
            4'b1111 : r_hex_encoding_d0 = 7'h47;
        endcase
    end
    
    // Decode upper nibble (bits 7:4) for display 2
    always @(*) begin
        case (i_byte[7:4])
            4'b0000 : r_hex_encoding_d1 = 7'h7E;
            4'b0001 : r_hex_encoding_d1 = 7'h30;
            4'b0010 : r_hex_encoding_d1 = 7'h6D;
            4'b0011 : r_hex_encoding_d1 = 7'h79;
            4'b0100 : r_hex_encoding_d1 = 7'h33;
            4'b0101 : r_hex_encoding_d1 = 7'h5B;
            4'b0110 : r_hex_encoding_d1 = 7'h5F;
            4'b0111 : r_hex_encoding_d1 = 7'h70;
            4'b1000 : r_hex_encoding_d1 = 7'h7F;
            4'b1001 : r_hex_encoding_d1 = 7'h7B;
            4'b1010 : r_hex_encoding_d1 = 7'h77;
            4'b1011 : r_hex_encoding_d1 = 7'h1F;
            4'b1100 : r_hex_encoding_d1 = 7'h4E;
            4'b1101 : r_hex_encoding_d1 = 7'h3D;
            4'b1110 : r_hex_encoding_d1 = 7'h4F;
            4'b1111 : r_hex_encoding_d1 = 7'h47;
        endcase
    end
    
    // Digit 1 (lower nibble)
    assign S1_A = ~r_hex_encoding_d0[6]; 
    assign S1_B = ~r_hex_encoding_d0[5]; 
    assign S1_C = ~r_hex_encoding_d0[4]; 
    assign S1_D = ~r_hex_encoding_d0[3]; 
    assign S1_E = ~r_hex_encoding_d0[2]; 
    assign S1_F = ~r_hex_encoding_d0[1]; 
    assign S1_G = ~r_hex_encoding_d0[0]; 
    
    // Digit 2 (upper nibble)
    assign S2_A = ~r_hex_encoding_d1[6]; 
    assign S2_B = ~r_hex_encoding_d1[5]; 
    assign S2_C = ~r_hex_encoding_d1[4]; 
    assign S2_D = ~r_hex_encoding_d1[3]; 
    assign S2_E = ~r_hex_encoding_d1[2]; 
    assign S2_F = ~r_hex_encoding_d1[1]; 
    assign S2_G = ~r_hex_encoding_d1[0]; 

endmodule
