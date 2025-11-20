
module I2S #(
  parameter integer DIVISOR = 512,                  // i_Clk / DIVISOR = sample rate (LRCLK freq)
  parameter integer NUM_OF_AMPLITUDE_BITS = 16,     // bits per channel
  parameter integer M = 256                         
)(

  input  wire                 i_Clk,
  input  wire [NUM_OF_AMPLITUDE_BITS-1:0] i_RX_Serial_Left,
  input  wire [NUM_OF_AMPLITUDE_BITS-1:0] i_RX_serial_Right,
  output reg                  o_MCLK = 1'b0,
  output reg                  o_LRCLK = 1'b0,
  output reg                  o_SCLK = 1'b0,
  output reg                  o_SDIN = 1'b0
);

  //CONSTANTS
  localparam integer TOTAL_BITS = NUM_OF_AMPLITUDE_BITS * 2; // bits per frame (left+right) ex. 16 bits per channel * 2 channels = 32 bits per frame
  // SCLK period (in i_Clk cycles) = DIVISOR / TOTAL_BITS
  // SCLK toggle interval (half period) = (DIVISOR / TOTAL_BITS) / 2 = DIVISOR / (TOTAL_BITS*2)
  //EX. DIVISOR = 512, TOTAL_BITS = 32, SCLK_TOGGLE = 512 / (32 * 2) = 8
  //SCLK_TOGGLE is the number of i_Clk cycles for one toggle of the SCLK
  localparam integer SCLK_TOGGLE = (DIVISOR) / (TOTAL_BITS * 2);

  // MCLK_TOGGLE is the number of i_Clk cycles for one toggle of the MCLK
  // MCLK_TOGGLE is always 2 for 50/50 duty
  localparam integer MCLK_TOGGLE = 2;

  // Functino to generate the number of bits required for the counter
  // LR_CNT_WIDTH is the number of bits required for the LR counter
  // EX. DIVISOR = 512, LR_CNT_WIDTH = $clog2(512) + 1 = 9
  localparam LR_CNT_WIDTH   = $clog2(DIVISOR) + 1;
  localparam SCLK_CNT_WIDTH = $clog2((SCLK_TOGGLE>0)?SCLK_TOGGLE:1) + 1;
  localparam MCLK_CNT_WIDTH = $clog2(MCLK_TOGGLE);
  localparam LR_CNT_MAX = DIVISOR>>1;

  // Initialize Counter
  reg [LR_CNT_WIDTH-1:0]   lr_cnt    = 0;
  reg [SCLK_CNT_WIDTH-1:0] sclk_cnt  = 0;
  reg [MCLK_CNT_WIDTH-1:0] mclk_cnt  = 0;

  // shift register and bit index
  reg [NUM_OF_AMPLITUDE_BITS-1:0] shift_reg = 0;
  reg [$clog2(NUM_OF_AMPLITUDE_BITS)-1:0] bit_index = 0;


  //FSM STATES 
  localparam LEFT_CHANNEL = 0;
  localparam RIGHT_CHANNEL = 1;
  reg current_channel = LEFT_CHANNEL; 

  // Sampling Frequency/LRCLK generation
  always @(posedge i_Clk) 
  begin
    if (lr_cnt == DIVISOR - 1) lr_cnt <= 0;
    else lr_cnt <= lr_cnt + 1;

    // LRCLK is high for first half of DIVISOR, low for second (or vice versa)
    o_LRCLK <= (lr_cnt < (DIVISOR >> 1));
  end

  // SCLK generation: toggle every SCLK_TOGGLE cycles for 50/50 duty (if SCLK_TOGGLE integer)
  // We produce a strobe `sclk_rising_strobe` when SCLK will transition low->high.
  reg sclk_rising_strobe;
  always @(posedge i_Clk) begin
    sclk_rising_strobe <= 1'b0;

    if (SCLK_TOGGLE < 1) begin
      // no-op, prevents divide by zero
      sclk_cnt <= 0;
      o_SCLK <= 1'b0;
    end else begin
      if (sclk_cnt == SCLK_TOGGLE - 1) begin
        sclk_cnt <= 0;
        // determine if this toggle is rising edge
        if (o_SCLK == 1'b0) begin
          sclk_rising_strobe <= 1'b1; // we'll go low->high this cycle
        end
        o_SCLK <= ~o_SCLK;
      end else begin
        sclk_cnt <= sclk_cnt + 1;
      end
    end
  end

  // MCLK generation (simple divider)
  always @(posedge i_Clk) begin
    if (mclk_cnt == MCLK_TOGGLE - 1) begin
      mclk_cnt <= 0;
      o_MCLK <= ~o_MCLK;
    end else begin
      mclk_cnt <= mclk_cnt + 1;
    end
  end

  // --- I2S shift logic (driven by sclk_rising_strobe, not posedge of o_SCLK) ---
  // We shift one bit per SCLK rising edge. On the first bit of each channel we preload the
  // channel's sample into the shift register and output its MSB immediately.
  always @(posedge i_Clk) begin
    if (sclk_rising_strobe) begin
      // If bit_index == 0, load new channel sample
      if (bit_index == 0) begin
        if (current_channel == 1'b0) begin
          shift_reg <= i_RX_Serial_Left;
        end else begin
          shift_reg <= i_RX_serial_Right;
        end
        // output MSB now (MSB first)
        o_SDIN <= (NUM_OF_AMPLITUDE_BITS>0) ? shift_reg[NUM_OF_AMPLITUDE_BITS-1] : 1'b0;
        bit_index <= 1;
      end
      else if (bit_index < NUM_OF_AMPLITUDE_BITS) begin
        // shift left: next MSB becomes output
        shift_reg <= {shift_reg[NUM_OF_AMPLITUDE_BITS-2:0], 1'b0};
        o_SDIN <= shift_reg[NUM_OF_AMPLITUDE_BITS-1];
        bit_index <= bit_index + 1;
      end
      else begin
        // finished both channels? toggle channel and reset bit index
        bit_index <= 0;
        current_channel <= ~current_channel;
      end
    end
    // else: no SCLK rising edge => hold outputs / counters
  end

endmodule
