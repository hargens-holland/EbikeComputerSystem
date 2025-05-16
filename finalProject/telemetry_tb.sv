module telemetry_tb();
  
  // Testbench signals
  logic clk, rst_n;
  logic [11:0] batt_v, curr, torque;
  logic TX;
  
  // UART receiver signals
  logic [7:0] rx_data;
  logic RX;
  logic rx_rdy;
  logic clr_rdy;
  
  // Received byte storage
  logic [7:0] received_bytes[8];
  integer byte_count;

  // Test values
  localparam [11:0] TEST_BATT_V = 12'hA5B;    // Battery voltage
  localparam [11:0] TEST_CURR = 12'h3C9;      // Current
  localparam [11:0] TEST_TORQUE = 12'h842;    // Torque
  
  // Expected byte sequence
  logic [7:0] expected_bytes[8];

  // Instantiate telemetry module
  telemetry iDUT(
    .clk(clk),
    .rst_n(rst_n),
    .batt_v(batt_v),
    .curr(curr),
    .torque(torque),
    .TX(TX)
  );

  // Instantiate UART receiver
  UART_rcv iUART_rcv(
    .clk(clk),
    .rst_n(rst_n),
    .RX(RX),
    .rx_data(rx_data),
    .rdy(rx_rdy),
    .clr_rdy(clr_rdy)
  );

  // Connect TX to RX (loopback)
  assign RX = TX;

  // Generate clock
  initial begin
    clk = 0;
    forever #10 clk = ~clk; // 50MHz clock (20ns period)
  end
  
  // Define expected byte sequence based on test values
  initial begin
    expected_bytes[0] = 8'hAA;                      // Delimiter 1
    expected_bytes[1] = 8'h55;                      // Delimiter 2
    expected_bytes[2] = {4'h0, TEST_BATT_V[11:8]};  // Battery High
    expected_bytes[3] = TEST_BATT_V[7:0];           // Battery Low
    expected_bytes[4] = {4'h0, TEST_CURR[11:8]};    // Current High
    expected_bytes[5] = TEST_CURR[7:0];             // Current Low
    expected_bytes[6] = {4'h0, TEST_TORQUE[11:8]};  // Torque High
    expected_bytes[7] = TEST_TORQUE[7:0];           // Torque Low
  end

  // **Capture received bytes correctly**
  // Capture received bytes correctly
always @(posedge rx_rdy) begin
    if (byte_count < 8) begin
        received_bytes[byte_count] = rx_data;
        $display("[%0t]  Received Byte %0d: 0x%h (Expected: 0x%h)", 
                 $time, byte_count, rx_data, expected_bytes[byte_count]);
        byte_count++;
    end else begin
        $display("[%0t]  Extra Byte Received: 0x%h (Possible Double Transmission)", 
                 $time, rx_data);
    end
    clr_rdy <= 1'b1;  // Clear `rx_rdy` immediately after receiving a byte
    #1 clr_rdy <= 1'b0;  // De-assert after one cycle to avoid repeated triggers
end


  // **Check received bytes against expected values**
  task check_sequence();
    integer error;
    
    for (int i = 2; i < 8; i++) begin
      if (received_bytes[i] !== expected_bytes[i]) begin
        $display("ERROR at byte %0d: Expected 0x%h, Got 0x%h", 
                i, expected_bytes[i], received_bytes[i]);
        error = 1;
      end
    end
    
    if (error) begin
      $display("TEST FAILED: Incorrect byte sequence received.");
    end else begin
      $display("TEST PASSED: All bytes match expected values!");
    end
  endtask

  // **Main test sequence**
  initial begin
    // Initialize signals
    rst_n = 0;
    batt_v = TEST_BATT_V;
    curr = TEST_CURR;
    torque = TEST_TORQUE;
    byte_count = 0;
    
    // **Release reset**
    repeat(5) @(posedge clk);
    rst_n = 1;
    
    $display("Starting telemetry module test...");
    $display("Test values: Battery = 0x%h, Current = 0x%h, Torque = 0x%h",
            TEST_BATT_V, TEST_CURR, TEST_TORQUE);
    
    // **Force timer to near completion for fast simulation**
    @(posedge clk);
    force iDUT.timer_cnt = 20'hFFFF0;
    @(posedge clk);
    release iDUT.timer_cnt;

    wait(byte_count == 8);
    
    // **Ensure stability before checking**
    repeat(10) @(posedge clk);

    check_sequence;
    byte_count = 0;
    $display(" Waiting for second transmission...");

    // **Force timer to near completion again**
    @(posedge clk);
    force iDUT.timer_cnt = 20'hFFFF0;
    @(posedge clk);
    release iDUT.timer_cnt;
    
    //  **Wait for all 8 bytes in the second transmission**
    wait(byte_count == 8);

    // **Ensure stability before checking again**
    repeat(10) @(posedge clk);

    // **Check again to verify periodic transmission**
    check_sequence();

    // **End simulation**
    $display("Simulation completed successfully!");
    $stop();
  end
  
  // **State transition monitoring for debugging**
  initial begin
    $display("\nDebugging: State Transitions & Transmission Details");
    $display("Time      State             TX_Data   TX   TX_Done  Byte_Count  Trmt");
    $monitor("%0t   %s  0x%h     %b    %b       %0d     %b", 
            $time, 
            iDUT.state.name(),
            iDUT.tx_data,
            TX,
            iDUT.tx_done,
            byte_count,
            iDUT.trmt);
  end

endmodule
