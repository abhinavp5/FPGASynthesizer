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

  //CONSTANTS
  localparam integer TOTAL_BITS = NUM_OF_AMPLITUDE_BITS * 2; // bits per frame (left+right) ex. 16 bits per channel * 2 channels = 32 bits per frame
  // SCLK period (in i_Clk cycles) = DIVISOR / TOTAL_BITS
  // SCLK toggle interval (half period) = (DIVISOR / TOTAL_BITS) / 2 = DIVISOR / (TOTAL_BITS*2)
  //EX. DIVISOR = 512, TOTAL_BITS = 32, SCLK_TOGGLE = 512 / (32 * 2) = 8
  //SCLK_TOGGLE is the number of i_Clk cycles for one toggle of the SCLK
  localparam integer BITS_PER_FRAME = TOTAL_BITS*2;
  localparam integer SCLK_TOGGLE = DIVISOR / (BITS_PER_FRAME * 2);
  // localparam integer SCLK_TOGGLE = DIVISOR / (64 * 2); // = 4 // 64 is the number of bits per frame

    reg [15:0] shift_register;
    /*
    reg sampling_rate = i_CLK / DIVISOR;
    where sampling rate is equal to 48Khz
    assign o_SCLK = samplingrate * 16 ; //2 channels * Sampling Rate * 16 for the bit resolution
    assign o_MCLK = sampling_rate* N ;
    assign o_LRCLK = sampling_rate; // For every 1 tick of the LRCLK 2^16(bit depth in our case) values get transmitted
    */

  // Counter widths (for LR, SCLK, and MCLK)
  localparam LR_CNT_WIDTH   = $clog2(DIVISOR) + 1;
  localparam SCLK_CNT_WIDTH = $clog2(SCLK_TOGGLE) + 1;
  localparam MCLK_CNT_WIDTH = $clog2(MCLK_TOGGLE) + 1;

    // Generate Serial Clock --> 25 Mhhz/16
    always @(posedge i_Clk)
    begin 
        if (serial_counter == 7)
        begin
          o_SCLK <= ~ o_SCLK;
        end
        o_SCLK <= ~o_SCLK; // Toggle SCLK
      end else begin
        sclk_cnt <= sclk_cnt + 1;
      end
    end
  end

  // MCLK generation (simple divider)
  // Clock Frequency = i_Clk / MCLK_TOGGLE
  // Ex. 25MHz / 2 = 12.5MHz
  always @(posedge i_Clk) begin
    if (mclk_cnt == MCLK_TOGGLE - 1) begin
      mclk_cnt <= 0;
      o_MCLK <= ~o_MCLK;
    end else begin
      mclk_cnt <= mclk_cnt + 1;
    end
  end



  // I2S shift logic
  // We shift one bit per SCLK rising edge. On the first bit of each channel we preload the
  // channel's sample into the shift register and output its MSB immediately.
  localparam integer CYCLE_DELAY = TOTAL_BITS-1-NUM_OF_AMPLITUDE_BITS;
  reg [$clog2(CYCLE_DELAY):0] CYCLE_DELAY_COUNT= 0;

  always @(posedge i_Clk) begin
    // Clocking data on falling edge of serial clock
    if (sclk_rising_pulse) begin
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
            CYCLE_DELAY_COUNT <= 0 ;
            r_SM_Main <= RIGHT_CHANNEL_WAIT;
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
            CYCLE_DELAY_COUNT <= 0;
            r_SM_Main <= LEFT_CHANNEL_WAIT;
          end
        end
        default:
          r_SM_Main <= LEFT_CHANNEL_WAIT; 
      endcase
    end
  end
endmodule
