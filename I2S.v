module I2S #(
  parameter DIVISOR = 520, // sampling rate = i_Clk/  DIVISOR
  parameter NUM_OF_AMPLITUDE_BITS = 16, // 2^16 to represnet each number
  parameter M = 256
)(
    input           i_Clk,
    input           [15:0] i_RX_Serial_Left, // Serial Data will be a 2^16 bit value, will be the same send to both channels
    input           [15:0] i_RX_serial_Right,  
    output reg      o_MCLK = 0,
    output reg      o_LRCLK = 0 , // 
    output reg      o_SCLK = 0 , // Serial Clock
    output reg      o_SDIN // Output bit
);  

    // Counters for generating 3 different clock signals
    reg       master_counter = 0; 
    reg [3:0]  serial_counter = 0; 
    reg [4:0] bit_counter = 0 ; 

    reg [15:0] shift_register;
    /*
    reg sampling_rate = i_CLK / DIVISOR;
    where sampling rate is equal to 48Khz
    assign o_SCLK = samplingrate * 16 ; //2 channels * Sampling Rate * 16 for the bit resolution
    assign o_MCLK = sampling_rate* N ;
    assign o_LRCLK = sampling_rate; // For every 1 tick of the LRCLK 2^16(bit depth in our case) values get transmitted
    */

    // State Machine States - Either Right or Left Channel
    localparam WS_LEFT      = 0;
    localparam WS_RIGHT     = 1;
    reg        r_SM_Main = 0; 

    // Generate Serial Clock --> 25 Mhhz/16
    always @(posedge i_Clk)
    begin 
        if (serial_counter == 7)
        begin
          o_SCLK <= ~ o_SCLK;
        end
        serial_counter <= serial_counter +1; 
    end
    

    // Generate Master Clock --> 25 Mhz/ 2
    always @(posedge i_Clk) 
    begin
      // clocks every 2 i_Clk cycles;
      if (master_counter ==0)
      begin
        o_MCLK <= ~o_MCLK;
      end
      master_counter <= master_counter + 1; 
    end

    // FSM and shift register logic for output
    // LR CLOK is also contained which is SERIAL_CLK/(16(bitresolution) and 2 (num channels))
    always @(posedge  o_SCLK)
    begin
      case (r_SM_Main)
        WS_LEFT:
        begin 
          o_LRCLK <= 0; // Clocking LR clock 0--> left channel 1 --> right channel
          if (bit_counter == 0)
          begin 
            shift_register <= i_RX_Serial_Left;
            bit_counter<= bit_counter +1;
            o_SDIN <= i_RX_Serial_Left[15]; // Assigning MSB to the data out
          end
          else if (bit_counter < NUM_OF_AMPLITUDE_BITS-1)
          begin
            o_SDIN <= shift_register[14]; // Output MSB BEFORE shifting (bit that will be lost)
            shift_register <= {shift_register[14:0], 1'b0};
            bit_counter <= bit_counter+1; 
          end
          else if  (bit_counter== NUM_OF_AMPLITUDE_BITS-1)
          begin
              o_SDIN <= shift_register[14]; // Output LSB (bit[0] after 15 shifts)
              bit_counter <= 0;
              r_SM_Main <= WS_RIGHT;
          end 
          else begin
              bit_counter <= bit_counter + 1;
          end
        end
        WS_RIGHT:
        begin 
          o_LRCLK <= 1; // Clocking LR clock 0--> left channel 1 --> right channel
          if (bit_counter == 0)
          begin 
            shift_register <= i_RX_serial_Right;
            bit_counter <= bit_counter +1;
            o_SDIN <= i_RX_serial_Right[15]; // Assigning MSB to the data out
          end
          else if (bit_counter < NUM_OF_AMPLITUDE_BITS-1)
          begin
            o_SDIN <= shift_register[14]; // Output MSB BEFORE shifting (bit that will be lost)
            shift_register <= {shift_register[14:0], 1'b0};
            bit_counter <= bit_counter+1; 
          end
          else if  (bit_counter== NUM_OF_AMPLITUDE_BITS-1)
          begin
              o_SDIN <= shift_register[14]; // Output LSB (bit[0] after 15 shifts)
              bit_counter <= 0;
              r_SM_Main <= WS_LEFT;
          end 
          else begin
              bit_counter <= bit_counter + 1;
          end
        end
      endcase
    end
endmodule
