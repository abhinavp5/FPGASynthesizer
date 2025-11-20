module I2S #(
  parameter integer DIVISOR = 512,                  // i_Clk / DIVISOR = sample rate (LRCLK freq)
  parameter integer NUM_OF_AMPLITUDE_BITS = 16,     // bits per channel
  parameter integer M = 256
  )(
  input  wire                 i_Clk,
  input  wire [NUM_OF_AMPLITUDE_BITS-1:0] i_RX_Serial_Left,
  input  wire [NUM_OF_AMPLITUDE_BITS-1:0] i_RX_Serial_Right,
  output reg                  o_MCLK = 1'b0,
  output reg                  o_LRCLK = 1'b1,
  output reg                  o_SCLK = 1'b0,
  output reg                  o_SDIN = 1'b0
);

  //CONSTANTS
  localparam integer TOTAL_BITS = NUM_OF_AMPLITUDE_BITS * 2; // bits per frame (left+right) ex. 16 bits per channel * 2 channels = 32 bits per frame
  // SCLK period (in i_Clk cycles) = DIVISOR / TOTAL_BITS
  // SCLK toggle interval (half period) = (DIVISOR / TOTAL_BITS) / 2 = DIVISOR / (TOTAL_BITS*2)
  //EX. DIVISOR = 512, TOTAL_BITS = 32, SCLK_TOGGLE = 512 / (32 * 2) = 8
  //SCLK_TOGGLE is the number of i_Clk cycles for one toggle of the SCLK
  localparam integer BITS_PER_FRAME = 64;
  localparam integer SCLK_TOGGLE = DIVISOR / (BITS_PER_FRAME * 2);
  // localparam integer SCLK_TOGGLE = DIVISOR / (64 * 2); // = 4 // 64 is the number of bits per frame

  // MCLK_TOGGLE is the number of i_Clk cycles for one toggle of the MCLK
  // MCLK_TOGGLE is always 2 for 50/50 duty
  localparam integer MCLK_TOGGLE = 2;

  // Counter widths (for LR, SCLK, and MCLK)
  localparam LR_CNT_WIDTH   = $clog2(DIVISOR) + 1;
  localparam SCLK_CNT_WIDTH = $clog2(SCLK_TOGGLE) + 1;
  localparam MCLK_CNT_WIDTH = $clog2(MCLK_TOGGLE) + 1;

  // Initialize Counter
  reg [LR_CNT_WIDTH-1:0]   lr_cnt    = 0;
  reg [SCLK_CNT_WIDTH-1:0] sclk_cnt  = 0;
  reg [MCLK_CNT_WIDTH-1:0] mclk_cnt  = 0;

  // shift register and bit index
  reg [NUM_OF_AMPLITUDE_BITS-1:0] shift_reg = 0;
  reg [$clog2(NUM_OF_AMPLITUDE_BITS)-1:0] bit_index = 0;

  //FSM STATES
  //LEFT_CHANNEL_WAIT--> LEFT_CHANNEL--> LEFT_CHANNEL_BURN--> RIGHT_CHANNEL_WAIT--> RIGHT_CHANNEL--> RIGHT_CHANNEL_BURN--> LEFT_CHANNEL_WAIT
  localparam LEFT_CHANNEL_WAIT  = 3'b000;
  localparam LEFT_CHANNEL       = 3'b001;
  localparam LEFT_CHANNEL_BURN  = 3'b010;
  localparam RIGHT_CHANNEL      = 3'b011;
  localparam RIGHT_CHANNEL_WAIT = 3'b100;
  localparam RIGHT_CHANNEL_BURN = 3'b101;
  reg [2:0] r_SM_Main = LEFT_CHANNEL_WAIT;

  // Sampling Frequency/LRCLK generation
  // Clock Frequency = i_Clk / DIVISOR
  // Ex. 25MHz / 512 = 48.8kHz
  always @(posedge i_Clk) begin
      if (lr_cnt == DIVISOR - 1) lr_cnt <= 0;
      else lr_cnt <= lr_cnt + 1;
      // i_Clk[0-255] = 0, i_Clk[256-511] = 1
      o_LRCLK <= !(lr_cnt < (DIVISOR >> 1)); 
    end


  // SCLK generation: toggle every SCLK_TOGGLE cycles for 50/50 duty (if SCLK_TOGGLE integer)
  reg sclk_rising_pulse;
  always @(posedge i_Clk) begin
    sclk_rising_pulse <= 1'b0;
    if (SCLK_TOGGLE < 1) begin
      // no-op, prevents divide by zero
      sclk_cnt <= 0;
      o_SCLK <= 1'b0;
    end else begin
      if (sclk_cnt == SCLK_TOGGLE - 1) begin
        sclk_cnt <= 0;
        // Rising edge of SCLK
        if (o_SCLK == 1'b0) begin
          sclk_rising_pulse <= 1'b1; 
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
        LEFT_CHANNEL_WAIT: //Wait 1 SCLK cycle begin
        begin
          r_SM_Main <= LEFT_CHANNEL;
          bit_index <= 0;
        end
        LEFT_CHANNEL: begin
          if (bit_index == 0) begin
          shift_reg <= i_RX_Serial_Left;

          // output MSB now (MSB first)
          o_SDIN <=  i_RX_Serial_Left[NUM_OF_AMPLITUDE_BITS-1];
          bit_index <= 1;
        end
        else if (bit_index < NUM_OF_AMPLITUDE_BITS) begin
          // shift left: next MSB becomes output
          shift_reg <= {shift_reg[NUM_OF_AMPLITUDE_BITS-2:0], 1'b0};
          o_SDIN <= shift_reg[NUM_OF_AMPLITUDE_BITS-1];
          bit_index <= bit_index + 1;
        end
        else begin
          // finished channel--> Swap to next state
          bit_index <= 0;
          r_SM_Main <= LEFT_CHANNEL_BURN;
        end
        end
        LEFT_CHANNEL_BURN:
        begin
          if (CYCLE_DELAY_COUNT < CYCLE_DELAY)begin
            CYCLE_DELAY_COUNT <= CYCLE_DELAY_COUNT+1;
          end
          else begin
            CYCLE_DELAY_COUNT <= 0 ;
            r_SM_Main <= RIGHT_CHANNEL_WAIT;
          end
        end
        RIGHT_CHANNEL_WAIT:
        begin
          r_SM_Main <= RIGHT_CHANNEL;
          bit_index <= 0;
        end
        RIGHT_CHANNEL:
        begin
         if (bit_index == 0) begin
          shift_reg <= i_RX_Serial_Right;
          // output MSB now (MSB first)
          o_SDIN <=  i_RX_Serial_Right[NUM_OF_AMPLITUDE_BITS-1];
          bit_index <= 1;
        end
        else if (bit_index < NUM_OF_AMPLITUDE_BITS) begin
          // shift left: next MSB becomes output
          shift_reg <= {shift_reg[NUM_OF_AMPLITUDE_BITS-2:0], 1'b0};
          o_SDIN <= shift_reg[NUM_OF_AMPLITUDE_BITS-1];
          bit_index <= bit_index + 1;
        end
        else begin
          // finished channel--> Swap to next state
          bit_index <= 0;
          r_SM_Main <= RIGHT_CHANNEL_BURN;
        end
        end
        RIGHT_CHANNEL_BURN:
        begin
          if (CYCLE_DELAY_COUNT < CYCLE_DELAY)begin
            CYCLE_DELAY_COUNT <= CYCLE_DELAY_COUNT + 1;
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
