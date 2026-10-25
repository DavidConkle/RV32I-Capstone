package rv32i_pkg;
    // we should decide global enum codes to use for each operation.
    // the following is my suggestion :)
    typedef enum logic [3:0] {
        ADD  = 4'b0000,
        SUB  = 4'b0001,
        AND  = 4'b0010,
        OR   = 4'b0011,
        XOR  = 4'b0100,
        SLL  = 4'b0101,
        SRL  = 4'b0110,
        SRA  = 4'b0111,
        SLT  = 4'b1000,
        SLTU = 4'b1001
    } alu_ops;
endpackage

import rv32i_pkg::*; // pulls in the package so we can use the enum codes in this module

module alu (
    // given two 32-bit inputs a and b, perform the operation specified by op and return the result
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  alu_ops      op,
    output logic [31:0] result,
    output logic        zero_flag,
    output logic        less_flag
);
    always_comb begin
        case (op)
            ADD:  result = a + b;
            SUB:  result = a - b;
            AND:  result = a & b;
            OR:   result = a | b;
            XOR:  result = a ^ b;
            SLL:  result = a << b[4:0];             // logical left shift by the lower 5 bits of b (shifts 0-31 bits)
            SRL:  result = a >> b[4:0];             // logical right shift by the lower 5 bits of b
            SRA:  result = $signed(a) >>> b[4:0];   // arithmetic right shift by the lower 5 bits of b
            SLT:  result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0; // set less than
            SLTU: result = (a < b) ? 32'b1 : 32'b0; // set less than unsigned
            default: result = 32'b0;
        endcase
    end
    // raise zero flag if the result is zero
    assign zero_flag = (result == 32'b0);

    // raise less flag if un/signed a < b
    always_comb begin
        if (alu_ctrl == ALU_SLTU) begin
            less_flag = (a < b);                   // unsigned less than (BLTU, BGEU, SLTU)
        end else begin
            less_flag = ($signed(a) < $signed(b)); // signed less than (BLT, BGE, SLT)
        end
    end
endmodule