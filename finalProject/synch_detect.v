module synch_detect(
	input asynch_sig_in,
	input clk,
	output rise_edge
);

	wire sync1, sync2, prev;
	
	// First stage of synchronization
    	dff dff1 (.D(asynch_sig_in), .clk(clk), .Q(sync1));

    	// Second stage of synchronization
    	dff dff2 (.D(sync1), .clk(clk), .Q(sync2));

	// Stage to store prev result
	dff dff3 (.D(sync2), .clk(clk), .Q(prev));

    	// sig_out is high for 1 cycle when sync2 transitions from 0 -> 1
    	assign rise_edge = sync2 & ~prev;
	
	

endmodule
