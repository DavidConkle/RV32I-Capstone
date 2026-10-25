// pipeline register struct definitions

// instruction fetch/decode pipeline register
typedef struct packed {
    logic [31:0] pc;
    logic [31:0] inst;
} if_id_reg_t;

// ID/EX pipeline register
typedef struct packed {
    // data pathways
    logic [31:0] pc;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;
    
    // instruction fields for forwarding and decoding
    logic [4:0]  rs1; // 5 bit source register 1
    logic [4:0]  rs2; // 5 bit source register 2
    logic [4:0]  rd;  // 5 bit destination register
    logic [2:0]  funct3; // 3 bit function code
    logic [6:0]  funct7; // 7 bit function code
    
    // control signals
    logic        reg_write;
    logic        mem_to_reg;
    logic        mem_write;
    logic        mem_read;
    logic        branch;
    logic [1:0]  alu_op;
    logic        alu_src;
} id_ex_reg_t;

// EX/MEM pipeline register
typedef struct packed {
    logic [31:0] pc_target;    // calculated branch target
    logic [31:0] alu_result;
    logic [31:0] rs2_data;     // data to write to memory
    logic [4:0]  rd;           // destination register
    logic        reg_write;
    logic        mem_to_reg;
    logic        mem_write;
    logic        mem_read;
    logic        branch_taken; // 1 if branch condition met and is a branch instr
} ex_mem_reg_t;

// MEM/WB pipeline register
typedef struct packed {
    logic [31:0] alu_result;
    logic [31:0] mem_data;     // data read from memory
    logic [4:0]  rd;
    logic        reg_write;
    logic        mem_to_reg;
} mem_wb_reg_t;



// top-level datapath module
module top (
    input  logic clk,
    input  logic rst
);

    // instantiate pipeline registers
    if_id_reg_t if_id_reg, if_id_next;
    id_ex_reg_t id_ex_reg, id_ex_next;
    ex_mem_reg_t ex_mem_reg, ex_mem_next;
    mem_wb_reg_t mem_wb_reg, mem_wb_next;

    // instr. fetch stage wires
    logic [31:0] if_pc_current, if_pc_next, if_inst;
    
    // instr. decode stage wires
    logic [31:0] id_rs1_data, id_rs2_data, id_imm;
    logic        id_reg_write, id_mem_to_reg, id_mem_write, id_mem_read, id_branch, id_alu_src;
    logic [1:0]  id_alu_op;

    // writeback stage wires
    logic        wb_reg_write;
    logic [4:0]  wb_rd;
    logic [31:0] wb_write_data;

    // need buffers between pipeline stages
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset all pipeline registers to 0
            if_id_reg <= '0;
            id_ex_reg <= '0;
            ex_mem_reg <= '0;
            mem_wb_reg <= '0;
        end else begin
            // advance pipeline state
            if_id_reg <= if_id_next;
            id_ex_reg <= id_ex_next;
            ex_mem_reg <= ex_mem_next;
            mem_wb_reg <= mem_wb_next;
        end
    end



    // instruction fetch combinational logic

    logic [31:0] if_pc_plus_4;
    
    // PC increment
    assign if_pc_plus_4 = if_pc_current + 32'd4;

    // next-PC MUX: selects either branch target (from EX/MEM) or PC+4
    assign if_pc_next = (ex_mem_reg.branch_taken) ? ex_mem_reg.pc_target : if_pc_plus_4;

    // instantiate program counter
    program_counter pc_reg (
        .clk(clk),
        .en(1'b1),              // enable tied high for continuous fetching (update later for stall logic)
        .rst(rst),
        .pc_next(if_pc_next),   // routed from next-PC MUX
        .pc(if_pc_current)      // output to instruction memory and pipeline register
    );

    // instantiate instruction memory
    instructin_mem imem (       // "instructin" matches spelling in the module definition
        .clk(clk),
        .rst_n(~rst),           // inverted reset since this module expects active-low (rst_n)
        .pc(if_pc_current),     // from PC
        .instr(if_inst)         // outputs 32 bit instruction to the IF/ID pipeline register
    );

    // load IF/ID next-state struct
    always_comb begin
        if_id_next.pc   = if_pc_current;
        if_id_next.inst = if_inst;
    end



    // instruction decode combinational logic
    
    // instantiate immediate generator
    imm_gen ig (
        .instr(if_id_reg.inst), // 32-bit instruction from the IF/ID register
        .imm(id_imm)            // decoded 32 bit immediate value
    );

    // instantiate register file
    // note: write_enable, write_addr, and write_data MUST be routed from final WB pipeline stage, not the current instr.
    register_file reg_file (
        .clk(clk),
        .read_addr1(if_id_reg.inst[19:15]),
        .read_addr2(if_id_reg.inst[24:20]),
        .write_enable(wb_reg_write),         // control signal fed back from WB stage
        .write_addr(wb_rd),                  // destination register fed back from WB stage
        .write_data(wb_write_data),          // final computed data fed back from WB stage
        .read_data1(id_rs1_data),            // output data 1 routed to ID/EX struct
        .read_data2(id_rs2_data)             // output data 2 routed to ID/EX struct
    );

    // instantiate control unit
    // decodes instruction fields to generate datapath control signals
    control_unit ctrl_unit (
        .opcode(if_id_reg.inst[6:0]),        // 7 bit opcode
        .funct3(if_id_reg.inst[14:12]),      // 3 bit function code
        .funct7(if_id_reg.inst[31:25]),      // 7 bit function code
        .alu_src(id_alu_src),                // selects between rs2 or immediate for ALU operand b
        .alu_op(id_alu_op),
        .branch(id_branch),                  
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .reg_write(id_reg_write),
        .mem_to_reg(id_mem_to_reg)
    );

    // load ID/EX next-state struct
    always_comb begin
        id_ex_next.pc         = if_id_reg.pc;
        id_ex_next.rs1_data   = id_rs1_data;
        id_ex_next.rs2_data   = id_rs2_data;
        id_ex_next.imm        = id_imm;
        
        // get standard RV32I fields from buffered instr.
        id_ex_next.rs1        = if_id_reg.inst[19:15];
        id_ex_next.rs2        = if_id_reg.inst[24:20];
        id_ex_next.rd         = if_id_reg.inst[11:7];
        id_ex_next.funct3     = if_id_reg.inst[14:12];
        id_ex_next.funct7     = if_id_reg.inst[31:25];
        
        // assign control signals
        id_ex_next.reg_write  = id_reg_write;
        id_ex_next.mem_to_reg = id_mem_to_reg;
        id_ex_next.mem_write  = id_mem_write;
        id_ex_next.mem_read   = id_mem_read;
        id_ex_next.branch     = id_branch;
        id_ex_next.alu_op     = id_alu_op;
        id_ex_next.alu_src    = id_alu_src;
    end

    

    // execute stage

    // ALU input/output wires
    logic [31:0] ex_alu_operand_a;
    logic [31:0] ex_alu_operand_b;
    logic [31:0] ex_alu_result;
    logic        ex_alu_zero;
    logic        ex_alu_less;

    // operand a is read_data1 from register file (ignoring forwarding for now)
    assign ex_alu_operand_a = id_ex_reg.rs1_data;

    // operand b MUX
    // 0: route read_data2 from register file (R-type instructions)
    // 1: route sign-extended immediate (I-type instructions)
    assign ex_alu_operand_b = (id_ex_reg.alu_src) ? id_ex_reg.imm : id_ex_reg.rs2_data;

    // instantiate ALU
    alu main_alu (
        .a(ex_alu_operand_a),
        .b(ex_alu_operand_b),
        .alu_op(id_ex_reg.alu_op),
        .result(ex_alu_result),
        .zero(ex_alu_zero),
        .less(ex_alu_less)
    );

    // branch condition evaluation logic
    logic ex_branch_condition_met;
    
    always_comb begin
        case (id_ex_reg.funct3)
            3'b000: ex_branch_condition_met = ex_alu_zero;           // BEQ
            3'b001: ex_branch_condition_met = ~ex_alu_zero;          // BNE
            3'b100: ex_branch_condition_met = ex_alu_less;           // BLT
            3'b101: ex_branch_condition_met = ~ex_alu_less;          // BGE
            3'b110: ex_branch_condition_met = ex_alu_less;           // BLTU
            3'b111: ex_branch_condition_met = ~ex_alu_less;          // BGEU
            default: ex_branch_condition_met = 1'b0;
        endcase
    end

    // load EX/MEM next-state struct
    always_comb begin
        ex_mem_next.pc_target    = id_ex_reg.pc + id_ex_reg.imm;
        ex_mem_next.alu_result   = ex_alu_result;
        ex_mem_next.rs2_data     = id_ex_reg.rs2_data;
        ex_mem_next.rd           = id_ex_reg.rd;
        ex_mem_next.reg_write    = id_ex_reg.reg_write;
        ex_mem_next.mem_to_reg   = id_ex_reg.mem_to_reg;
        ex_mem_next.mem_write    = id_ex_reg.mem_write;
        ex_mem_next.mem_read     = id_ex_reg.mem_read;
        
        // final branch decision: branch instruction AND condition met
        ex_mem_next.branch_taken = id_ex_reg.branch & ex_branch_condition_met;
    end



    // memory combinational logic
    
    logic [31:0] mem_read_data;

    // instantiate data memory
    // (Ensure the module name and ports match your actual data memory file)
    data_memory dmem (
        .clk(clk),
        .mem_write(ex_mem_reg.mem_write),
        .mem_read(ex_mem_reg.mem_read),
        .addr(ex_mem_reg.alu_result),      // ALU calculates memory address
        .write_data(ex_mem_reg.rs2_data),  // data to store
        .read_data(mem_read_data)
    );

    // load MEM/WB next-state struct
    always_comb begin
        mem_wb_next.alu_result = ex_mem_reg.alu_result;
        mem_wb_next.mem_data   = mem_read_data;
        mem_wb_next.rd         = ex_mem_reg.rd;
        mem_wb_next.reg_write  = ex_mem_reg.reg_write;
        mem_wb_next.mem_to_reg = ex_mem_reg.mem_to_reg;
    end



    // writeback combinational logic
    
    // drive  writeback wires that connect back to the register file
    assign wb_reg_write = mem_wb_reg.reg_write;
    assign wb_rd        = mem_wb_reg.rd;

    // memory to register MUX
    // 0: route ALU result to destination register
    // 1: route memory read data to destination register
    assign wb_write_data = (mem_wb_reg.mem_to_reg) ? mem_wb_reg.mem_data : mem_wb_reg.alu_result;

endmodule