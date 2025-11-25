
module Debounce_Filter #(parameter DEBOUNCE_LIMIT = 20) (
  input  i_Clk,
  input reset,
  input  i_Bouncy,
  output o_Debounced);

  reg [$clog2(DEBOUNCE_LIMIT)-1:0] r_Count_cs = 0;
  reg [$clog2(DEBOUNCE_LIMIT)-1:0] r_Count_ns = 0;

  reg r_Sample_1_cs;
  reg r_Sample_1_ns = 1'b0;

  reg r_Sample_2_cs;
  reg r_Sample_2_ns = 1'b0;

  reg r_debounce = 1'b0;

  // Current State -- Sequential Logic
  always @(posedge i_Clk or posedge reset) begin
    if (reset) begin
	r_Count_cs <= 0;
	r_Sample_1_cs <= 1'b0;
	r_Sample_2_cs <= 1'b0;
    end else 
	begin
	  r_Count_cs <= r_Count_ns;
	  r_Sample_1_cs <= r_Sample_1_ns;
	  r_Sample_2_cs <= r_Sample_2_ns;
	end
    end
	

  // Next State -- Combinational Logic
  always @(*) begin
    r_Sample_1_ns = i_Bouncy;
    r_Sample_2_ns = r_Sample_1_cs;

    if (r_Sample_1_cs !== r_Sample_2_cs)
      begin
	r_Count_ns = 0;
      end
    else if (r_Count_cs < DEBOUNCE_LIMIT - 1)
      begin
	r_Count_ns = r_Count_cs + 1;
      end
    else
      begin
	r_Count_ns = 0;
	r_debounce = r_Sample_1_cs;
      end
  end


  assign o_Debounced = r_debounce;

endmodule

