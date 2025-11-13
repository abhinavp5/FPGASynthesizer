/*
UART_RX module to UART bytes from MIDI
- 115200 baud rate 
- 8 data bits (7 for MIDI note and 1 for On/OFF)
- 0 parity bits
- 1 stop bit
- no flow control
CLKS_PER_BIT = CLK_FREQUNECY/BAUDRATE
*/
module UART_RX #(parameter CLKS_PER_BIT = 217)(
    input           i_Clk, 
    input           i_RX_Serial,
    output          o_RX_DV, // pulse to indicate data valid or not
    output [7:0]    o_RX_Byte
    );

    // States of the State machine (Values of RX_State_machine )
    localparam IDLE         = 3'b000; 
    localparam RX_START_BIT = 3'b001; 
    localparam RX_DATA_BIT  = 3'b010; // 217/2 clock cycles
    localparam RX_STOP_BIT  = 3'b011;
    localparam CLEANUP      = 3'b100; 

    reg [7:0]     r_Clock_Count = 0;
    reg [2:0]     r_Bit_Index   = 0; //8 bits total
    reg [7:0]     r_RX_Byte     = 0;
    reg           r_RX_DV       = 0;
    reg [2:0]     r_SM_Main     = 0;


    always @(posedge i_Clk) begin
        case(r_SM_Main)
                IDLE: // State 1 -> Waiting for Serial 
                    begin
                        r_RX_DV       <= 1'b0;
                        r_Clock_Count <= 0;
                        r_Bit_Index   <= 0;
                        
                        if (i_RX_Serial == 1'b0) // Start bit detected
                            r_SM_Main <= RX_START_BIT; // Transition to next state
                        else
                            r_SM_Main <= IDLE;
                    end
                RX_START_BIT: // State 2 - Start bit has been detected (Falling edge of start bit)
                    begin
                        if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
                        begin
                            if (i_RX_Serial == 1'b0)
                                begin
                                    r_Clock_Count <= 0;  // reset counter, found the middle
                                    r_SM_Main     <= RX_DATA_BIT;
                                end
                            else
                                r_SM_Main <= IDLE;
                        end
                    
                        else
                            begin
                                r_Clock_Count <= r_Clock_Count + 1;
                                r_SM_Main     <= RX_START_BIT;
                            end
                    end
                RX_DATA_BIT:
                    begin
                        if (r_Clock_Count < CLKS_PER_BIT-1)
                        begin
                            r_Clock_Count <= r_Clock_Count+1; 
                            r_SM_Main <= r_SM_Main; // stay in the stame state until have a enough clock cycles have elasped
                        end
                        else
                        begin
                            //Enough clock cycles have elapsed for new data bit to appear
                            r_Clock_Count <= 0; 
                            r_RX_Byte[r_Bit_Index] <= i_RX_Serial; // Captuing the bit
                            // Check number of data bits recieved to decied next state exp - 1 byte 
                            if (r_Bit_Index <7 )
                            begin
                                r_Bit_Index <= r_Bit_Index +1; 
                                r_SM_Main <= RX_DATA_BIT; 
                            end
                            else
                            begin
                                r_Bit_Index <=0 ; 
                                r_SM_Main <= RX_STOP_BIT;  // State transitino because all data bytes have been recieved
                            end
                        end
                    end
                RX_STOP_BIT:
                    begin
                        //waiting CLKS_PER_BUT-1 clock cycles for stop bit to finish
                        if (r_Clock_Count < CLKS_PER_BIT-1)
                        begin
                            r_Clock_Count <= r_Clock_Count+1; 
                            r_SM_Main <= RX_STOP_BIT; 
                        end
                        else
                        begin
                            r_RX_DV   <= 1'b1; //indicating data value has been recieved
                            r_SM_Main <= CLEANUP; 
                        end
                    end
                CLEANUP:
                    begin
                        // Resetting State and data value
                        r_SM_Main <= IDLE; 
                        r_RX_DV <= 1'b0; 

                    end
        endcase
    end

    assign o_RX_DV = r_RX_DV; 
    assign o_RX_Byte = r_RX_Byte; 


    
endmodule
