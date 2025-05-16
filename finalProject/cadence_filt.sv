module cadence_filt(clk, rst_n, cadence, cadence_filt, cadence_rise);
	input logic  clk;
	input logic rst_n;
	input logic cadence;
	output logic cadence_filt;
	output logic cadence_rise;
	
	logic [15:0] stbl_cnt;
	logic chngd_n;
	
	logic D1, D2, D3, M1, A1;

	parameter FAST_SIM = 1; 
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			D1 <= 1'b0;
			D2 <= 1'b0;
			D3 <= 1'b0;
			end
			
		else begin
			D1 <= cadence;
			D2 <= D1;
			D3 <= D2;
		end
	end

	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			stbl_cnt <= 0;
		else if (chngd_n) 
			stbl_cnt <= stbl_cnt + 1;
	end


	generate if (FAST_SIM) begin
		always_ff @(posedge clk, negedge rst_n) begin
			if (!rst_n)
				cadence_filt <= 1'b0;
			else if (&stbl_cnt[8:0])
				cadence_filt <= D3;
		end
	end else begin
		always_ff @(posedge clk, negedge rst_n) begin
			if (!rst_n)
				cadence_filt <= 1'b0;
			else if (&stbl_cnt)
				cadence_filt <= D3;
		end
	end
	endgenerate
				
	
	always_comb begin	
		cadence_rise = D2 & ~D3;
		chngd_n = ~(D2 ^ D3);
		
	end
endmodule
			
		
		
	
	
