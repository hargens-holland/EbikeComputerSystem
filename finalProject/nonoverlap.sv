module nonoverlap(
    input logic clk,       // 50 MHz clock
    input logic rst_n,     // Reset active low
    input logic highIn,    // Control for high side FET
    input logic lowIn,     // Control for low side FET
    output logic highOut,  // Control for high side FET with ensured non-overlap
    output logic lowOut    // Control for low side FET with ensured non-overlap
);
    // Input registers to detect changes
    logic highIn_r, lowIn_r;
    
    // Dead time counter (5-bit)
    logic [4:0] counter;
    
    // Input edge detection registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            highIn_r <= 1'b0;
            lowIn_r <= 1'b0;
        end else begin
            highIn_r <= highIn;
            lowIn_r <= lowIn;
        end
    end
    
    // Edge detection (change detection)
    logic change_detected;
    assign change_detected = (highIn != highIn_r) || (lowIn != lowIn_r);
    
    // Counter for tracking dead time
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 5'd0;
        end else if (change_detected) begin
            // Reset counter when change detected
            counter <= 5'd0;
        end else if (counter != 5'd31) begin
            // Keep counting until maximum
            counter <= counter + 1'b1;
        end
    end
    
    // Output registers - CORRECTED to prevent both outputs being high
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            highOut <= 1'b0;
            lowOut <= 1'b0;
        end else if (change_detected || counter < 5'd31) begin
            // During dead time (including when change is detected)
            highOut <= 1'b0;
            lowOut <= 1'b0;
        end else begin
            // SAFETY CHECK: Prevent both outputs being high simultaneously
            // Prioritize high side if both are requested
            if (highIn) begin
                highOut <= 1'b1;
                lowOut <= 1'b0;  // Force low side off when high side requested
            end else begin
                highOut <= 1'b0;
                lowOut <= lowIn;  // Only allow low side when high side not requested
            end
        end
    end
    
endmodule