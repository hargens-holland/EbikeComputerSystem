module incline_sat(
	input logic [12:0] in,
	output logic [9:0] out
);

	
	assign out = (in[12] && ~(&in[11:9])) ? 10'b1000000000 : // Checks negative saturation and sets lowest neg value
		     (~in[12] && (|in[11:9])) ? 10'b0111111111 : // Check positive saturation and sets highest pos value
		     in[9:0]; // Otherwise just copies over the lower bits 
	
endmodule



		
		
