module brushless_mtr_drv(
  input clk, rst_n, 
  input [11:0] drv_mag,
  input hallGrn, hallYlw, hallBlu,
  input brake_n,  // Add this missing input
  output highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu
);
  // Interconnection signals
  logic [10:0] duty;
  logic PWM_synch;
  logic [1:0] selGrn, selYlw, selBlu;
  
  // Instantiate brushless controller
  brushless brushless_inst(
    .clk(clk),
    .rst_n(rst_n),
    .drv_mag(drv_mag),
    .hallGrn(hallGrn),
    .hallYlw(hallYlw),
    .hallBlu(hallBlu),
    .brake_n(brake_n),
    .PWM_synch(PWM_synch),
    .duty(duty),
    .selGrn(selGrn),
    .selYlw(selYlw),
    .selBlu(selBlu)
  );
  
  // Instantiate motor driver
  mtr_drv mtr_drv_inst(  // Fixed module name
    .clk(clk),
    .rst_n(rst_n),
    .duty(duty),
    .selGrn(selGrn),
    .selYlw(selYlw),
    .selBlu(selBlu),
    .PWM_synch(PWM_synch),
    .highGrn(highGrn),
    .lowGrn(lowGrn),
    .highYlw(highYlw),
    .lowYlw(lowYlw),
    .highBlu(highBlu),
    .lowBlu(lowBlu)
  );
endmodule