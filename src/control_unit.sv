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

  
    // Make sure branch operations agree with ALU
    typedef enum logic [2:0] {
        BEQ  = 3'b000,
        BNE  = 3'b001,
        BLT  = 3'b100,
        BGE  = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
    } cmp_ops;

    // Opcodes
    localparam logic [6:0] OP_R      = 7'b0110011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
endpackage



module control_unit
    import rv32i_pkg::*;
(
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output alu_ops     alu_op,    // operation select for the ALU
    output logic       alu_src,   // 0 = ALU input B is rs2, 1 = ALU input B is immediate
    output logic       branch,    // instruction is a conditional branch
    output cmp_ops     cmp_op,    // which branch comparison to evaluate
    output logic       jump,      // JAL or JALR (unconditional)
    output logic       jalr,      // 1 = target is rs1+imm, 0 = target is PC+imm
    output logic       write_enable,    // 1 = write to register file
    //output logic       mem_read,   // 1 = read from memory (load)
    //output logic       mem_write,  // 1 = write to memory (store)
);

    // ALU op decode for R-type and I-type operations
    function automatic alu_ops decode_alu(input logic [2:0] f3, input logic alt);
        case (f3)
            3'b000:  return alt ? SUB : ADD;
            3'b001:  return SLL;
            3'b010:  return SLT;
            3'b011:  return SLTU;
            3'b100:  return XOR;
            3'b101:  return alt ? SRA : SRL;
            3'b110:  return OR;
            3'b111:  return AND;
            default: return ADD;
        endcase
    endfunction

    always_comb begin
        // Default outputs
        alu_op  = ADD;
        alu_src = 1'b0;
        branch  = 1'b0;
        cmp_op  = BEQ;
        jump    = 1'b0;
        jalr    = 1'b0;

        case (opcode)
            OP_R: begin
                alu_op = decode_alu(funct3, funct7[5]);
                write_enable = 1'b1;
            end

            OP_IMM: begin
                alu_src = 1'b1;
                alu_op  = decode_alu(funct3, (funct3 == 3'b101) && funct7[5]);
                write_enable = 1'b1;
            end

            OP_BRANCH: begin
                branch  = 1'b1;
                alu_src = 1'b0;        // compare rs1 vs rs2
                cmp_op  = cmp_ops'(funct3);
                // Pick the ALU op that produces the needed comparison result
                case (funct3[2:1])
                    2'b00:   alu_op = SUB;   // BEQ/BNE  -> check zero flag
                    2'b10:   alu_op = SLT;   // BLT/BGE  -> signed less-than
                    2'b11:   alu_op = SLTU;  // BLTU/BGEU-> unsigned less-than
                    default: alu_op = SUB;
                endcase
            end

            OP_JAL: begin
                jump    = 1'b1;
                write_enable = 1'b1;
            end

            OP_JALR: begin
                jump    = 1'b1;
                jalr    = 1'b1;
                alu_src = 1'b1;
                alu_op  = ADD;         // target = rs1 + imm (clear bit 0 in datapath)
                write_enable = 1'b1;
            end

            default: ; // keep defaults (treat as NOP)
        endcase
        
    end

endmodule

