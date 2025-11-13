
/*
N-Bit Coutner component
*/
module modncounter #(
    parameter WIDTH = 8, 
    RESET_VALUE = 0
    )(

    // Inputs
    input reset,   // reset input 
    input clock,    // clock input

    // Output
    output [WIDTH-1 : 0 ] o_Counter
    );

    //Defining Registers
    reg [WIDTH-1: 0 ] counterCurrentState; 
    reg [WIDTH-1: 0 ] counterNextState; 
    
    // Current State Logic 
    always @(posedge clock , posedge reset)
        begin 
            if (reset ==1)
                counterCurrentState <= RESET_VALUE ; 
            else
                counterCurrentState <= counterNextState;
        end

    // Next State Logic 
    always @(counterCurrentState)
        begin 
            counterNextState = counterCurrentState + 1;
        end

    // Output Logic 
    assign o_Counter = counterCurrentState; 
endmodule
