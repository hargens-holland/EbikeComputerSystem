module A2D_intf(
    input clk, rst_n,
    input MISO,
    output reg [11:0] batt,
    output reg [11:0] curr,
    output reg [11:0] brake,
    output reg [11:0] torque,
    output SS_n,
    output SCLK,
    output MOSI
);

    logic [1:0] channel_cnt;
    logic cnv_cmplt;
    logic [15:0] cmd;
    logic [2:0] chnnl;
    logic [15:0] resp;
    logic [13:0] dead_cnt;
    logic done, snd;
    logic en;

    typedef enum reg [2:0] {IDLE, CMD, WAIT, DATA} state_t;
    state_t state, nxt_state;

    SPI_mnrch SPI(.clk(clk), .rst_n(rst_n), .MISO(MISO), .snd(snd), .cmd(cmd), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

    // Increments a 2 bit counter to round robin the channels read
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            channel_cnt <= '0;
        end else if(cnv_cmplt) begin
            channel_cnt <= channel_cnt + 1;
        end
    end

    // decodes count into channel number
    assign chnnl = (channel_cnt == 0) ? 3'b000 : (channel_cnt == 1) ? 3'b001 : (channel_cnt == 2) ? 3'b011 : 3'b100;

    // builds the command to send to SPI
    assign cmd = {2'b00, chnnl, 11'h0};

    // enables batt flop for first command
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            batt <= '0;
        else if((channel_cnt == 0 ) && en)
            batt <= resp;
    end

    // enables curr flop for second command
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            curr <= '0;
        else if((channel_cnt == 1) && en)
            curr <= resp;
    end

    // enables brake flop for third command
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            brake <= '0;
        else if((channel_cnt == 2) && en)
            brake <= resp;
    end

    // enables torque flop for fourth command
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            torque <= '0;
        else if((channel_cnt == 3) && en)
            torque <= resp;
    end

    // 14 bit counter for SPI timing
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n)
            dead_cnt <= '0;
        else
            dead_cnt <= dead_cnt + 1; 
    end

    // State machine, sends command when 14-bit timer full, waits 1 clock after each transmission
    always_comb begin
        nxt_state = state;
        cnv_cmplt = 0;
        snd = 0;
        en = 0;

        case(state)
            IDLE: begin
                if (&dead_cnt) begin
                    nxt_state = CMD;
                    snd = 1;
                end
            end

            // sends Serial command to A2D
            CMD: begin
                if(done) begin
                    nxt_state = WAIT;
                end 
            end

            // waits for 1 clock cycle
            WAIT: begin
                nxt_state = DATA;
                snd = 1;
            end

            // recieves data
            DATA: begin
                if (done) begin
                    nxt_state = IDLE;
                    cnv_cmplt = 1;
                    en = 1;
                end
            end

            default:
                nxt_state = IDLE;

            
        endcase
    end

    // update state
    always_ff @(posedge clk, negedge rst_n) begin
        if (~rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

endmodule