module CRC(clk,strt,shift,msg_in ,signature);

input clk,strt,shift,msg_in;

output [7:0] signature;

reg [7:0] signature;

wire [7:0] nxt_signature;
wire fb;

always @(posedge clk)
  if (strt)
    signature <= 8'h00;
  else if (shift)
    signature <= nxt_signature;

assign fb = msg_in ^ signature[7];
assign nxt_signature = ({5'h00,fb,fb,fb})^({signature[6:0],1'b0});

endmodule
