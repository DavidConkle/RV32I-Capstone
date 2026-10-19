module program_counter(
	input clk,				// Clock signal
	input en,				// Enables the input of the PC
	input rst,				// Resets the adder 
  	input [31:0] pc_next,	// Input value of PC that is written to register when enables
  	output reg [31:0] pc	// Current output value of program register
);
  
	always @(posedge clk) begin
		if(rst)
			pc <= 32'h0000_0000;
		else if(en)
			pc <= pc_next;	// If enable is low, PC retains its value implicitly
    end
  
endmodule