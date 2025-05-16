module uart_rcv(clk,rst_n,rx,rx_rdy,rx_data,mid_bit,start);

///////////////////////////////////////////////////////
// WARNING: I introduced a lot of subtle bugs in this code
// so copying it as your uart_rcv is a bad idea
//////////////////////////////////////////////////////

input clk,rst_n;			// clock and active low reset
input rx;				// rx is the asynch serial input (need to double flop)
output rx_rdy;				// signifies to core a byte has been received
output mid_bit;				// sent to CRC to indicate in middle of bit and can sample and shift
output start;
output [7:0] rx_data;			// data that was received

reg state,nxt_state;	 		// I can name that tune in 2 states
reg [8:0] shift_reg;			// shift register MSB will contain stop bit when finished
reg [3:0] bit_cnt;			// bit counter (need extra bit for start bit)
reg [9:0] baud_cnt;			// baud rate counter (471.85MHz/460800) = need 10-bit count
reg rx_rdy;				// implemented as a flop
reg rx_ff1, rx_ff2;			// back to back flops for meta-stability

reg start, set_rx_rdy, receiving;	// set in state machine

wire shift;

parameter IDLE  = 1'b0;
parameter RX    = 1'b1;

////////////////////////////
// Infer state flop next //
//////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else
    state <= nxt_state;

/////////////////////////
// Infer bit_cnt next //
///////////////////////
always @(posedge clk)
  if (start)
    bit_cnt <= 4'b0000;
  else if (shift)
    bit_cnt <= bit_cnt+1;

//////////////////////////
// Infer baud_cnt next //
////////////////////////
always @(posedge clk)
  if (start)
    baud_cnt <= 10'h400;		// load at half a bit time for sampling in middle of bits
  else if (shift)
    baud_cnt <= 10'h000;		// reset when baud count is full value for 19200 baud
  else if (receiving)
    baud_cnt <= baud_cnt+1;		// only burn power incrementing if tranmitting

////////////////////////////////
// Infer shift register next //
//////////////////////////////
always @(posedge clk)
  if (shift)
    shift_reg <= {rx,shift_reg[8:1]};   // LSB comes in first

/////////////////////////////////////////////
// rx_rdy will be implemented with a flop //
///////////////////////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    rx_rdy <= 1'b0;
  else if (start)
    rx_rdy <= 1'b0;			// knock down rx_rdy when new start bit detected
  else if (set_rx_rdy)
    rx_rdy <= 1'b0;

////////////////////////////////////////////////
// RX is asynch, so need to double flop      //
// prior to use for meta-stability purposes //
/////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    begin
      rx_ff1 <= 1'b0;			// reset to idle state
      rx_ff2 <= 1'b0;
    end
  else
    begin
      rx_ff1 <= rx;
      rx_ff2 <= rx_ff1;
    end

//////////////////////////////////////////////
// Now for hard part...State machine logic //
////////////////////////////////////////////
always @(state,rx_ff2,bit_cnt)
  begin
    //////////////////////////////////////
    // Default assign all output of SM //
    ////////////////////////////////////
    start         = 0;
    set_rx_rdy    = 0;
    receiving     = 0;
    nxt_state     = IDLE;	// always a good idea to default to IDLE state
    
    case (state)
      IDLE : begin
        if (rx_ff2)		// did fall of start bit occur?
          begin
            nxt_state = RX;
            start = 1;
          end
        else nxt_state = IDLE;
      end
      default : begin		// this is RX state
        if (bit_cnt==4'b1001)
          begin
            set_rx_rdy = 1;
            nxt_state = IDLE;
          end
        else
          nxt_state = RX;
        receiving = 1;
      end
    endcase
  end

////////////////////////////////////
// Continuous assignement follow //
//////////////////////////////////
assign shift = &baud_cnt; 
assign mid_bit = (shift && (bit_cnt>0) && (bit_cnt<4'b1001)) ? 1'b1 : 1'b0;
assign rx_data = shift_reg[7:0];				// MSB of shift reg is stop bit

endmodule
