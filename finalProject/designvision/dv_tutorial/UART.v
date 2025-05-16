module uart(clk,rst_n,rx,tx,rx_rdy,rx_data, strt_tx,tx_data,tx_done,mid_bit,trnsmttng,strt_rcv);

input clk,rst_n;		// clock and active low reset
input rx,strt_tx;		// strt_tx tells TX section to transmit tx_data
input [7:0] tx_data;		// byte to transmit
output tx,rx_rdy,tx_done;	// rx_rdy asserted when byte received,
output trnsmttng;		// output asserted when transmitting.  Used to enable tri-states
				// tx_done asserted when tranmission complete
output mid_bit;			// signal to CRC to tell it to sample and shift
output strt_rcv;		// signal to CRC to clear the signature register
output [7:0] rx_data;		// byte received

wire mid_tx,mid_rcv;

//////////////////////////////
// Instantiate Transmitter //
////////////////////////////
uart_tx iTX(.clk(clk), .rst_n(rst_n), .tx(tx), .strt_tx(strt_tx), .tx_data(tx_data),
            .tx_done(tx_done), .mid_bit(mid_tx), .trnsmttng(trnsmttng));

///////////////////////////
// Instantiate Receiver //
/////////////////////////
uart_rcv iRX(.clk(clk), .rst_n(rst_n), .rx(rx), .rx_rdy(rx_rdy),
        .rx_data(rx_data), .mid_bit(mid_rcv), .start(strt_rcv));

assign mid_bit = mid_tx | mid_rcv;

endmodule
