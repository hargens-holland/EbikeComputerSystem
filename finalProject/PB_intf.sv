module PB_intf(
    input clk, rst_n,
    input reg tgglMd,
    output logic [2:0] scale,
    output logic [1:0] setting
);


logic tgglMd_1, tgglMd_2, tgglMd_3;
logic rise_edge;

// flops for metastability and rise edge detection
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tgglMd_1 <= 0;
        tgglMd_2 <= 0;
        tgglMd_3 <= 0;
    end else begin
        tgglMd_1 <= tgglMd;
        tgglMd_2 <= tgglMd_1;
        tgglMd_3 <= tgglMd_2;
    end
end

// rising edge detection
assign rise_edge = tgglMd_2 & ~tgglMd_3;

// setting counter
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        setting <= 2'b10; // resets to medium setting
    end else if (rise_edge) begin
        setting <= setting + 1;
    end
end

// interprets setting to scale
assign scale = (setting == 0) ? 3'b000 :
                (setting == 1) ? 3'b011 :
                (setting == 2) ? 3'b101 :
                3'b111;


endmodule
