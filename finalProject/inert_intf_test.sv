module inert_intf_test(input logic clk, RST_n, INT, MISO,
					   output logic SS_n, SCLK, MOSI,
					   output logic [7:0] LED);


//hook up reset
logic rst_n;
reset_synch ireset(.RST_n(RST_n), .clk(clk), .rst_n(rst_n));

//create the inert
logic [12:0] incline;
inert_intf iinert(.clk(clk), .rst_n(rst_n), .INT(INT), .MISO(MISO), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .vld(vld), .incline(incline));


//set up LED display
always_ff @(posedge clk) begin
	if(vld) LED <= incline[8:1];
end

endmodule