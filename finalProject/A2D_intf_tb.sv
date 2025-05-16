module A2D_intf_tb();

    logic rst_n, clk, SS_n, SCLK, MOSI, MISO;
    logic [11:0] batt, curr, torque, brake;

    A2D_intf iDUT(.clk(clk), .rst_n(rst_n), .MISO(MISO), .batt(batt), .curr(curr), .torque(torque), .brake(brake), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI));
    ADC128S iADC(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .MISO(MISO), .MOSI(MOSI), .SCLK(SCLK));


    initial begin
        clk = 0;
        rst_n = 0;
        @(posedge clk);
        @(negedge clk);
        @(negedge clk) rst_n = 1;

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(batt !== 12'hC00) begin
            $display("Test failed for batt, expected 0xC00, got %h", batt);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(curr !== 12'hBF1) begin
            $display("Test failed for curr, expected 0xBF1, got %h", curr);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(brake !== 12'hBE3) begin
            $display("Test failed for brake, expected 0xBE3, got %h", curr);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(torque !== 12'hBD4) begin
            $display("Test failed for torque, expected 0xBD4, got %h", curr);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(batt !== 12'hBC0) begin
            $display("Test failed for batt, expected 0xBC0, got %h", batt);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(curr !== 12'hBB1) begin
            $display("Test failed for curr, expected 0xBB1, got %h", curr);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(brake !== 12'hBA3) begin
            $display("Test failed for brake, expected 0xBA3, got %h", curr);
            $stop();
        end

        @(posedge SS_n);
        @(posedge SS_n);
        @(posedge clk);
        @(posedge clk);

        if(torque !== 12'hB94) begin
            $display("Test failed for torque, expected 0xB94, got %h", curr);
            $stop();
        end

        $display("All tests passed!");
        $stop();

    end 

    always #5 clk = ~clk;


endmodule