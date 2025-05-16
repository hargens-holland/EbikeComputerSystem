 module eBike(clk,RST_n,A2D_SS_n,A2D_MOSI,A2D_SCLK,
             A2D_MISO,hallGrn,hallYlw,hallBlu,highGrn,
			 lowGrn,highYlw,lowYlw,highBlu,lowBlu,
			 inertSS_n,inertSCLK,inertMOSI,inertMISO,
			 inertINT,cadence,TX,tgglMd,LED);
			 
  parameter FAST_SIM = 1;		// accelerate simulation by default

  input clk;				// 50MHz clk
  input RST_n;				// active low RST_n from push button
  output A2D_SS_n;			// Slave select to A2D on DE0
  output A2D_SCLK;			// SPI clock to A2D on DE0
  output A2D_MOSI;			// serial output to A2D (what channel to read)
  input A2D_MISO;			// serial input from A2D
  input hallGrn;			// hall position input for "Green" phase
  input hallYlw;			// hall position input for "Yellow" phase
  input hallBlu;			// hall position input for "Blue" phase
  output highGrn;			// high side gate drive for "Green" phase
  output lowGrn;			// low side gate drive for "Green" phase
  output highYlw;			// high side gate drive for "Yellow" phase
  output lowYlw;			// low side gate drive for "Yellow" phas
  output highBlu;			// high side gate drive for "Blue" phase
  output lowBlu;			// low side gate drive for "Blue" phase
  output inertSS_n;			// Slave select to inertial (tilt) sensor
  output inertSCLK;			// SCLK signal to inertial (tilt) sensor
  output inertMOSI;			// Serial out to inertial (tilt) sensor  
  input inertMISO;			// Serial in from inertial (tilt) sensor
  input inertINT;			// Alerts when inertial sensor has new reading
  input cadence;			// pulse input from pedal cadence sensor
  input tgglMd;				// used to select setting[1:0] (from PB switch)
  output TX;				// serial output of measured batt,curr,torque
  output [1:0] LED;			// Lower 2-bits of LED (setting) 11 => easy, 10 => medium, 01 => hard, 00 => off
  
  ////////////////////////////////////////////
  // Declare internal interconnect signals //
  //////////////////////////////////////////
  wire rst_n;									// global reset from reset_synch
  wire [11:0] torque, batt, curr, brake;		// Raw A2D results
  wire signed [12:0] error;
  wire cadence;
  wire not_pedaling;
  wire [10:0] duty;
  wire [1:0] selGrn, selYlw, selBlu;
  wire signed [12:0] incline;
  wire [11:0] drv_mag;
  wire brake_n;
  wire PWM_synch;
  wire [2:0] scale;
  
  ////////////////////////////////////////////////////////
  // Brake lever input is converted as analog, but     //
  // treated as digital (if below mid rail it is low) //
  /////////////////////////////////////////////////////
  assign brake_n = (brake<12'h800) ? 1'b0 : 1'b1;
	
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////
  reset_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
  
  ///////////////////////////////////////////////////////
  // Instantiate A2D_intf to read torque & batt level //
  /////////////////////////////////////////////////////
  A2D_intf iA2D(.clk(clk),.rst_n(rst_n),.MISO(A2D_MISO), .batt(batt), 
                .curr(curr), .torque(torque), .brake(brake), .SS_n(A2D_SS_n), 
                .SCLK(A2D_SCLK), .MOSI(A2D_MOSI)
                );

				 
  ////////////////////////////////////////////////////////////
  // Instantiate SensorCondition block to filter & average //
  // readings and provide cadence_vec, and zero_cadence   //
  /////////////////////////////////////////////////////////
  sensorCondition #(FAST_SIM) iSensorCondition(.clk(clk), .rst_n(rst_n), .torque(torque), 
                              .cadence_raw(cadence), .curr(curr), .incline(incline), 
                              .scale(scale), .batt(batt), .error(error), 
                              .not_pedaling(not_pedaling), .TX(TX)
                              );
					   
  ///////////////////////////////////////////////////
  // Instantiate PID to determine drive magnitude //
  /////////////////////////////////////////////////		   
  PID #(FAST_SIM) iPID(.clk(clk), .rst_n(rst_n),
           .error(error), .drv_mag(drv_mag), .not_pedaling(not_pedaling)
           );
  
  ////////////////////////////////////////////////
  // Instantiate brushless DC motor controller //
  //////////////////////////////////////////////
  brushless iBrushless(
    .clk(clk), .rst_n(rst_n), .drv_mag(drv_mag), 
    .hallGrn(hallGrn), .hallYlw(hallYlw), .hallBlu(hallBlu), 
    .brake_n(brake_n), .PWM_synch(PWM_synch), 
    .duty(duty), .selGrn(selGrn), .selYlw(selYlw), .selBlu(selBlu)
    );

  ///////////////////////////////
  // Instantiate motor driver //
  /////////////////////////////
  mtr_drv iMtrDrv(
    .clk(clk), .rst_n(rst_n), .duty(duty), .PWM_synch(PWM_synch), .highGrn(highGrn), 
    .lowGrn(lowGrn), .highYlw(highYlw), .lowYlw(lowYlw), .highBlu(highBlu), 
    .lowBlu(lowBlu), .selGrn(selGrn), .selYlw(selYlw), .selBlu(selBlu)
    );

  /////////////////////////////////////////////////////////////
  // Instantiate inertial sensor to measure incline (pitch) //
  ///////////////////////////////////////////////////////////
  inert_intf iInert(.clk(clk), .rst_n(rst_n), .INT(inertINT), 
                .MISO(inertMISO), .SS_n(inertSS_n), .SCLK(inertSCLK), 
                .MOSI(inertMOSI), .incline(incline), .vld(vld)
                );
					
  /////////////////////////////////////////////////////////////////
  // Instantiate PB_intf block to establish setting/LED & scale //
  ///////////////////////////////////////////////////////////////
  PB_intf iPB(.clk(clk), .rst_n(rst_n), .tgglMd(tgglMd), .scale(scale), .setting(LED));  

endmodule
