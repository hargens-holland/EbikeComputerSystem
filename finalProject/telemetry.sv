module telemetry(
  input clk, rst_n,
  input [11:0] batt_v, curr, torque,
  output TX
);
  // UART transmitter signals
  logic [7:0] tx_data;
  logic trmt;
  logic tx_done;

  // Instantiate UART transmitter
  UART_tx iUART_tx(
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .trmt(trmt),
    .TX(TX),
    .tx_done(tx_done)
  );

  // Timer for periodic transmission (47.68 Hz ≈ 2^20 cycles at 50MHz)
  logic [19:0] timer_cnt;
  logic timer_full;
  
  // State machine states
  typedef enum logic [4:0] {
    IDLE,
    SEND_DELIM1, WAIT_DELIM1,
    SEND_DELIM2, WAIT_DELIM2,
    SEND_BATT_HIGH, WAIT_BATT_HIGH,
    SEND_BATT_LOW, WAIT_BATT_LOW,
    SEND_CURR_HIGH, WAIT_CURR_HIGH,
    SEND_CURR_LOW, WAIT_CURR_LOW,
    SEND_TORQUE_HIGH, WAIT_TORQUE_HIGH,
    SEND_TORQUE_LOW, WAIT_TORQUE_LOW
  } state_t;
  
  state_t state;
  state_t next_state;

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      timer_cnt <= 20'h00000;
    else if (state == IDLE) begin
      if (timer_full)
        timer_cnt <= 20'h00000;
      else
        timer_cnt <= timer_cnt + 1'b1;
    end
  end
  assign timer_full = (timer_cnt == 20'hFFFFF); // 2^20 - 1
    

  
  // State register
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  // One-cycle `trmt` signal
  logic trmt_reg;
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      trmt_reg <= 1'b0;
    else
      trmt_reg <= (state != next_state); // Assert `trmt` for one cycle when changing state
  end
  assign trmt = trmt_reg;

  // Next state logic
  always_comb begin
    // Default values
    next_state = state;
    tx_data = 8'h00;
    
    case (state)
      IDLE: begin
        if (timer_full)
          next_state = SEND_DELIM1;
      end
      
      // Delimiters
      SEND_DELIM1: begin tx_data = 8'hAA; next_state = WAIT_DELIM1; end
      WAIT_DELIM1: if (tx_done) next_state = SEND_DELIM2;

      SEND_DELIM2: begin tx_data = 8'h55; next_state = WAIT_DELIM2; end
      WAIT_DELIM2: if (tx_done) next_state = SEND_BATT_HIGH;

      // Battery voltage
      SEND_BATT_HIGH: begin tx_data = {4'h0, batt_v[11:8]}; next_state = WAIT_BATT_HIGH; end
      WAIT_BATT_HIGH: if (tx_done) next_state = SEND_BATT_LOW;

      SEND_BATT_LOW: begin tx_data = batt_v[7:0]; next_state = WAIT_BATT_LOW; end
      WAIT_BATT_LOW: if (tx_done) next_state = SEND_CURR_HIGH;

      // Current
      SEND_CURR_HIGH: begin tx_data = {4'h0, curr[11:8]}; next_state = WAIT_CURR_HIGH; end
      WAIT_CURR_HIGH: if (tx_done) next_state = SEND_CURR_LOW;

      SEND_CURR_LOW: begin tx_data = curr[7:0]; next_state = WAIT_CURR_LOW; end
      WAIT_CURR_LOW: if (tx_done) next_state = SEND_TORQUE_HIGH;

      // Torque
      SEND_TORQUE_HIGH: begin tx_data = {4'h0, torque[11:8]}; next_state = WAIT_TORQUE_HIGH; end
      WAIT_TORQUE_HIGH: if (tx_done) next_state = SEND_TORQUE_LOW;

      SEND_TORQUE_LOW: begin tx_data = torque[7:0]; next_state = WAIT_TORQUE_LOW; end
      WAIT_TORQUE_LOW: if (tx_done) next_state = IDLE;

      default: next_state = IDLE;
    endcase
  end

endmodule
