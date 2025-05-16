module PID_tb();
//test bench connecting pid and the plant pid
//the plant will do the work we just need them connected run the clock until test_over is received
logic clk, rst_n, not_pedaling;
logic [12:0] error;
logic [11:0] drv_mag;
logic test_over;

PID #(1) ipid(clk, rst_n, not_pedaling, error, drv_mag);

plant_PID iplant(clk,rst_n,drv_mag,error,not_pedaling,test_over);


initial begin
	clk = 0;
	rst_n = 0;
	@(negedge clk);
	rst_n = 1;
	
	@(posedge test_over);
	$stop();
end

always 
#5 clk = ~clk;

endmodule