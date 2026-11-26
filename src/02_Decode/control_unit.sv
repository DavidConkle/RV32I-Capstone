import rv32i_pkg::*;		// Import Package

module control_unit
(
  input logic [6:0] opcode,
  input logic [2:0] funct3,
  input logic [6:0] funct7,
	
  output logic [3:0] ALUControl,
  output logic       RS1Source,
  output logic       RS2Source,
  output logic       MemWrite,
  output logic       MemRead,
  output logic       WriteSel,
  output logic [2:0] Funct3,
  output logic       WriteEnable
);
  
  // Funct3 is unchanged (Might make sense to remove later)
  assign Funct3 = funct3;
  
  // ---------------------------------------------------------------------------
  // Determine the ALU opcode for R-type and I-type instructions
  // ---------------------------------------------------------------------------
  alu_ops alu_op_r;
  alu_ops alu_op_i;
  
  always_comb begin
    // R-type:
    case (funct3)
      3'b000:  begin
        if (funct7[5]) begin
          alu_op_r = SUB; 
        end
        else begin
          alu_op_r = ADD;
        end
      end
      3'b001:  alu_op_r = SLL;
      3'b010:  alu_op_r = SLT;
      3'b011:  alu_op_r = SLTU;
      3'b100:  alu_op_r = XOR;
      3'b101:  begin
        if (funct7[5]) begin
          alu_op_r = SRA; 
        end
        else begin
          alu_op_r = SRL;
        end
      end
      3'b110:  alu_op_r = OR;
      3'b111:  alu_op_r = AND;
      default: alu_op_r = ADD;
    endcase

    
    // I-type:
    case (funct3)
      3'b000:  alu_op_i = ADD;
      3'b001:  alu_op_i = SLL;
      3'b010:  alu_op_i = SLT;
      3'b011:  alu_op_i = SLTU;
      3'b100:  alu_op_i = XOR;
      3'b101:  begin
        if (funct7[5]) begin
          alu_op_i = SRA; 
        end
        else begin
          alu_op_i = SRL;
        end
      end
      3'b110:  alu_op_i = OR;
      3'b111:  alu_op_i = AND;
      default: alu_op_i = ADD;
    endcase
  end
  
  
  // ---------------------------------------------------------------------------
  // Main decoder logic
  // ---------------------------------------------------------------------------
  
  always_comb begin
    // Set all values to 0 by default, then change when necessary
    ALUControl = ADD;
    RS1Source = 1'b0;
    RS2Source = 1'b0;
    MemWrite = 1'b0;
    WriteSel = 1'b0;
    WriteEnable = 1'b0;
    
    // Drive output for each opcode
    case (opcode)
      OP_R: begin
        ALUControl = alu_op_r;
        WriteEnable = 1'b1;  
      end
      
      OP_IMM: begin
        ALUControl = alu_op_i;
        RS2Source = 1'b1;
        WriteEnable = 1'b1;
      end
      
      OP_LOAD: begin
        ALUControl = ADD;
        RS2Source = 1'b1;
        WriteSel = 1'b1;
        WriteEnable = 1'b1;
        MemRead = 1'b1;
      end
      
      OP_STORE: begin
        ALUControl = ADD;
        RS2Source = 1'b1;
        MemWrite = 1'b1;
      end
      
      OP_BRANCH: begin
        // Processor currently does not support branching, will be updated later
      end
      
      OP_JAL: begin
        // Processor currently does not support JAL, will be updated later
      end
      
      OP_JALR: begin
        // Processor currently does not support JALR, will be updated later
      end
	
      OP_LUI: begin
        ALUControl = PASSB;
        RS2Source = 1'b1;
        WriteEnable = 1'b1;
      end
      
      OP_AUIPC: begin
        ALUControl = ADD;
        RS1Source = 1'b1;
        RS2Source = 1'b1;
        WriteEnable = 1'b1;
      end
    endcase
  end   
endmodule