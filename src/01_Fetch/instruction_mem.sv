module instruction_mem #(
    parameter WIDTH = 32, //Each instruction has 32 bits
    parameter DEPTH = 256 //Store up to 256 instructions, arbitrary number since no tapeout
)(
    input logic clk,
    input logic rst_n,
    input logic[31:0] pc,
    output logic[31:0] instr
);
  
    //Instantiate hardware memory
    reg [WIDTH-1:0] instr_mem[0:DEPTH-1];

    //Get instrucion, clog2 gets how many bits are needed to address DEPTH in powers of 2,
    // add one to set upper bound (pc may be larger than instruction memory) 
    // slice off last two bits to divide by 4, assumes memory is alligned to multiples of 4 (byte adressable)
    always_comb begin
      instr = instr_mem[pc[$clog2(DEPTH)+1:2]]; 		// Elaborated at elaboration, therfore synthesizable
    end

endmodule
