/*
Header and other stuff
*/

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


module decode (
  input logic[31:0] instr;
  output logic[4:0] rs1, rs2, rd;
  output logic validinstr;
  output logic[31:0] imm; //Immediate value, 
  output logic[3:0] alu_op; //ALU operation code, to be defined in the ALU module
);

  // Basic fields, not all instructions have these fields
  logic[6:0] opcode;
  logic[3:0] funct3;

  assign opcode = instr[6:0];
  assign rd = instr[11:7];
  assign rs1 = instr[19:15];
  assign rs2 = instr[24:20];
  assign funct3 = instr[14:12];


  //Check opcode for instr type
  always @(*) begin
  
    //Initial vals
    validinstr = 1'b1;
    imm = 32'b0;
    alu_op = ADD; //Maybe add null enum?

    case(opcode)
    
    //LUI, load upper 20 bits of imm to rd
    7'b0110111: begin
      imm = {instr[31:12], 12'b0}; // Upper 20 bits of rd
      alu_op = ADD;
    end

    //AUIPC, addes upper 20 bits of rd to PC
    7'b0010111: begin
      imm = {instr[31:12], 12'b0}; // Upper 20 bits of rd
      alu_op = ADD;
    end 

    //Need to get pc value, figure out how to pass through
    //JAL, jump to new location (PC + imm) and store return address in rd
    7'b1101111: begin
      imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      alu_op = ADD;
    end


    //JALR, jump to new location (rs1 + imm) and store return address in rd
    7'b1100111: begin
      imm = {{20{instr[31]}}, instr[31:20]};
      alu_op = ADD;
    end

    //BEQ, BNE, BLT, BGE, BLTU, BGEU
    7'b1100011: begin
      imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // 12-bit immediate for branch instructions
      case(funct3)
        //BEQ and BNE
        3'b000, 3'b001: alu_op = SUB;

        //BLT and BGE
        3'b100, 3'b101: alu_op = SLT; 


        //BLTU and BGEU
        3'b110, 3'b111: alu_op = SLTU;
      
        default: validinstr = 1'b0;
      endcase
    end
    
    //LB, LH, LW, LBU, LHU, load instructions, needs memory intercface    
    7'b0000011: begin
      imm = {{20{instr[31]}}, instr[31:20]}; // 12-bit immediate for load instructions
      case(funct3)
        //LB, load byte
        3'b000: 

        //LH, load halfword
        3'b001: 

        //LW, load word
        3'b010: 

        //LBU, load byte unsigned
        3'b100: 

        //LHU, load halfword unsigned
        3'b101: 

        default: validinstr = 1'b0;
      endcase
    end

    //SB, SH, SW, store instructions, needs memory intercface
    7'b0100011: begin
      imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      case(funct3)
        //SB, store byte
        3'b000: 

        //SH, store halfword
        3'b001:

        //SW, store word
        3'b010: 
        default: validinstr = 1'b0;
      endcase
    end

    //Immediate arithmetic
    //ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    7'b0010011: begin
      case(funct3)
        //ADDI
        3'b000: alu_op = ADD;

        //SLTI
        3'b010: alu_op = SLT;

        //SLTIU
        3'b011: alu_op = SLTU;
 
        //XORI
        3'b100: alu_op = XOR;

        //ORI
        3'b110: alu_op = OR;

        //ANDI
        3'b111: alu_op = AND;

        //SLLI
        3'b001: alu_op = SLL;

        //SRLI, SRAI 
        3'b101: alu_op = instr[30] ? SRA : SRL;
          
        default: validinstr = 1'b0;
      endcase
    end

    //Register arithmetic
    //ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    7'b0110011: begin
      case(funct3)
        //ADD, SUB 
        3'b000: alu_op = instr[30] ? SUB : ADD;
        
        //SLL
        3'b001: alu_op = SLL;

        //SLT
        3'b010: alu_op = SLT;

        //SLTU
        3'b011: alu_op = SLTU;

        //XOR
        3'b100: alu_op = XOR;

        //SRL, SRA 
        3'b101: alu_op = instr[30] ? SRA : SRL;
        
        //OR
        3'b110: alu_op = OR;

        //AND
        3'b111: alu_op = AND;

        default: validinstr = 1'b0;
      endcase
    end

    //FENCE, FENCE.I
    7'b0001111: 
    default: validinstr = 1'b0;
    
  endcase
  end

endmodule