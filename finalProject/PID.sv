module PID(input logic clk, rst_n, not_pedaling,
		   input logic [12:0] error,
		   output logic [11:0] drv_mag);

/////////////////
//decimator to make a clk that runs once every 1/48 seconds
/////////////////
logic [19:0] decimator;
logic decimator_full;
parameter FAST_SIM = 0;

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) decimator <= 0;
	else decimator <= decimator + 1;
end

//assign decimator to full sooner if we want to speed up simulation
generate if (FAST_SIM)
	assign decimator_full = &decimator[14:0];
else
	assign decimator_full = &decimator;
endgenerate

/////////////////
//P_term is is just sign extended error to 14 bits;
/////////////////
logic [13:0] P_term;
assign P_term = {error[12],error};

/////////////////
//I_term is an accumulator of error over time
/////////////////
logic [11:0] I_term;
logic [17:0] integrator;
logic [17:0] error_extended;
logic [17:0] saturated_I;
logic [17:0] added_I;
logic [17:0] D_I;
logic pos_ov;

always_comb begin
	error_extended = {{5{error[12]}},error}; // signextended input
	pos_ov = !error_extended[17] && integrator[16]; //determines if positive overflow 
	added_I = error_extended + integrator;
	
	//saturate the I to a positive, non overflowed value
	if(pos_ov) saturated_I = 18'h1FFFF;
	else if (added_I[17]) saturated_I = 18'h00000;
	else saturated_I = added_I;
	
	//I_term is only updated every decimated and when pedaling
	if(not_pedaling) D_I = 18'h00000;
	else if (decimator_full) D_I = saturated_I;
	else D_I = integrator[17:0];	
end

//flipflop controling the final output of integrator
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) integrator <= 18'h00000;
	else integrator <= D_I;
end
assign I_term = integrator[16:5];

/////////////////
//D_term
/////////////////
logic [9:0] D_term;
logic [12:0] DFF1, DFF2, DFF3;
logic [12:0] D_diff;
logic [8:0] saturated_D;
logic too_pos, too_neg;
logic [12:0] error_flopped;

//triple flop signal to get a previous value to subtract
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		DFF1 <= 13'd0;
		DFF2 <= 13'd0;
		DFF3 <= 13'd0;
	end
	else if (decimator_full) begin
		DFF1 <= error;
		DFF2 <= DFF1;
		DFF3 <= DFF2;
	end
end

always_ff @(posedge clk)
	error_flopped <= error;

//signed saturation to 9-bits and multiplication
always_comb begin

	
	D_diff = error_flopped - DFF3;
	
	too_pos = ~D_diff[12] && |D_diff[11:8];
	too_neg = D_diff[12] && ~&D_diff[11:8];
	
	if(too_pos) saturated_D = 9'h0FF;
	else if(too_neg) saturated_D = 9'h100;
	else saturated_D = D_diff[8:0];
	
	D_term = {saturated_D, 1'b0};
end

logic [13:0] itermZext, dtermSext, PI_sum, PIDsum;
logic [11:0] PIDsat;

assign itermZext = {{2{1'b0}}, I_term};
assign dtermSext = {{4{D_term[9]}}, D_term};


// Stage 2: (P + I) + D
always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) PIDsum <= 0;
    else        PIDsum <= itermZext + P_term + dtermSext;

assign PIDsat  = PIDsum[12] ? 12'hFFF : PIDsum[11:0];
assign drv_mag = PIDsum[13] ? 12'h000 : PIDsat;

endmodule
