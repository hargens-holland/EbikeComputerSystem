module inert_intf(
    input  logic clk, rst_n, INT, MISO,
    output logic SS_n, SCLK, MOSI, vld,
    output logic [12:0] incline
);

// SPI interface
logic snd, done;
logic [15:0] cmd, resp;
SPI_mnrch ispy(
    .clk(clk), .rst_n(rst_n),
    .cmd(cmd), .snd(snd),
    .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI),
    .MISO(MISO), .resp(resp), .done(done)
);

// Integrator
logic signed [15:0] roll_rt, yaw_rt, AY, AZ;
logic [7:0] LED;
inertial_integrator iintegrator(
    .clk(clk), .rst_n(rst_n), .vld(vld),
    .roll_rt(roll_rt), .yaw_rt(yaw_rt),
    .AY(AY), .AZ(AZ), .incline(incline), .LED(LED)
);

// FSM states
typedef enum logic [4:0] {
    INIT1, INIT2, INIT3, INIT4,
    INT_WAIT,
    ROLLL, ROLLL_WAIT, ROLLH, ROLLH_WAIT,
    YAWL, YAWL_WAIT, YAWH, YAWH_WAIT,
    AYL, AYL_WAIT, AYH, AYH_WAIT,
    AZL, AZL_WAIT, AZH, AZH_WAIT,
    VLD
} state_t;

state_t state, nxt_state;

// double-flop INT
logic INT_ff1, INT_ff2;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        INT_ff1 <= 0; INT_ff2 <= 0;
    end else begin
        INT_ff1 <= INT;
        INT_ff2 <= INT_ff1;
    end
end

// 16-bit timer for INIT delay
logic [15:0] timer;
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) timer <= 0;
    else       timer <= timer + 1;
end

// byte storage
logic [7:0] C_R_H, C_R_L, C_Y_H, C_Y_L;
logic [7:0] C_AY_H, C_AY_L, C_AZ_H, C_AZ_L;

assign roll_rt = {C_R_H, C_R_L};
assign yaw_rt  = {C_Y_H, C_Y_L};  // ✅ fixed
assign AY      = {C_AY_H, C_AY_L};
assign AZ      = {C_AZ_H, C_AZ_L};

// Combinational control logic
always_comb begin
    snd = 0;
    cmd = 16'h0000;
    vld = 0;
    nxt_state = state;

    case (state)
        INIT1:     if (&timer)        begin snd = 1; cmd = 16'h0D02;        nxt_state = INIT2; end
        INIT2:     if (done)          begin snd = 1; cmd = 16'h1053;        nxt_state = INIT3; end
        INIT3:     if (done)          begin snd = 1; cmd = 16'h1150;        nxt_state = INIT4; end
        INIT4:     if (done)          begin snd = 1; cmd = 16'h1460;        nxt_state = INT_WAIT; end
        INT_WAIT:  if (INT_ff2)       begin snd = 1; cmd = 16'hA400;        nxt_state = ROLLL_WAIT; end
        ROLLL_WAIT:if (done)          begin snd = 1; cmd = 16'hA500;        nxt_state = ROLLH_WAIT; end
        ROLLH_WAIT:if (done)          begin snd = 1; cmd = 16'hA600;        nxt_state = YAWL_WAIT; end
        YAWL_WAIT: if (done)          begin snd = 1; cmd = 16'hA700;        nxt_state = YAWH_WAIT; end
        YAWH_WAIT: if (done)          begin snd = 1; cmd = 16'hAA00;        nxt_state = AYL_WAIT; end
        AYL_WAIT:  if (done)          begin snd = 1; cmd = 16'hAB00;        nxt_state = AYH_WAIT; end
        AYH_WAIT:  if (done)          begin snd = 1; cmd = 16'hAC00;        nxt_state = AZL_WAIT; end
        AZL_WAIT:  if (done)          begin snd = 1; cmd = 16'hAD00;        nxt_state = AZH_WAIT; end
        AZH_WAIT:  if (done)          nxt_state = VLD;
        VLD:                         begin vld = 1;                          nxt_state = INT_WAIT; end
        default:                     nxt_state = INIT1;
    endcase
end

// Register updates
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset stateful outputs
        C_R_L <= 8'h00;
        C_R_H <= 8'h00;
        C_Y_L <= 8'h00;
        C_Y_H <= 8'h00;
        C_AY_L <= 8'h00;
        C_AY_H <= 8'h00;
        C_AZ_L <= 8'h00;
        C_AZ_H <= 8'h00;
        state <= INIT1;
    end else begin
        // State register
        state <= nxt_state;

        // Capture sensor data from resp on DONE
        case (state)
            ROLLL_WAIT: if (done) C_R_L <= resp[15:8];
            ROLLH_WAIT: if (done) C_R_H <= resp[7:0];
            YAWL_WAIT:  if (done) C_Y_L <= resp[15:8];
            YAWH_WAIT:  if (done) C_Y_H <= resp[7:0];
            AYL_WAIT:   if (done) C_AY_L <= resp[15:8];
            AYH_WAIT:   if (done) C_AY_H <= resp[7:0];
            AZL_WAIT:   if (done) C_AZ_L <= resp[15:8];
            AZH_WAIT:   if (done) C_AZ_H <= resp[7:0];
        endcase
    end
end

endmodule
