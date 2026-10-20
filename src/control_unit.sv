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



module control_unit
    import rv32i_pkg::*;
(
     input  logic [6:0] opcode,
    input  logic [2:0] funct3,
     input  logic [6:0] funct7,

    output alu_ops     alu_op     // operation select for the ALU

);

    always_comb begin

        alu_op = ADD;   //Default ALU operation
        
        case (funct3)
                3'b000: alu_op = funct7[5] ? SUB: ADD;  // ADD unless funct7 bit 5 is 1, otherwise SUB
                3'b001: alu_op = SLL;
                3'b010: alu_op = SLT;
                3'b011: alu_op = SLTU;
                3'b100: alu_op = XOR;
                3'b101: alu_op = funct7[5] ? SRA : SRL;
                3'b110: alu_op = OR;
                3'b111: alu_op = AND;

        endcase
        
    end
endmodule

