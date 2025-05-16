module SPI_mnrch(
    input clk,
    input rst_n,
    input MISO,
    input snd,
    input [15:0] cmd,
    output reg SS_n,
    output SCLK,
    output MOSI,
    output reg done,
    output reg [15:0] resp
);

logic ld_SCLK;
logic [4:0] SCLK_div;
logic full;
logic shft;
logic init;
logic set_done;
logic MISO_smpl;
logic [4:0] bit_cntr;
logic done16;

logic [15:0] shft_reg;

// counter logic for SCLK
always_ff @(posedge clk) begin
    if(ld_SCLK) 
        SCLK_div <= 5'b10111;
    else
        SCLK_div <= SCLK_div + 1;
end

// decode outputs
assign full = &SCLK_div; // count is full
assign shft = SCLK_div == 5'b10001; // shifts 2 system clocks after sclk is high
assign SCLK = SCLK_div[4]; // sclk high for msb of 32-bit counter

// 16-bit shift counter
always_ff @(posedge clk) begin
    if(init) 
        bit_cntr <= 5'b00000;
    else if (shft)
        bit_cntr <= bit_cntr + 1;
end
// Sample MISO on SCLK rising edge
always_ff @(posedge clk) begin
    if (SCLK_div == 5'b10000) // adjust based on your SCLK phase
        MISO_smpl <= MISO;
end
assign done16 = bit_cntr[4]; // 16 clocks passed

// shift logic
always_ff @(posedge clk) begin
    if(init)
        shft_reg <= cmd;
    else if(shft)
        shft_reg <= {shft_reg[14:0], MISO_smpl};
end

assign MOSI = shft_reg[15];


// state machine to control SPI logic
typedef enum reg [1:0] {IDLE, SHFT, BACK_PORCH} state_t;
state_t state, next_state;

always_comb begin
    next_state = state;
    ld_SCLK = 0;
    init = 0;
    set_done = 0;

    case (state) 
        IDLE: begin
    if(snd) begin
        init = 1;
        ld_SCLK = 1;  
        next_state = SHFT;  
    end else begin
        ld_SCLK = 1;
        next_state = IDLE;
    end
end
        SHFT: // shifts bits into the shift register until full
            if(done16)
                next_state = BACK_PORCH;
            else 
                next_state = SHFT;
        BACK_PORCH:
            if(full) begin // waits 2 clock cycles for a back porch to finish SPI signal
                ld_SCLK = 1;
                set_done = 1;
                init = 0;
                next_state = IDLE;
            end else
                next_state = BACK_PORCH;
        default: begin
            next_state = IDLE;
            ld_SCLK = 0;
            init = 0;
            set_done = 0;
        end
    endcase
end

// state transition logic
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// Gives the output once the signal is captured
always_ff @(posedge clk) begin
    if (set_done)
        resp <= shft_reg;
end


// SS_n preset ff
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        SS_n <= 1;
    else if (init)
        SS_n <= 0;
    else if(set_done)
        SS_n <= 1;
end   

// done reset ff
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
        done <= 1'b0;
    else if(init || !set_done)
        done <= 1'b0;
    else if(set_done)
        done <= 1'b1;
end


endmodule