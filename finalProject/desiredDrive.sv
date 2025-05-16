module desiredDrive(
	input logic [11:0] avg_torque, 
	input logic [4:0] cadence,
	input logic not_pedaling,
	input logic [12:0] incline,
	input logic [2:0] scale,
	output logic [11:0] target_curr,
	input clk
);

	logic [9:0] incline_sat;
	logic [10:0] incline_factor;
	logic [8:0] incline_lim;
	logic [5:0] cadence_factor;
	logic [12:0] torque_off;
	logic [29:0] assist_prod;
	localparam TORQUE_MIN = 12'h380;
	logic unsigned [11:0] torque_pos;

	// PIPELINE STAGES
	logic [23:0] assist_prod_1, assist_prod_1_ff;
	logic [11:0] assist_prod_2, assist_prod_2_ff;
	logic [29:0]  pp_low;
    logic [29:0]  pp_high;
    logic [29:0]  assist_prod_pipe;
    logic [11:0]  target_raw;

	
	// Get saturated incline
	incline_sat inc_sat(.in(incline), .out(incline_sat));
	
	// Calculate incline factor
	assign incline_factor = {{1{incline_sat[9]}}, incline_sat} + 11'd256;
	
	// Limit incline factor
	assign incline_lim = (incline_factor[10]) ? 9'b0 : 
                        (incline_factor > 9'd511) ? 9'd511 : 
                        incline_factor[8:0];

	 // Calculate cadence factor
    	assign cadence_factor = (cadence > 5'd1) ? cadence + 6'd32 : 6'd0;
	
	// Calculate torque with offset
    	assign torque_off = {1'b0, avg_torque} - {1'b0, TORQUE_MIN};
	
	// Ensure torque is positive
    	assign torque_pos = (torque_off[12]) ? 12'd0 : torque_off[11:0];
	
	// Calculate assist product
		assign assist_prod_1 = torque_pos * {3'd0, incline_lim};
		assign assist_prod_2 = cadence_factor * {3'b0, scale};

	// Stage 1 ﬂops for small mult inputs
    always_ff @(posedge clk) begin
        assist_prod_1_ff <= assist_prod_1;
        assist_prod_2_ff <= assist_prod_2;
    end

    // Stage 2: low-half multiply (24×6)
    always_ff @(posedge clk) begin
        pp_low <= assist_prod_1_ff * assist_prod_2_ff[5:0];
    end

    // Stage 3: high-half multiply + accumulate -> final product
    always_ff @(posedge clk) begin
        pp_high <= assist_prod_1_ff * assist_prod_2_ff[11:6];
        assist_prod_pipe <= pp_low + (pp_high << 6);
    end

    // Stage 4: saturate & slice -> target_curr
    always_ff @(posedge clk) begin
        target_raw  <= (|assist_prod_pipe[29:27]) ? 12'hFFF : assist_prod_pipe[26:15];
        target_curr <= target_raw;
    end
endmodule
   
