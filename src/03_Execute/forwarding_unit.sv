module forwarding_unit (
    input  logic [4:0] rs1_EX,
    input  logic [4:0] rs2_EX,
    input  logic [4:0] rd_MEM,
    input  logic [4:0] rd_WB,
    input  logic       WriteEnable_M,
    input  logic       WriteEnable_WB,

    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin
        // Operand A
        if (WriteEnable_M && (rd_MEM != 5'd0) && (rd_MEM == rs1_EX))
            forward_a = 2'b10;
        else if (WriteEnable_WB && (rd_WB != 5'd0) && (rd_WB == rs1_EX))
            forward_a = 2'b01;
        else
            forward_a = 2'b00;

        // Operand B
        if (WriteEnable_M && (rd_MEM != 5'd0) && (rd_MEM == rs2_EX))
            forward_b = 2'b10;
        else if (WriteEnable_WB && (rd_WB != 5'd0) && (rd_WB == rs2_EX))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end

endmodule