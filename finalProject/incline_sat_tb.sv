module incline_sat_tb;

	// Declare test signals
	logic [12:0] in;
	logic [9:0] out;
	logic [9:0] expected;
    	int errors = 0;
	// Instantiate the module
	incline_sat DUT (
		.in(in),
		.out(out)
	);
	
	// Test stimulus
    initial begin
        $display("Starting Incline Saturation Tests");
        $display("Time    in          out        expected   Pass/Fail");

        // Test Case 1: Normal positive number -> pass through
        in = 13'b0000001111111;
        expected = in[9:0];
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 2: Normal negative number -> pass through
        in = 13'b1111110000000;
        expected = in[9:0];
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 3: Large positive number -> saturate to max positive
        in = 13'b0111111111111;
        expected = 10'b0111111111;
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 4: Large negative number -> saturate to max negative
        in = 13'b1000000000000;
        expected = 10'b1000000000;
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 5: Just below positive saturation -> pass through
        in = 13'b0000111111111;
        expected = in[9:0];
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 6: Just above negative saturation -> pass through
        in = 13'b1111000000000;
        expected = in[9:0];
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 7: Just above positive saturation -> saturate to max positive
        in = 13'b0001111111111;
        expected = 10'b0111111111;
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        // Test Case 8: Just below negative saturation -> saturate to max negative
        in = 13'b1110000000000;
        expected = 10'b1000000000;
        #10;
        if (out !== expected) begin
            $display("%0t\t %b\t %b\t %b\t FAIL", $time, in, out, expected);
            errors++;
        end else
            $display("%0t\t %b\t %b\t %b\t PASS", $time, in, out, expected);

        $display("Incline Saturation Test Complete");
        if (errors == 0)
            $display("All tests PASSED!");
        else
            $display("FAILED: %0d tests failed", errors);

        $stop;
    end
endmodule
