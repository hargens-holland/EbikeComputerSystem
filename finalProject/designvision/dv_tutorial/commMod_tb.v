module commMod_tb();

reg clk,rst_n;
reg trmt;
reg clr_rdy_DUT,clr_rdy_RCV;
reg [15:0] txdata;

wire [15:0] rxdata_DUT,rxdata_RCV;

//////////////////////
// Instantiate DUT //
////////////////////
commMod iDUT(.clk(clk), .rst_n(rst_n), .trmt(trmt), .txdata(txdata), .pckt_rdy(rdy_DUT), 
             .clr_pckt_rdy(clr_rdy_DUT), .rxdata(rxdata_DUT), .Bp(Bp), .Am(Am));

commMod iRCV(.clk(clk), .rst_n(rst_n), .trmt(1'b0), .txdata(16'h0000), .pckt_rdy(rdy_RCV),
             .clr_pckt_rdy(clr_rdy_RCV), .rxdata(rxdata_RCV), .Bp(Bp), .Am(Am));

initial begin
  clk = 0;
  rst_n = 0;
  txdata = 16'h1234;
  clr_rdy_DUT = 0;
  clr_rdy_RCV = 0;
  #2 rst_n = 1;
  #2 trmt = 1;
  #2 trmt = 0;
  @(posedge iDUT.tx_done);
  @(posedge iDUT.tx_done);
  @(posedge iDUT.tx_done);
  if ((rdy_RCV) && (rxdata_RCV==16'h1234)) $display("Tranmission of %h at time %t was successful",rxdata_RCV,$time);
  else $display("ERROR: Transmission of 0x1234 at time %t failed!",$time);


  ///////////////////////////////////////////////////////////////////////////////////////
  // 2nd transmission with new data.  Check for fall of rx_rdy_RCV with new reception //
  /////////////////////////////////////////////////////////////////////////////////////
  #2 txdata = 16'h9669;
  #2 trmt = 1;
  #2 trmt = 0;
  @(posedge iDUT.tx_done);
  if (rdy_RCV) $display("ERROR: rdy_RCV should not be high at time %t",$time);
  @(posedge iDUT.tx_done);
  @(posedge iDUT.tx_done);
  if ((rdy_RCV) && (rxdata_RCV==16'h9669)) $display("Tranmission of %h at time %t was successful",rxdata_RCV,$time);
  else $display("ERROR: Transmission of 0x9669 at time %t failed!",$time);

  //////////////////////////////////////////////////////////////////////////
  // 3rd transmission.  Look to see clr_pckt_rdy works, and deliberately //
  // interrupt the CRC transmission to ensure pckt_rdy does not get set //
  ///////////////////////////////////////////////////////////////////////

  #2 txdata = 16'habcd;
     clr_rdy_RCV = 1;
  #2 trmt = 1;
  if (rdy_RCV) $display("ERROR: rdy_RCV should not be high at time %t",$time);
  #2 trmt = 0; 
  #2 trmt = 1;
  #2 trmt = 0;
  @(posedge iDUT.tx_done);
  @(posedge iDUT.tx_done);
  #4 force Bp = 0;            // force CRC transmission to be messed up
  @(posedge iDUT.tx_done);
  if (rxdata_RCV==16'habcd)
    if (rdy_RCV) $display("ERROR: At time %t CRC was messed up, so pckt_rdy should not have been asserted",$time);
    else $display("At %t data receved was correct but CRC was messed up...passed",$time);
  else 
    $display("ERROR: recevied data at time %t should have been 0xabcd and was %h",$time,rxdata_RCV);
 
  #100; 
  $stop;
end

always
  #1 clk = ~clk;

endmodule
