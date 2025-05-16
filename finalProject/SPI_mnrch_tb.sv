module SPI_mnrch_tb();
  // TB signals
  logic clk, rst_n;
  logic [15:0] cmd;
  logic snd;
  logic SS_n, SCLK, MOSI, MISO;
  logic [15:0] resp;
  logic done;
  
  // For testbench checking
  integer test_case = 0;
  logic [15:0] expected_resp;
  
  // Instantiate the SPI master module
  SPI_mnrch iSPI_mnrch(
    .clk(clk),
    .rst_n(rst_n),
    .cmd(cmd),
    .snd(snd),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .resp(resp),
    .done(done)
  );
  
  // Instantiate the ADC128S as SPI slave
  ADC128S iADC128S(
    .clk(clk),
    .rst_n(rst_n),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MISO(MISO),
    .MOSI(MOSI)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 50MHz clock (20ns period)
  end
  
  // Test stimulus
  initial begin
    // Initialize
    rst_n = 0;
    snd = 0;
    cmd = 16'h0000;
    
    // Wait and release reset
    repeat(5) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);
    
    // Test case 1: First read requesting channel 1, should return channel 0 = 0xC00
    test_case = 1;
    expected_resp = 16'h0C00;  // First read always returns 0xC00 (channel 0)
    
    // Format command: {2'b00, channel[2:0], 11'h000}
    cmd = {2'b00, 3'b001, 11'h000};  // Requesting channel 1 for next time
    
    // Send command
    @(posedge clk);
    snd = 1;
    @(posedge clk);
    snd = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    check_response(1);
    
    // Add required delay between transactions
    @(posedge clk);
    
    // Test case 2: Second read requesting channel 1 again, returns channel 1 = 0xC01
    test_case = 2;
    expected_resp = 16'h0C01;  // Channel 1 from last request, not yet decremented
    
    // Same command for channel 1
    cmd = {2'b00, 3'b001, 11'h000};
    
    // Send command
    @(posedge clk);
    snd = 1;
    @(posedge clk);
    snd = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    check_response(2);
    
    // Add required delay between transactions
    @(posedge clk);
    
    // Test case 3: Third read requesting channel 4, returns channel 1 = 0xBF1
    test_case = 3;
    expected_resp = 16'h0BF1;  // 0xC00 decremented by 0x10 after two reads, still channel 1
    
    // Command for channel 4
    cmd = {2'b00, 3'b100, 11'h000};
    
    // Send command
    @(posedge clk);
    snd = 1;
    @(posedge clk);
    snd = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    check_response(3);
    
    // Add required delay between transactions
    @(posedge clk);
    
    // Test case 4: Fourth read requesting channel 4, returns channel 4 = 0xBF4
    test_case = 4;
    expected_resp = 16'h0BF4;  // Channel 4 response from last request
    
    // Same command for channel 4
    cmd = {2'b00, 3'b100, 11'h000};
    
    // Send command
    @(posedge clk);
    snd = 1;
    @(posedge clk);
    snd = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    check_response(4);
    
    // End the simulation
    repeat(10) @(posedge clk);
    $display("All tests passed successfully!");
    $stop();
  end
  
  // Task to check response
  task check_response(input integer tc_num);
    begin
      // Wait a clock cycle for stability
      @(posedge clk);
      
      // Check if response matches expected value
      if (resp[11:0] === expected_resp[11:0]) begin
        $display("Test Case %0d: PASSED - Received 0x%h, Expected 0x%h", 
                tc_num, resp[11:0], expected_resp[11:0]);
      end
      else begin
        $display("Test Case %0d: FAILED - Received 0x%h, Expected 0x%h", 
                tc_num, resp[11:0], expected_resp[11:0]);
        $display("ERROR: Test failed!");
        $stop();
      end
    end
  endtask
  
  // For simulation debugging
  initial begin
    $display("Starting SPI Master Testbench");
    $display("Test case sequence from assignment:");
    $display("1. Request channel 1, expect 0xC00 (first read returns channel 0)");
    $display("2. Request channel 1, expect 0xC01 (returns channel 1 from last request)");
    $display("3. Request channel 4, expect 0xBF1 (0xC00 - 0x10 = 0xBF0 + channel 1 = 0xBF1)");
    $display("4. Request channel 4, expect 0xBF4 (returns channel 4 from last request)");
  end
  
  // Monitor SPI transactions
  initial begin
    $monitor("%0t\tSS_n=%b SCLK=%b MOSI=%b MISO=%b resp=0x%h done=%b", 
            $time, SS_n, SCLK, MOSI, MISO, resp, done);
  end
  
endmodule