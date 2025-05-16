module uart_tx(clk,rst_n,tx,strt_tx,tx_data,tx_done,mid_bit,trnsmttng);

////////////////////////////////////////////////////////////////////
// WARNING : I introduced a lot of subtle bugs in this code deliberately
// copying it for your own UART_tx is not a good starting point.
/////////////////////////////////////////////////////////////////////

input clk,rst_n;		// clock and active low reset
input strt_tx;			// strt_tx tells TX section to transmit tx_data
input [7:0] tx_data;		// byte to transmit
output tx, tx_done;		// tx_done asserted when transmission complete
output mid_bit;			// sent to CRC to indicate in middle of bit and can sample and shift
output trnsmttng;		// used to enable tri-states of commMod, and block receiving own transmissions

reg state,nxt_state;		// I can name that tune in two states
reg [8:0] shift_reg;		// 1-bit wider to store start bit
reg [3:0] bit_cnt;		// bit counter
reg [9:0] baud_cnt;		// baud rate counter (471.85MHz/460800) = need 10-bit count
reg tx_done;			// status flop

reg trnsmttng;	        	// output used to enable tri-states, generated in SM
reg load;			// assigned in state machine

wire shift;

localparam IDLE = 1'b0;
localparam TX = 1'b1;

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
  if (load)
    bit_cnt <= 4'b0000;
  else if (shift)
    bit_cnt <= bit_cnt-1;

//////////////////////////
// Infer baud_cnt next //
////////////////////////
always @(posedge clk)
  if (load)
    baud_cnt <= 10'h0000;
  else if (shift)
    baud_cnt <= 10'h0000;		// reset when baud count indicates 19200 baud
  else if (trnsmttng)
    baud_cnt <= baud_cnt+1;		// only burn power incrementing if tranmitting

////////////////////////////////
// Infer shift register next //
//////////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    shift_reg <= 9'h000;		// reset to idle state being transmitted
  else if (load)
    shift_reg <= {1'b1,tx_data};	// start, and stop of previous transmission
  else if (shift)
    shift_reg <= {shift_reg[8:1],1'b0};	

///////////////////////////////////////////////
// Easiest to make tx_done a reset/set flop //
/////////////////////////////////////////////
always @(posedge clk or negedge rst_n)
  if (!rst_n)
    tx_done <= 1'b0;
  else if (strt_tx)
    tx_done <= 1'b0;
  else if (bit_cnt==4'b1001)
    tx_done <= 1'b1;

//////////////////////////////////////////////
// Now for hard part...State machine logic //
////////////////////////////////////////////
always @(state,strt_tx,shift,bit_cnt)
  begin
    //////////////////////////////////////
    // Default assign all output of SM //
    ////////////////////////////////////
    load         = 0;
    trnsmttng = 0;
    nxt_state    = IDLE;	// always a good idea to default to IDLE state
    
    case (state)
      IDLE : begin
        if (strt_tx)
          begin
            nxt_state = TX;
            load = 1;
          end
        else nxt_state = IDLE;
      end
      default : begin		// this is TX state
        if (bit_cnt==4'b1010)
          nxt_state = IDLE;
        else
          nxt_state = TX;
        trnsmttng = 1;
      end
    endcase
  end

////////////////////////////////////
// Continuous assignement follow //
//////////////////////////////////
assign shift = &baud_cnt; 
assign mid_bit = (baud_cnt==15'h200) ? (((bit_cnt>4'b0000) && (bit_cnt<4'b1001)) ? 1'b1 : 1'b0) : 1'b0;
assign tx = shift_reg[0];		// LSB of shift register is TX

endmodule

