
module eBike_tb();
 
  // include or import tasks?

  localparam FAST_SIM = 1;		// accelerate simulation by default

  ///////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk,RST_n;
  reg [11:0] BATT;				// analog values
  reg [11:0] BRAKE,TORQUE;		// analog values
  reg tgglMd;					// push button for assist mode
  reg [15:0] YAW_RT;			// models angular rate of incline (+ => uphill)

  localparam error_threshold = 50;
  localparam testcase = 1;

  //////////////////////////////////////////////////
  // Declare any internal signal to interconnect //
  ////////////////////////////////////////////////
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;
  wire highGrn,lowGrn,highYlw,lowYlw,highBlu,lowBlu;
  wire hallGrn,hallBlu,hallYlw;
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;
  logic cadence;
  wire [1:0] LED;			// hook to setting from PB_intf
  
  wire signed [11:0] coilGY,coilYB,coilBG;
  logic [11:0] curr;		// comes from hub_wheel_model
  wire [11:0] BATT_TX, TORQUE_TX, CURR_TX;
  logic vld_TX;
  
  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
		    .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
		     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
		     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike #(FAST_SIM) iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
                         .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
			 .inertMISO(inertMISO),.inertINT(inertINT),
			 .cadence(cadence),.tgglMd(tgglMd),.TX(TX_RX),
			 .LED(LED));
			 
			 
  ////////////////////////////////////////////////////////////
  // Instantiate UART_rcv or some other telemetry monitor? //
  //////////////////////////////////////////////////////////
			 
  initial begin
    clk = 0;

    // reset all
    RST_n = 0;
    @(posedge clk);
    @(negedge clk);
    RST_n = 1;


    if(testcase == 1) begin
      BATT = 12'hB11;
      BRAKE = 12'h900;	// brake not asserted
      TORQUE = 12'h700;	// low torque
      YAW_RT = 16'h0000;

      repeat(2048) begin
        cadence = 0;
        repeat(2048) @(posedge clk);
        cadence = 1;
        repeat(2048) @(posedge clk);
      end

      if(iDUT.iSensorCondition.error > error_threshold || iDUT.iSensorCondition.error < -error_threshold) begin
        $display("Error detected in test case %0d: %0d", 1, iDUT.iSensorCondition.error);
        $stop();
      end else begin
        $display("No error detected in test case %0d", 1);
      end

      TORQUE = 12'h9FF;

      repeat(2048) begin
        cadence = 0;
        repeat(2048) @(posedge clk);
        cadence = 1;
        repeat(2048) @(posedge clk);
      end

      if(iDUT.iSensorCondition.error > error_threshold || iDUT.iSensorCondition.error < -error_threshold) begin
        $display("Error detected in test case %0d: %0d", 1, iDUT.iSensorCondition.error);
        $stop();
      end else begin
        $display("No error detected in test case %0d", 1);
      end

      YAW_RT = 12'h2000;

      repeat(2048) begin
        cadence = 0;
        repeat(2048) @(posedge clk);
        cadence = 1;
        repeat(2048) @(posedge clk);
      end

      if(iDUT.iSensorCondition.error > error_threshold || iDUT.iSensorCondition.error < -error_threshold) begin
        $display("Error detected in test case %0d: %0d", 1, iDUT.iSensorCondition.error);
        $stop();
      end else begin
        $display("No error detected in test case %0d", 1);
      end

    $display("Test case %0d completed", 1);
    $stop();
    
    end

    
  end
  
  ///////////////////
  // Generate clk //
  /////////////////
  always
    #10 clk = ~clk;

  ///////////////////////////////////////////
  // Block for cadence signal generation? //
  /////////////////////////////////////////
	
endmodule
