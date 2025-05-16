module cadence_meas(
    input cadence_filt,
    input clk,
    input rst_n,
    
    output logic not_pedaling,    
    output logic [7:0] cadence_per  
);

parameter FAST_SIM = 0; 
 
localparam THIRD_SEC_REAL = 24'hE4E1C0;
localparam THIRD_SEC_FAST = 24'h007271;
localparam THIRD_SEC_UPPER = 8'hE4;

localparam THIRD_SEC = (FAST_SIM) ? 24'h007271 : 24'hE4E1C0;
 
logic cadence_rise;
logic rise_detect_ff1;

//rise detection
always_ff @(posedge clk) begin
    rise_detect_ff1 <= cadence_filt;
end

assign cadence_rise = cadence_filt && ~rise_detect_ff1;
  
//first flipflop after rise detect, this includes all muxes
logic [23:0] ff2;

always_ff @(posedge clk, negedge rst_n) begin  
    if (~rst_n) 
        ff2 <= 0;
    else begin
        if (cadence_rise)
            ff2 <= 24'h000000;
        else begin
            if (ff2 == THIRD_SEC)
                ff2 <= ff2;
            else 
                ff2 <= ff2 + 1;
        end
    end
end
 
// second ff after the rising edge detector, this includes all muxes

logic capture_per;
 
assign capture_per = cadence_rise || (ff2 == THIRD_SEC);

always_ff @(posedge clk, negedge rst_n) begin  // Added reset
    if (~rst_n)
        cadence_per <= THIRD_SEC_UPPER;
    else if (capture_per) begin
        if (FAST_SIM)
            cadence_per <= ff2[14:7];
        else 
            cadence_per <= ff2[23:16];
    end
end

//for not_pedaling output
always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n)
        not_pedaling <= 1'b1;  // Default to not pedaling on reset
    else
        not_pedaling <= (cadence_per == THIRD_SEC_UPPER);
end
   
endmodule