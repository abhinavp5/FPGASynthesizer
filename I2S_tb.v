//////////////////////////////////////////////////////////////////////
// @author Abhinav Pappu & Claude 4 Shannon 
// I2S Testbench
// Tests I2S transmission with 8 sine wave samples (π/4 apart)
// Peak amplitude: 3.3V represented in 16-bit two's complement
//////////////////////////////////////////////////////////////////////
`timescale 1ns/10ps

module I2S_TB();
  
  parameter c_CLOCK_PERIOD_NS = 40;  
  parameter c_DIVISOR = 520;
  parameter c_NUM_BITS = 16;
  parameter c_M = 256;
  
  // Calculate timing parameters
  parameter c_SCLK_PERIOD = c_CLOCK_PERIOD_NS * 16;  // SCLK = CLK/16
  parameter c_LRCK_PERIOD = c_SCLK_PERIOD * c_NUM_BITS * 2;  // Full L+R cycle
  
  // Testbench signals
  reg r_Clock = 0;
  reg [15:0] r_Left_Data = 0;
  reg [15:0] r_Right_Data = 0;
  wire w_MCLK;
  wire w_LRCK;
  wire w_SCLK;
  wire w_SDIN;
  
  // Sine wave samples (8 points, π/4 apart, 16-bit two's complement)
  // Peak = 32767 (0x7FFF) for 3.3V representation
  // Formula: sample[i] = round(32767 * sin(i * π/4))
  reg [15:0] sine_samples [0:7];
  
  initial begin
    sine_samples[0] = 16'sd0;      // sin(0)     =  0.000 → 0
    sine_samples[1] = 16'sd23170;  // sin(π/4)   =  0.707 → 23170
    sine_samples[2] = 16'sd32767;  // sin(π/2)   =  1.000 → 32767 (max positive)
    sine_samples[3] = 16'sd23170;  // sin(3π/4)  =  0.707 → 23170
    sine_samples[4] = 16'sd0;      // sin(π)     =  0.000 → 0
    sine_samples[5] = -16'sd23170; // sin(5π/4)  = -0.707 → -23170
    sine_samples[6] = -16'sd32768; // sin(3π/2)  = -1.000 → -32768 (max negative)
    sine_samples[7] = -16'sd23170; // sin(7π/4)  = -0.707 → -23170
  end
  
  // Task to send one complete stereo sample (L+R)
  task SEND_STEREO_SAMPLE;
    input [15:0] i_Left;
    input [15:0] i_Right;
    integer wait_cycles;
    begin
      r_Left_Data <= i_Left;
      r_Right_Data <= i_Right;
      
      // Wait for one complete LRCK cycle (left + right transmission)
      wait_cycles = c_NUM_BITS * 2 * 16;  // bits * channels * SCLK_divisor
      repeat(wait_cycles) @(posedge r_Clock);
    end
  endtask

  
  // Serial data capture registers
  reg [15:0] captured_left_data;
  reg [15:0] captured_right_data;
  reg [4:0] bit_count;
  
  // Task to capture and verify serial data
  task CAPTURE_AND_VERIFY;
    input [15:0] expected_left;
    input [15:0] expected_right;
    begin
      // Wait for LRCK to go low (start of left channel)
      @(negedge w_LRCK);
      #1; // Small delay to avoid race conditions
      
      // Capture left channel (16 bits)
      captured_left_data = 16'b0;
      bit_count = 0;
      while (bit_count < 16) begin
        @(posedge w_SCLK);
        #1;
        captured_left_data = {captured_left_data[14:0], w_SDIN};
        bit_count = bit_count + 1;
      end
      
      // Verify left channel
      if (captured_left_data !== expected_left) begin
        $error("LEFT CHANNEL MISMATCH at time %0t: Expected %d (0x%h), Got %d (0x%h)", 
               $time, expected_left, expected_left, captured_left_data, captured_left_data);
      end else begin
        $display("LEFT CHANNEL OK: %d (0x%h)", captured_left_data, captured_left_data);
      end
      
      // Wait for LRCK to go high (start of right channel)
      @(posedge w_LRCK);
      #1;
      
      // Capture right channel (16 bits)
      captured_right_data = 16'b0;
      bit_count = 0;
      while (bit_count < 16) begin
        @(posedge w_SCLK);
        #1;
        captured_right_data = {captured_right_data[14:0], w_SDIN};
        bit_count = bit_count + 1;
      end
      
      // Verify right channel
      if (captured_right_data !== expected_right) begin
        $error("RIGHT CHANNEL MISMATCH at time %0t: Expected %d (0x%h), Got %d (0x%h)", 
               $time, expected_right, expected_right, captured_right_data, captured_right_data);
      end else begin
        $display("RIGHT CHANNEL OK: %d (0x%h)", captured_right_data, captured_right_data);
      end
    end
  endtask
  
  // Instantiate I2S module
  I2S #(
    .DIVISOR(c_DIVISOR),
    .NUM_OF_AMPLITUDE_BITS(c_NUM_BITS),
    .M(c_M)
  ) I2S_INST (
    .i_Clk(r_Clock),
    .i_RX_Serial_Left(r_Left_Data),
    .i_RX_serial_Right(r_Right_Data),
    .o_MCLK(w_MCLK),
    .o_LRCLK(w_LRCK),
    .o_SCLK(w_SCLK),
    .o_SDIN(w_SDIN)
  );
  
  // Clock generation
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
  
  // Monitor signals (optional - useful for debugging)
  always @(posedge w_LRCK) begin
    $display("Time: %0t - LRCK Rising Edge (Right Channel)", $time);
  end
  
  always @(negedge w_LRCK) begin
    $display("Time: %0t - LRCK Falling Edge (Left Channel)", $time);
  end
  
  // Main test sequence
  integer test_num;
  initial begin
    // Setup waveform dump
    $dumpfile("_build/default/I2S_tb.vcd");
    $dumpvars(0, I2S_TB);

    repeat(100) @(posedge r_Clock);

    // Test all 8 sine wave samples
    for (test_num = 0; test_num < 8; test_num = test_num + 1) begin
      $display("\n=== Test %0d: Sine sample %0d ===", test_num, test_num);
      $display("Expected value: %d (0x%h)", sine_samples[test_num], sine_samples[test_num]);
      
      // Send same sine sample to both left and right channels (mono)
      SEND_STEREO_SAMPLE(sine_samples[test_num], sine_samples[test_num]);
      
      // Wait a bit for data to propagate
      repeat(10) @(posedge r_Clock);
      
      // Capture and verify the serial output
      CAPTURE_AND_VERIFY(sine_samples[test_num], sine_samples[test_num]);
      
      // Wait between tests
      repeat(50) @(posedge r_Clock);
    end
    
    $display("\n=== All tests completed ===");
        $finish();
  end
  
  // Timeout protection
  initial begin
    #100000000;  // 100ms timeout
    $display("ERROR: Testbench timeout!");
    $finish();
  end
endmodule
