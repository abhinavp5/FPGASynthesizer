module sine_rom #(
    parameter ADDR_BITS = 8,
    parameter DATA_BITS = 12,
    parameter FILE = "sine_rom.hex"
)(
    input wire clk,
    //address of the ROM file we want to select
    input wire [ADDR_BITS-1:0] addr,
    //current amplitude output
    output reg [DATA_BITS-1:0] data
);
    //rom register is DATA_BITS wide and has 2^ADDR_BITS entries (256 for a 1 byte address)
    reg [DATA_BITS-1:0] rom [0:(1<<ADDR_BITS)-1];

    //read the file
    initial begin
        $readmemh(FILE, rom);
    end

    //always read from whatever address is given (this will update based on phase_inc in the top module)
    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule
