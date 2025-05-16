module sensorCondition(
    input clk, rst_n,
    input [11:0] torque,
    input cadence_raw,
    input [11:0] curr,
    input [12:0] incline,
    input [2:0] scale,
    input [11:0] batt,
    output signed [12:0] error,
    output logic not_pedaling,
    output TX
);
    parameter FAST_SIM = 0;
    localparam LOW_BATT_THRES = 12'h400; // Battery threshold

    // Internal signals
    logic [21:0] sample_timer;
    logic include_sample;
    logic cadence_filt;
    logic cadence_rise;
    logic [7:0] cadence_per;
    logic [4:0] cadence;
    logic pedaling_resumes;
    logic [11:0] avg_torque;
    logic [15:0] torque_accum;
    logic [47:0] torque_mult;
    logic [13:0] curr_accum;
    logic [11:0] avg_curr;
    logic [11:0] target_curr;

    // Cadence filter for debouncing the cadence signal
    cadence_filt #(.FAST_SIM(FAST_SIM)) cadence_filt_inst(
        .clk(clk),
        .rst_n(rst_n),
        .cadence(cadence_raw),
        .cadence_filt(cadence_filt),
        .cadence_rise(cadence_rise)
    );

    // Measures the period of cadence pulses
    cadence_meas #(.FAST_SIM(FAST_SIM)) cadence_meas_inst(
        .cadence_filt(cadence_filt),
        .clk(clk),
        .rst_n(rst_n),
        .not_pedaling(not_pedaling),
        .cadence_per(cadence_per)
    );

    // Look up table for cadence values
    cadence_LU cadence_LU_inst(
        .cadence_per(cadence_per),
        .cadence(cadence)
    );

    // Sample timer for decimation
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n) 
            sample_timer <= 0;
        else
            sample_timer <= sample_timer + 1;
    end

    // Adjust sample period based on FAST_SIM parameter
    generate 
        if(FAST_SIM)
            assign include_sample = &sample_timer[15:0];
        else
            assign include_sample = &sample_timer;
    endgenerate

    // Detect when pedaling resumes 
    logic prev_not_pedaling;
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            prev_not_pedaling <= 1'b1;
        else
            prev_not_pedaling <= not_pedaling;
    end
    assign pedaling_resumes = prev_not_pedaling & ~not_pedaling;

    always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    torque_accum <= 16'b0;
  else if (pedaling_resumes)
     torque_accum <= ({1'b0, torque, 4'b0000}) >> 1; // seed with 16x torque
  else if (cadence_rise)
    torque_accum <= torque_mult[47:5]; // divide by 32
end
always_comb begin
  // Exponential average: (accum * (W-1) + input*W) >> log2(W)
  torque_mult = (torque_accum * 5'd31) + {torque, 4'b0000}; // torque * 16
end
   assign avg_torque = torque_accum[15:4]; 

    // Current exponential average
    logic [15:0] curr_mult;
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            curr_accum <= 0;
        else if (include_sample)
            curr_accum <= curr_mult[15:2] + curr;
    end

    assign curr_mult = curr_accum * 4'd3; // Multiplies by 3 (weight-1)
    assign avg_curr = curr_accum[13:2];

    

// Instantiate desiredDrive
desiredDrive desiredDrv_inst(
    .avg_torque(avg_torque),
    .cadence(cadence),
    .not_pedaling(not_pedaling),
    .incline(incline),  // Extend to 13 bits as required
    .scale(scale),
    .target_curr(target_curr),
    .clk(clk)
);



    // Calculate error for PID
    logic [12:0] error_calc;
    assign error_calc = {1'b0, target_curr} - {1'b0, avg_curr};

    // Zero out error when batt low or not pedaling
    assign error = ((batt < LOW_BATT_THRES) || not_pedaling) ? 13'b0 : error_calc;

    // Telemetry module
// Telemetry module
telemetry telemetry_inst(
    .clk(clk),
    .rst_n(rst_n),
    .batt_v(batt),
    .curr(avg_curr),
    .torque(avg_torque),
    .TX(TX)
);

endmodule