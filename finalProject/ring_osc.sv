module ring_osc(
	input logic en, 
	output logic out
);

    logic n1, n2;

    // NAND gate with enable signal
    nand #5 gate1 (n1, en, out);
    // Inverter 1
    not #5 gate2 (n2, n1);
    // Inverter 2
    not #5 gate3 (out, n2);

endmodule
