module commMod(clk,rst_n,trmt,txdata,pckt_rdy,clr_pckt_rdy,rxdata,Bp,Am);

input clk,rst_n,trmt,clr_pckt_rdy;
input [15:0] txdata;
inout Bp,Am;				// differential "Modbus" signals

output pckt_rdy;
output [15:0] rxdata;

////////////////////
// States for SM //
//////////////////
localparam IDLE         = 3'b000;
localparam TX_LOW       = 3'b001;
localparam TX_HIGH      = 3'b010;
localparam TX_CRC       = 3'b011;
localparam RX_HIGH      = 3'b100;
localparam RX_CRC       = 3'b101;

//////////////////////////////
// Datapath registers next //
////////////////////////////
reg [7:0] txhigh;	// need to buffer high byte of txdata
reg [15:0] rxdata;	// rxdata is first 2-bytes of packet

reg [2:0] state,nxt_state;
reg pckt_rdy;
reg rx_rdy_ff;		// need to flop rx_rdy so can have a posedge detector
reg tx_high,tx_crc;
reg strt_tx;
reg rx2high,rx2low;	// used to control buffering of received 8-bit data
reg set_pckt_rdy;

wire strt_rcv,rx,tx,trnsmttng;
wire [7:0] txdata8;	// data for UART transmitter to transmit.
wire [7:0] signature;	// signature from CRC
wire [7:0] rxdata8;
wire [7:0] sig_reversed;

///////////////////////
// Instantiate UART //
/////////////////////
uart iUART(.clk(clk), .rst_n(rst_n), .rx(rx), .tx(tx), .rx_rdy(rx_rdy), .rx_data(rxdata8),
           .strt_tx(strt_tx), .tx_data(txdata8), .tx_done(tx_done), .mid_bit(mid_bit), 
           .trnsmttng(trnsmttng), .strt_rcv(strt_rcv));

/////////////////////////////
// Instantiate CRC module //
///////////////////////////
CRC iCRC(.clk(clk), .strt(rset_crc), .shift(mid_bit), .msg_in(msg_in),
         .signature(signature));

//////////////////////////////////////////////////////////
// pckt_rdy is a flop set by error free reception, and //
// cleared by clr_pckt_rdy, or start of new reception // 
///////////////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
  if (!rst_n)
    pckt_rdy <= 1'b0;
  else if (rx2low || clr_pckt_rdy)	// clear on new reception
    pckt_rdy <= 1'b0;
  else if (set_pckt_rdy)
    pckt_rdy <= ~|signature;		// signature of all zeros is good

//////////////////////////////////////////////////////////
// Need to flop rx_rdy so can have a pos edge detector //
////////////////////////////////////////////////////////
always @(posedge clk, negedge rst_n)
  if (!rst_n)
    rx_rdy_ff <= 1'b0;
  else
    rx_rdy_ff <= rx_rdy;

assign rx_rdy_posedge = rx_rdy & ~rx_rdy_ff;

//////////////////////////////////////////////////////////////////////
// High byte of txdata needs to be captured for transmission later //
////////////////////////////////////////////////////////////////////
always @(posedge clk)
  if (trmt)
    txhigh <= txdata[15:8];

//////////////////////////////////////////////////////
// 16-bit rxdata is buffered from 8-bit receptions //
////////////////////////////////////////////////////
always @(posedge clk)
  if (rx2high)
    rxdata <= {rxdata8,rxdata[7:0]};
  else if (rx2low)
    rxdata <= {rxdata[15:8],rxdata8};

////////////////////////////////////////////////////////////
// Since assuming RX and TX are not active at same time, //
// can form msg_in as simple AND between the two        //
/////////////////////////////////////////////////////////
assign msg_in = rx & tx;

/////////////////////////////////////////////////////
// Reset the CRC signature on a transmission or   //
// on start bit of first bytebyte of a reception // 
//////////////////////////////////////////////////
assign rset_crc = (trmt || (strt_rcv &&  (state==IDLE))) ? 1'b1 : 1'b0;

always @(posedge clk, negedge rst_n)
  if (!rst_n) 
    state <= IDLE;
  else
    state <= nxt_state;

always @(state,trmt,rx_rdy_posedge,strt_rcv,tx_done)

begin
  /////////// Default SM outputs /////////////
  tx_high = 1'b0;
  tx_crc = 1'b0;
  strt_tx = 1'b0;
  rx2high = 1'b0;
  rx2low = 1'b0;
  set_pckt_rdy = 1'b0;
  nxt_state = IDLE;

  case (state)
    IDLE : begin
      if (trmt)
        begin
          nxt_state = TX_LOW;
          strt_tx = 1'b1;
        end
      else if (rx_rdy_posedge)
        begin
          nxt_state = RX_HIGH;
          rx2low = 1;		// store off low received byte
        end
    end
    TX_LOW : begin
      if (tx_done)
        begin
          nxt_state = TX_HIGH;
          strt_tx = 1'b1;
          tx_high = 1'b1;
        end
      else
        nxt_state = TX_LOW;
    end
    TX_HIGH : begin
      if (tx_done)
        begin
          nxt_state = TX_CRC;
          strt_tx = 1'b1;
          tx_crc = 1'b1;
        end
      else begin
        nxt_state = TX_HIGH;
        tx_high = 1'b1;
      end
    end
    TX_CRC : begin
      tx_crc = 1'b1;
      if (tx_done)
        nxt_state = IDLE;
      else
        nxt_state = TX_CRC;
    end
    /////////////////////////////////
    // Now for receive part of SM //
    ///////////////////////////////
    RX_HIGH : begin
      if (rx_rdy_posedge)
        begin
          nxt_state = RX_CRC;
          rx2high = 1;
        end
      else
        nxt_state = RX_HIGH;
    end
    default : begin		// this state is RX_CRC
      if (rx_rdy_posedge)
        begin
          set_pckt_rdy = 1;
          nxt_state = IDLE;
        end
      else
        nxt_state = RX_CRC; 
    end
  endcase
end 

////////////////////////////////////////////////////////////////////
// CRC has to be sent MSB first for evaluation to result in zero //
//////////////////////////////////////////////////////////////////
assign sig_reversed = {signature[0],signature[1],signature[2],signature[3],signature[4],signature[5],signature[6],signature[7]};

/////////////////////////////////
// 3:1 mux for txdata to UART //
///////////////////////////////
assign txdata8 = (tx_crc) ? sig_reversed : ((tx_high) ? txhigh : txdata[7:0]);

////////////////////////////////////////////////////////
// Infer differential tri-states that drive "modbus" //
//////////////////////////////////////////////////////
assign Bp = (trnsmttng) ? (tx) : 1'bz;
assign Am = (trnsmttng) ? (~tx) : 1'bz;

assign rx = Bp | trnsmttng;	// block reception of our own transmissions


endmodule
