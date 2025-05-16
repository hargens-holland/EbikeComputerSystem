module sensorCondition_tb;
  logic clk, rst_n;
  logic [11:0] torque = 12'h400;
  logic [11:0] curr = 12'h200;
  logic cadence_raw = 0;
  logic [11:0] incline = 0;
  logic [2:0] scale = 3'b011;
  logic [11:0] batt = 12'hFFF;
  wire [12:0] error;
  wire not_pedaling;
  wire TX;

  sensorCondition #(.FAST_SIM(1)) iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .torque(torque),
    .cadence_raw(cadence_raw),
    .curr(curr),
    .incline(incline),
    .scale(scale),
    .batt(batt),
    .error(error),
    .not_pedaling(not_pedaling),
    .TX(TX)
  );

  // Dump waveform
  initial begin
    $dumpfile("sensorCondition.vcd");
    $dumpvars(0, sensorCondition_tb);
  end

initial begin
  curr   = 12'h3FF;
  torque = 12'h2FF;
end

  // 50MHz clock
  initial clk = 0;
  always #10 clk = ~clk;

  // Basic stimulus
  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
  end

  // Cadence pulses (slow, every ~4000 cycles)
  initial begin
    forever begin
      cadence_raw = 1;
      repeat(2000) @(posedge clk);
      cadence_raw = 0;
      repeat(2000) @(posedge clk);
    end
  end

always @(posedge clk) begin
  if (iDUT.cadence_rise) begin
    $display("Time=%0t: torque = %h, torque_accum = %h, torque_mult = %h, avg_torque = %h", 
             $time, iDUT.torque, iDUT.torque_accum, iDUT.torque_mult, iDUT.avg_torque);
  end
end

  // Simulation timeout
  initial begin
    #10000000; // 500,000 cycles
    $finish;
  end
endmodule
