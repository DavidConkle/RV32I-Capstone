module imm_gen (
    input logic[31:0] instr;

    //For future use if needed, not needed for base RV32I
    input logic[2:0] funct3;
    input logic[6:0] funct7; //funct5 + funct2 on sheet

    //Output immediate based on instruction type
    output logic[31:0] imm;
);

    always_comb begin
        logic[6:0] opcode = instr[6:0]; //Opcode extract
        case(opcode)
            //U-type
            7'b0110111, 7'b0010111: imm = {instr[31:12], 12'b0};
            //J-type 
            7'b1101111: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            //I-type
            7'b1100111, 7'b0010011, 7'b0000011: imm = {{20{instr[31]}}, instr[31:20]};
            //B-type
            7'b1100011: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            //S-type
            7'b0100011: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        endcase
    end
endmodule