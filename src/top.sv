// -----------------------------------------------------------------------------
// rv32i_top.sv
//
// Top level of the 5-stage RV32I pipeline (IF / ID / EX / MEM / WB).
//
// -----------------------------------------------------------------------------

module rv32i_top (
  input logic CLK,
  input logic RST
);

  // ===========================================================================
  // Pipeline register contents
  // ===========================================================================

  typedef struct packed {
    logic [31:0] PC;
    logic [31:0] Instr;
  } if_id_t;

  typedef struct packed {
    // control
    logic        WriteEnable;
    logic [2:0]  Funct3;
    logic        WriteSel;
    logic        MemWrite;
    logic        MemRead;				// May be used later
    logic        RS2Source;
    logic        RS1Source;
    logic [3:0]  ALUControl;
    // data
    logic [31:0] PC;
    logic [31:0] D1;
    logic [31:0] D2;
    logic [4:0]  RD;
    logic [31:0] ImmExt;
    logic [4:0]  RS1Addr;
    logic [4:0]  RS2Addr;
  } id_ex_t;

  typedef struct packed {
    logic        WriteEnable;
    logic [2:0]  Funct3;
    logic        WriteSel;
    logic        MemWrite;
    logic	     MemRead;				// May be used later
    logic [31:0] ALUOut;
    logic [31:0] D2Fwd;
    logic [4:0]  RD;
  } ex_mem_t;

  typedef struct packed {
    logic        WriteEnable;
    logic        WriteSel;
    logic [31:0] ALUOut;
    logic [31:0] MemAl;
    logic [4:0]  RD;
  } mem_wb_t;

  // in = value entering the register, out = value leaving the register
  if_id_t  if_id_in;
  id_ex_t  id_ex_in;
  ex_mem_t ex_mem_in;
  mem_wb_t mem_wb_in;

  if_id_t  if_id_out;
  id_ex_t  id_ex_out;
  ex_mem_t ex_mem_out;
  mem_wb_t mem_wb_out;

  // CLR and EN for each register, as well as the program counter
  logic CLR_PC,    EN_n_PC;
  logic CLR_IF_ID, EN_n_IF_ID;
  logic CLR_ID_EX, EN_n_ID_EX;
  logic CLR_EX_M,  EN_n_EX_M;
  logic CLR_M_WB,  EN_n_M_WB;

  // Set to CPU RST input signal so the CPU resets when RST is asserted
  assign CLR_PC = RST;
  assign CLR_IF_ID = RST;
  assign CLR_ID_EX = RST;
  assign CLR_EX_M  = RST;
  assign CLR_M_WB = RST;
  
  // Enable all registers and PC since enable input is not yet used
  assign EN_n_PC = 1'b1;
  assign EN_n_IF_ID = 1'b0;
  assign EN_n_ID_EX = 1'b0;
  assign EN_n_EX_M = 1'b0;
  assign EN_n_M_WB = 1'b0;

  // ===========================================================================
  // Remaining (non-registered) signals
  // ===========================================================================

  // IF
  logic [31:0] PC;
  logic [31:0] PCNext, Instr_IF;

  // EX
  logic [1:0]  RS1_FWD, RS2_FWD;
  logic [31:0] D1Fwd_EX, D2Fwd_EX, ALUIn1, ALUIn2, ALUOut_EX;

  // MEM
  logic [31:0] Mem_M, MemAl_M;

  // WB
  logic [31:0] RegData;

  // ===========================================================================
  // IF stage
  // ===========================================================================

  // PC register (Active-low EN tied to 0 in the schematic)
  program_counter u_program_counter(
    .clk(CLK),
    .en(EN_n_PC),
    .rst(CLR_PC),
    .pc_next(PCNext),
    
    .pc(PC)
  );
    
  // Adder: PC + 4
  assign PCNext = PC + 32'd4;

  instruction_mem u_instruction_mem (
    .clk(CLK),            // Not used in design, will be used later with cache possibly
    .rst_n(1'b1),		  // Not used in design, idk why here
    .pc(PC),
    
    .instr(Instr_IF)
  );

  // IF/ID register input
  assign if_id_in.PC    = PC;
  assign if_id_in.Instr = Instr_IF;

  // Update register content at positive clock edge
  always_ff @(posedge CLK) begin
    if (CLR_IF_ID)        if_id_out <= '0;
    else if (!EN_n_IF_ID) if_id_out <= if_id_in;
  end

  // ===========================================================================
  // ID stage
  // ===========================================================================

  assign id_ex_in.RS1Addr = if_id_out.Instr[19:15];
  assign id_ex_in.RS2Addr = if_id_out.Instr[24:20];
  assign id_ex_in.RD      = if_id_out.Instr[11:7];
  assign id_ex_in.PC      = if_id_out.PC;

  control_unit u_control_unit (
    .opcode      (if_id_out.Instr[6:0]),
    .funct3      (if_id_out.Instr[14:12]),
    .funct7      (if_id_out.Instr[31:25]), 
    
    .ALUControl  (id_ex_in.ALUControl),
    .RS1Source   (id_ex_in.RS1Source),
    .RS2Source   (id_ex_in.RS2Source),
    .MemWrite    (id_ex_in.MemWrite),
    .MemRead     (id_ex_in.MemRead),
    .WriteSel    (id_ex_in.WriteSel),
    .Funct3      (id_ex_in.Funct3),
    .WriteEnable (id_ex_in.WriteEnable)
  );

  register_file u_register_file (
    .clk          (CLK),
    .read_addr1   (if_id_out.Instr[19:15]),
    .read_addr2   (if_id_out.Instr[24:20]),
    .write_enable (mem_wb_out.WriteEnable),
    .write_addr   (mem_wb_out.RD),
    .write_data   (RegData),
    
    .read_data1   (id_ex_in.D1),
    .read_data2   (id_ex_in.D2)
  );

  imm_gen u_imm_gen (
    .instr    (if_id_out.Instr),
    .funct3   (if_id_out.Instr[14:12]),			// For potential future use?
    .funct7   (if_id_out.Instr[31:25]),			// 
    
    .imm      (id_ex_in.ImmExt)
  );
  
  // Update register content at positive clock edge
  always_ff @(posedge CLK) begin
    if (CLR_ID_EX)        id_ex_out <= '0;
    else if (!EN_n_ID_EX) id_ex_out <= id_ex_in;
  end

  // ===========================================================================
  // EX stage
  // ===========================================================================

  forwarding_unit u_forwarding_unit (
    .rs1_EX         (id_ex_out.RS1Addr),
    .rs2_EX         (id_ex_out.RS2Addr),
    .rd_MEM         (ex_mem_out.RD),
    .rd_WB          (mem_wb_out.RD),
    .WriteEnable_M  (ex_mem_out.WriteEnable),
    .WriteEnable_WB (mem_wb_out.WriteEnable),
    
    .forward_a      (RS1_FWD),
    .forward_b      (RS2_FWD)
  );

  // Forwarding muxes: 00/default = register file, 01 = ALUOut_M (MEM), 10 = RegData (WB)
  always_comb begin
    case (RS1_FWD)
      2'b01:   D1Fwd_EX = ex_mem_out.ALUOut;
      2'b10:   D1Fwd_EX = RegData;
      default: D1Fwd_EX = id_ex_out.D1;
    endcase

    case (RS2_FWD)
      2'b01:   D2Fwd_EX = ex_mem_out.ALUOut;
      2'b10:   D2Fwd_EX = RegData;
      default: D2Fwd_EX = id_ex_out.D2;
    endcase
  end

  // ALU input muxes
  assign ALUIn1 = id_ex_out.RS1Source ? id_ex_out.PC     : D1Fwd_EX;   // 1 = PC (For AUIPC)
  assign ALUIn2 = id_ex_out.RS2Source ? id_ex_out.ImmExt : D2Fwd_EX;   // 1 = immediate

  alu u_alu (
    .a          (ALUIn1),
    .b          (ALUIn2),
    .op         (id_ex_out.ALUControl),
    
    .result     (ALUOut_EX),
    .zero_flag  (),                 // not used yet (no branch hardware)
    .less_flag  ()                  // not used yet (no branch hardware)
  );

  // EX/MEM register
  assign ex_mem_in.WriteEnable = id_ex_out.WriteEnable;
  assign ex_mem_in.Funct3      = id_ex_out.Funct3;
  assign ex_mem_in.WriteSel    = id_ex_out.WriteSel;
  assign ex_mem_in.MemWrite    = id_ex_out.MemWrite;
  assign ex_mem_in.MemRead     = id_ex_out.MemRead;
  assign ex_mem_in.ALUOut      = ALUOut_EX;
  assign ex_mem_in.D2Fwd       = D2Fwd_EX;
  assign ex_mem_in.RD          = id_ex_out.RD;

  // Update register content at positive clock edge
  always_ff @(posedge CLK) begin
    if (CLR_EX_M)        ex_mem_out <= '0;
    else if (!EN_n_EX_M) ex_mem_out <= ex_mem_in;
  end

  // ===========================================================================
  // MEM stage
  // ===========================================================================

  // rst is tied low
  data_mem u_data_mem (
    .clk       (CLK),
    .rst       (1'b0),
    .funct3    (ex_mem_out.Funct3),
    .addr      (ex_mem_out.ALUOut),
    .wdata     (ex_mem_out.D2Fwd),
    .write_en  (ex_mem_out.MemWrite),
    .read_en   (ex_mem_out.MemRead),				// May be used data when memory is a cache
    
    .rdata     (Mem_M)
  );

  data_aligner u_data_aligner (
    .mem_data     (Mem_M),
    .funct3       (ex_mem_out.Funct3),
    .addr_lsb     (ex_mem_out.ALUOut[1:0]),
    .mem_aligned  (MemAl_M)
  );

  // MEM/WB register
  assign mem_wb_in.WriteEnable = ex_mem_out.WriteEnable;
  assign mem_wb_in.WriteSel    = ex_mem_out.WriteSel;
  assign mem_wb_in.ALUOut      = ex_mem_out.ALUOut;
  assign mem_wb_in.MemAl       = MemAl_M;
  assign mem_wb_in.RD          = ex_mem_out.RD;

  // Update register content at positive clock edge
  always_ff @(posedge CLK) begin
    if (CLR_M_WB)        mem_wb_out <= '0;
    else if (!EN_n_M_WB) mem_wb_out <= mem_wb_in;
  end

  // ===========================================================================
  // WB stage
  // ===========================================================================

  assign RegData = mem_wb_out.WriteSel ? mem_wb_out.MemAl : mem_wb_out.ALUOut;   // 1 = memory load data

endmodule