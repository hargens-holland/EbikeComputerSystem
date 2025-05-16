module PWM(
  input logic clk,  // 50 MHz system clock
  input logic rst_n,  // Async active low reset
  input logic [10:0] duty, // Unsigned 11-bit duty cycle
  output logic PWM_sig,  // PWM output
  output logic PWM_synch // Synchronization signal
);


  logic [10:0] cnt; // 11-bit counter
  
  // Counter logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      cnt <= 11'h000; // Set to 0 if reset is low
    else
      cnt <= cnt + 1'b1;  // Otherwise, Increment count every clock edge
  end

  // PWM output logic 
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      PWM_sig <= 1'b0;
    else 
      PWM_sig <= (cnt <= duty);
  end

  // Synchronization signal when counter is 0x001
  always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n)
      PWM_synch <= 1'b0;
    else 
      PWM_synch <= (cnt == 11'h001);
  end

endmodule