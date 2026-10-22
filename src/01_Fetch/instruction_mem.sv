/*
Headder
*/
module instructin_mem(
    input logic clk,
    input logic rst_n,
    input logic[31:0] pc,
    output logic[31:0] instr

    parameter WIDTH = 32; //Each instruction has 32 bits
    parameter DEPTH = 256; //Store up to 256 instructions, arbitrary number since no tapeout
    parameter FILE = "instr.hex"; //Instruction file to load into memeory
    
    /*  Instruction file formating
        -Use hex and one instruction per line
        -Memory is word-addressable, may need to be changed later to byte-addressable
        -No prefix is needed for hex values(no 0x0000abcd) - 32 bit is 8 hex digits
    */
);
    //Instantiate hardware memory
    reg [WIDTH-1:0] instr_mem[0:DEPTH-1];

    //Only need to open file once
    initial begin
        $readmemh(FILE, instr_mem); //Load instructions from file into memory
    end

    always_comb begin
        //Get instrucion, clog2 gets how many bits are needed to address DEPTH in powers of 2,
        // add one to set upper bound (pc may be larger than instruction memory) 
        // slice off last two bits to divide by 4, assumes memory is alligned to multiples of 4 (byte adressable)
        instr = instr_mem[$clog2(DEPTH)+1:2]; 
    end

endmodule