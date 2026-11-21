import rv_pkg::*;

typedef struct packed {
    logic [31:0] pc;
    logic [31:0] inst;
} f_d_reg;

// ID/EX pipeline register
typedef struct packed {
    logic write_en;
    logic [2:0] funct3;
    
    logic branch;
    logic jump;
    logic jalr;

    logic mem_read;
    logic mem_write;
    logic alu_src1;
    logic alu_src2;
    alu_ops alu_ctl;
    cmp_ops alu_cmp;
    

    logic [31:0] pc;
    logic [31:0] data1;
    logic [31:0] data2;
    logic [31:0] imm;

    logic [4:0] dest;
    logic [4:0] rs1_num;
    logic [4:0] rs2_num;

} d_e_reg;

typedef struct packed{
    logic write_en;
    logic [2:0] funct3;
    logic mem_read;
    logic mem_write;

    logic [31:0] alu_out;
    logic [31:0] store_data;
    logic [4:0] dest;
} e_m_reg;

typedef struct packed{
    logic write_en;
    logic [31:0] data;
    logic [4:0] dest;
} m_w_reg;


module top_new(
    input logic clk,
    input logic rst
);
    //Wires connecting directly between modules
    //Fetch
    wire logic[31:0] pc_next_val;
    wire logic[31:0] pc_imem;

    //Decode
    logic [31:0] rf_data1, rf_data2;

    //Execute
    //logic [31:0] fwd_a, fwd_b;
    logic [31:0] alu_in1, alu_in2, alu_out;
    logic [1:0] forward_a, forward_b;
    logic zflag, lflag, luflag;
    logic cmp_true_w;
    logic take_jump;
    logic [31:0] jump_target;
    logic flush;

    //Writeback
    logic [4:0] wb_dest;
    logic wb_write_en;
    logic [31:0] wb_data;


    //Pipeline registers
    f_d_reg f_d_in, f_d_out;
    d_e_reg d_e_in, d_e_out;
    e_m_reg e_m_in, e_m_out;
    m_w_reg m_w_in, m_w_out;


    //Register updates
    assign flush = take_jump;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // reset all pipeline registers to 0
            f_d_out <= '0;
            d_e_out <= '0;
            e_m_out <= '0;
            m_w_out <= '0;
        end else begin
            // flush on IF/ID and ID/EX if a branch/jump is taken
            f_d_out  <= flush ? '0 : f_d_in;
            d_e_out  <= flush ? '0 : d_e_in;
            e_m_out <= e_m_in;
            m_w_out <= m_w_in;
        end
    end
    
    //Fetch
    assign pc_next_val = (take_jump ? jump_target : (pc_imem + 4));

    program_counter pc(
        .clk(clk),
        .en(1'b1),
        .rst(rst),
        .pc_next(pc_next_val),

        .pc(pc_imem)
    );

    instruction_mem imem(
        .clk(clk),
        .rst_n(~rst),
        .pc(pc_imem),

        .instr(f_d_in.inst)
    );


    
    assign f_d_in.pc = pc_imem;

    //DECODE
    imm_gen imm_val(
        .instr(f_d_out.inst),

        .imm(d_e_in.imm)
    );

    register_file reg_file(
        .clk(clk),
        .read_addr1(f_d_out.inst[19:15]),
        .read_addr2(f_d_out.inst[24:20]),

        //Should be from write back stage, for now just using memory stage
        .write_enable(wb_write_en),
        .write_addr(wb_dest),
        .write_data(wb_data),

        .read_data1(rf_data1),
        .read_data2(rf_data2)
    );
    
    //Writeback
    assign d_e_in.data1 = (wb_write_en && wb_dest != 5'b0 && wb_dest == f_d_out.inst[19:15]) ? wb_data : rf_data1;
    assign d_e_in.data2 = (wb_write_en && wb_dest != 5'b0 && wb_dest == f_d_out.inst[24:20]) ? wb_data : rf_data2;
    
    assign d_e_in.pc = f_d_out.pc;
    assign d_e_in.funct3 = f_d_out.inst[14:12];
    assign d_e_in.dest = f_d_out.inst[11:7];
    assign d_e_in.rs1_num = f_d_out.inst[19:15];
    assign d_e_in.rs2_num = f_d_out.inst[24:20];
    
    cmp_ops ctl_cmp_op_w;
    assign d_e_in.alu_cmp = ctl_cmp_op_w;

    control_unit ctl_unit(
        .opcode(f_d_out.inst[6:0]),
        .funct3(f_d_out.inst[14:12]),
        .funct7(f_d_out.inst[31:25]),

        .alu_op(d_e_in.alu_ctl),
        .alu_src1(d_e_in.alu_src1),
        .alu_src2(d_e_in.alu_src2),
        .branch(d_e_in.branch),
        .cmp_op(ctl_cmp_op_w),
        .jump(d_e_in.jump),
        .jalr(d_e_in.jalr),
        .write_enable(d_e_in.write_en)
    );

    


    cmp_unit compare(
        .zero_flag(zflag),
        .less_flag(lflag),
        .less_unsigned_flag(luflag),
        .comparison(d_e_out.alu_cmp),

        .cmp_true(cmp_true_w)
    );

    //EXECUTE
    logic [31:0] alu_operand2;

    // ALU input mux 1 (Forwarding A)
    always_comb begin
        case (forward_a)
            2'b01:   alu_in1 = e_m_out.alu_out;
            2'b10:   alu_in1 = wb_data; 
            default: alu_in1 = d_e_out.data1;
        endcase        
    end

    // ALU input mux 2, Forwarding B, and Immediate selection
    always_comb begin
        case (forward_b)
            2'b01:   alu_operand2 = e_m_out.alu_out;
            2'b10:   alu_operand2 = wb_data; 
            default: alu_operand2 = d_e_out.data2; // FIXED: Assigned to alu_operand2 (prevents latches)
        endcase

        // FIXED: Handled inside always_comb to avoid multiple drivers on alu_in2, 
        // and corrected the struct field typo from alusrc2 to alu_src2.
        alu_in2 = d_e_out.alu_src2 ? d_e_out.imm : alu_operand2;
    end

    assign jump_target = d_e_out.jalr ? (alu_in1 + d_e_out.imm) : (d_e_out.pc + d_e_out.imm);
    assign take_jump   = (d_e_out.branch & cmp_true_w) | d_e_out.jump | d_e_out.jalr;

    alu alu(
        .a(alu_in1),
        .b(alu_in2),
        .op(d_e_out.alu_ctl),

        .result(alu_out),
        .zero_flag(zflag),
        .less_flag(lflag),
        .less_unsigned_flag(luflag)
    );

    forwarding_unit forward(
        .rs1_EX(d_e_out.rs1_num),
        .rs2_EX(d_e_out.rs2_num),
        .rd_MEM(e_m_out.dest),
        .rd_WB(wb_dest),
        .WriteEnable_M(e_m_out.write_en),
        .WriteEnable_WB(wb_write_en),

        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    //Memory
    //Junk for now, just placeholder
    always_comb begin
        e_m_in.write_en  = d_e_out.write_en;
        e_m_in.funct3    = d_e_out.funct3;
        e_m_in.mem_read  = d_e_out.mem_read;
        e_m_in.mem_write = d_e_out.mem_write;
        e_m_in.alu_out   = (d_e_out.jump | d_e_out.jalr) ? (d_e_out.pc + 32'd4) : alu_out;
        e_m_in.store_data = alu_operand2; // FIXED: Replaced undriven fwd_b with proper forwarded operand 2
        e_m_in.dest      = d_e_out.dest;
    end

    always_comb begin
        m_w_in.write_en = e_m_out.write_en;
        m_w_in.data = e_m_out.alu_out;
        m_w_in.dest = e_m_out.dest;
    end
    //Write Back
   assign wb_write_en = m_w_out.write_en;
   assign wb_dest = m_w_out.dest;
   assign wb_data = m_w_out.data;

endmodule
