import rv32i_pkg::*;		// Import package

module control_unit_tb();
  
  // Declare signals
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
	
  logic [3:0] ALUControl;
  logic       RS1Source;
  logic       RS2Source;
  logic       MemWrite;
  logic       WriteSel;
  logic [2:0] Funct3;
  logic       WriteEnable;

  // Instantiate the DUT
  control_unit dut(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .ALUControl(ALUControl),
    .RS1Source(RS1Source),
    .RS2Source(RS2Source),
    .MemWrite(MemWrite),
    .WriteSel(WriteSel),
    .Funct3(Funct3),
    .WriteEnable(WriteEnable)
  );
  
  // Dump the waveform
  initial begin
    $dumpfile("control_unit_tb.vcd");
    $dumpvars(0, control_unit_tb);
  end
  
  
  // Task that automates the process of driving inputs and reporting errors
  task automatic check(
    input string      name,
    input logic [6:0] i_opcode,
    input logic [2:0] i_funct3,
    input logic [6:0] i_funct7,
    input logic [3:0] e_alu,
    input logic       e_rs1src,
    input logic       e_rs2src,
    input logic       e_memwr,
    input logic       e_wrsel,
    input logic       e_we
  );
    opcode = i_opcode;
    funct3 = i_funct3;
    funct7 = i_funct7;
    #1;
    if (ALUControl !== e_alu)
      $fatal(1, "%s: ALUControl = %b, expected %b", name, ALUControl, e_alu);
    if (RS1Source !== e_rs1src)
      $fatal(1, "%s: RS1Source = %b, expected %b", name, RS1Source, e_rs1src);
    if (RS2Source !== e_rs2src)
      $fatal(1, "%s: RS2Source = %b, expected %b", name, RS2Source, e_rs2src);
    if (MemWrite !== e_memwr)
      $fatal(1, "%s: MemWrite = %b, expected %b", name, MemWrite, e_memwr);
    if (WriteSel !== e_wrsel)
      $fatal(1, "%s: WriteSel = %b, expected %b", name, WriteSel, e_wrsel);
    if (WriteEnable !== e_we)
      $fatal(1, "%s: WriteEnable = %b, expected %b", name, WriteEnable, e_we);
    if (Funct3 !== i_funct3)
      $fatal(1, "%s: Funct3 = %b, expected pass-through of %b", name, Funct3, i_funct3);
    $display("pass: %s", name);
    #1;
  endtask
  
  
  // Simple directed testing
  initial begin
	//    name         opcode     funct3   funct7      ALU     rs1   rs2   wr    wsel  we
    // R-type
    check("ADD",       OP_R,      3'b000,  7'b0000000, ADD,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("SUB",       OP_R,      3'b000,  7'b0100000, SUB,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("SLL",       OP_R,      3'b001,  7'b0000000, SLL,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("SLT",       OP_R,      3'b010,  7'b0000000, SLT,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("SLTU",      OP_R,      3'b011,  7'b0000000, SLTU,   1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("XOR",       OP_R,      3'b100,  7'b0000000, XOR,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("SRL",       OP_R,      3'b101,  7'b0000000, SRL,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("SRA",       OP_R,      3'b101,  7'b0100000, SRA,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("OR",        OP_R,      3'b110,  7'b0000000, OR,     1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
    check("AND",       OP_R,      3'b111,  7'b0000000, AND,    1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

    // I-type ALU (RS2Source = immediate)
    check("ADDI",      OP_IMM,    3'b000,  7'b0000000, ADD,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("SLTI",      OP_IMM,    3'b010,  7'b0000000, SLT,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("SLTIU",     OP_IMM,    3'b011,  7'b0000000, SLTU,   1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("ANDI",      OP_IMM,    3'b111,  7'b0000000, AND,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("ORI",       OP_IMM,    3'b110,  7'b0000000, OR,     1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("XORI",      OP_IMM,    3'b100,  7'b0000000, XOR,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("SLLI",      OP_IMM,    3'b001,  7'b0000000, SLL,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("SRLI",      OP_IMM,    3'b101,  7'b0000000, SRL,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    check("SRAI",      OP_IMM,    3'b101,  7'b0100000, SRA,    1'b0, 1'b1, 1'b0, 1'b0, 1'b1);

    // I-type Load (address = rs1 + imm, WriteSel = memory)
    check("LW",        OP_LOAD,   3'b010,  7'b0000000, ADD,    1'b0, 1'b1, 1'b0, 1'b1, 1'b1);
    check("LH",        OP_LOAD,   3'b001,  7'b0000000, ADD,    1'b0, 1'b1, 1'b0, 1'b1, 1'b1);
    check("LHU",       OP_LOAD,   3'b101,  7'b0000000, ADD,    1'b0, 1'b1, 1'b0, 1'b1, 1'b1);
    check("LB",        OP_LOAD,   3'b000,  7'b0000000, ADD,    1'b0, 1'b1, 1'b0, 1'b1, 1'b1);
    check("LBU",       OP_LOAD,   3'b100,  7'b0000000, ADD,    1'b0, 1'b1, 1'b0, 1'b1, 1'b1);

    // S-type (address = rs1 + imm, MemWrite = 1, no register write)
    check("SW",        OP_STORE,  3'b010,  7'b0000000, ADD,    1'b0, 1'b1, 1'b1, 1'b0, 1'b0);
    check("SH",        OP_STORE,  3'b001,  7'b0000000, ADD,    1'b0, 1'b1, 1'b1, 1'b0, 1'b0);
    check("SB",        OP_STORE,  3'b000,  7'b0000000, ADD,    1'b0, 1'b1, 1'b1, 1'b0, 1'b0);

    // U-type
    check("AUIPC",     OP_AUIPC,  3'b000,  7'b0000000, ADD,    1'b1, 1'b1, 1'b0, 1'b0, 1'b1);
    check("LUI",       OP_LUI,    3'b000,  7'b0000000, PASSB,  1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    
    $display("ALL TESTS PASSED");
    $finish;
  end
  
endmodulev