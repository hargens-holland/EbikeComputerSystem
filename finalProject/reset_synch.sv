module reset_synch(
    input  logic RST_n,  // Raw input from push button
    input  logic clk,    // Clock signal (we use negative edge)
    output logic rst_n   // Synchronized output (global reset)
);

    // Two flip-flops for double-flopping (meta-stability handling)
    logic q1;
    
    // First flip-flop - asynchronous preset when button is pressed (RST_n is low)
    always_ff @(negedge clk, negedge RST_n) begin
        if (!RST_n)
            q1 <= 1'b0;  // Reset when button is pressed
        else
            q1 <= 1'b1;  // Set when button is released
    end
    
    // Second flip-flop - asynchronous preset when button is pressed (RST_n is low)
    always_ff @(negedge clk, negedge RST_n) begin
        if (!RST_n)
            rst_n <= 1'b0;  // Reset when button is pressed
        else
            rst_n <= q1;    // Synchronized reset signal
    end

endmodule