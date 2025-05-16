
module ring_osc_tb();

logic en; // enable signal 
logic out; // Output from the DUT

// Instantiate DUT //
ring_osc iDUT(.en(en), .out(out));

// Apply stimulus in an initial block
initial begin
	en = 0; 
	out = 0;
	#15;
	en = 1;
	#50;
	en = 0;
	#20;
	$stop();
end


endmodule  
