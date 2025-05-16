module brushless(
  input clk, rst_n, 
  input [11:0] drv_mag,
  input hallGrn, hallYlw, hallBlu,
  input brake_n,
  input PWM_synch,
  output[10:0] duty, 
  output logic [1:0] selGrn, selYlw, selBlu
);

	logic hallGrn_ff1, hallGrn_ff2;
        logic hallBlu_ff1, hallBlu_ff2;
        logic hallYlw_ff1, hallYlw_ff2;

	logic synchGrn, synchYlw, synchBlu;

	logic [2:0] rotation_state;

	// Synchronization logic 
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			hallGrn_ff1 <= 0;
			hallGrn_ff2 <= 0;
			hallBlu_ff1 <= 0;
			hallBlu_ff2 <= 0;
			hallYlw_ff1 <= 0;
			hallYlw_ff2 <= 0;
		end else begin
			hallGrn_ff1 <= hallGrn;
			hallGrn_ff2 <= hallGrn_ff1;
			synchGrn <= hallGrn_ff2;
			hallBlu_ff1 <= hallBlu;
			hallBlu_ff2 <= hallBlu_ff1;
			synchBlu <= hallBlu_ff2;
			hallYlw_ff1 <= hallYlw;
			hallYlw_ff2 <= hallYlw_ff1;
			synchYlw <= hallYlw_ff2;
	
			// Synchronize with PWM cycle
        		if (PWM_synch) begin
            			synchGrn <= hallGrn_ff2;
            			synchBlu <= hallBlu_ff2;
            			synchYlw <= hallYlw_ff2;
        		end
		end
	end 
	
	// Form rotation stae from synchronized sensors
	assign rotation_state = {synchGrn, synchYlw, synchBlu};
	
	// Set duty cycle based on operating mode
    	assign duty = brake_n ? (11'h400 + drv_mag[11:2]) : 11'h600;

	
// Determine coil drive states based on rotation_state and brake_n
always_comb begin
    if (!brake_n) begin
        // Regenerative braking mode - all coils in regen braking state
        selGrn = 2'b11;
        selYlw = 2'b11;
        selBlu = 2'b11;
    end else begin
        // Normal operation - determine states based on rotation_state
        case(rotation_state)
            3'b101: begin
                selGrn = 2'b10; // for_curr
                selYlw = 2'b01; // rev_curr
                selBlu = 2'b00; // High Z
            end
            3'b100: begin
                selGrn = 2'b10; 
                selYlw = 2'b00; 
                selBlu = 2'b01; 
            end
            3'b110: begin
                selGrn = 2'b00; 
                selYlw = 2'b10; 
                selBlu = 2'b01; 
            end
            3'b010: begin
                selGrn = 2'b01; 
                selYlw = 2'b10; 
                selBlu = 2'b00; 
            end
            3'b011: begin
                selGrn = 2'b01; 
                selYlw = 2'b00;
                selBlu = 2'b10; 
            end
            3'b001: begin
                selGrn = 2'b00;
                selYlw = 2'b01; 
                selBlu = 2'b10; 
            end
            default: begin
                selGrn = 2'b00;
                selYlw = 2'b00;
                selBlu = 2'b00;
            end

        endcase
    end
end


			
endmodule