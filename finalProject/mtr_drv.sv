module mtr_drv(
  input clk, rst_n, 
  input [10:0] duty,
  input [1:0] selGrn, selYlw, selBlu,
  output PWM_synch,
  output highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu
);

logic PWM_sig;

PWM pwm11(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_synch(PWM_synch), .PWM_sig(PWM_sig));

    // Inverted PWM signal
    logic PWM_n;
    assign PWM_n = ~PWM_sig;

    // Decode the select values for each coil
    // High and low side signals before non-overlap
    logic highGrn_pre, lowGrn_pre;
    logic highYlw_pre, lowYlw_pre;
    logic highBlu_pre, lowBlu_pre;

// Green coil high and low side control based on selGrn
    always_comb begin
        case(selGrn)
            2'b00: begin   // Not driven (high impedance)
                highGrn_pre = 1'b0;
                lowGrn_pre = 1'b0;
            end
            2'b01: begin   // Forward current (PWM_sig/~PWM_sig)
                highGrn_pre = PWM_n;
                lowGrn_pre = PWM_sig;
            end
            2'b10: begin   // Reverse current (~PWM_sig/PWM_sig)
                highGrn_pre = PWM_sig;
                lowGrn_pre = PWM_n;
            end
            2'b11: begin   // Dynamic braking (0 for high side, PWM for low side)
                highGrn_pre = 1'b0;
                lowGrn_pre = PWM_sig;
            end
        endcase
    end

    // Yellow coil high and low side control based on selYlw
    always_comb begin
        case(selYlw)
            2'b00: begin   // Not driven 
                highYlw_pre = 1'b0;
                lowYlw_pre = 1'b0;
            end
            2'b01: begin   // Forward current
                highYlw_pre = PWM_n;
                lowYlw_pre = PWM_sig;
            end
            2'b10: begin   // Reverse current 
                highYlw_pre = PWM_sig;
                lowYlw_pre = PWM_n;
            end
            2'b11: begin   // Dynamic braking 
                highYlw_pre = 1'b0;
                lowYlw_pre = PWM_sig;
            end
        endcase
    end

    // Blue coil high and low side control based on selBlu
    always_comb begin
        case(selBlu)
            2'b00: begin   // Not driven 
                highBlu_pre = 1'b0;
                lowBlu_pre = 1'b0;
            end
            2'b01: begin   // Forward current
                highBlu_pre = PWM_n;
                lowBlu_pre = PWM_sig;
            end
            2'b10: begin   // Reverse current
                highBlu_pre = PWM_sig;
                lowBlu_pre = PWM_n;
            end
            2'b11: begin   // Dynamic braking 
                highBlu_pre = 1'b0;
                lowBlu_pre = PWM_sig;
            end
        endcase
    end

    // Apply non-overlap to prevent shoot-through
    nonoverlap nol_Grn(
        .clk(clk),
        .rst_n(rst_n),
        .highIn(highGrn_pre),
        .lowIn(lowGrn_pre),
        .highOut(highGrn),
        .lowOut(lowGrn)
    );

    nonoverlap nol_Ylw(
        .clk(clk),
        .rst_n(rst_n),
        .highIn(highYlw_pre),
        .lowIn(lowYlw_pre),
        .highOut(highYlw),
        .lowOut(lowYlw)
    );

    nonoverlap nol_Blu(
        .clk(clk),
        .rst_n(rst_n),
        .highIn(highBlu_pre),
        .lowIn(lowBlu_pre),
        .highOut(highBlu),
        .lowOut(lowBlu)
    );

endmodule