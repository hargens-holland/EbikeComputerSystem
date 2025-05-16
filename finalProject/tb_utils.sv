package tb_utils;

    // Checks if the error is within the threshold
    function checkError(input int error, input int threshold);
        if(error > threshold || error < -threshold) 
            checkError = 1; // error detected
        else
            checkError = 0; // no error

    endfunction

    // Pedals for many clock cycles until output should be stable
    task pedal(input cadence, input clk);
        repeat(2048) begin
            cadence = 0;
            repeat(2048) @(posedge clk);
            cadence = 1;
            repeat(2048) @(posedge clk);
        end
    endtask

endpackage