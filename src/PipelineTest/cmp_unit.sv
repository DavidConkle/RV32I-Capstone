import rv32i_pkg ::*;

module cmp_unit (
    input logic z_flag,
    input logic less_flag,
    input logic less_unsigned_flag,
    input cmp_ops comparison,

    output logic cmp_true
);

    always_comb begin
        case(comparison)
            BEQ: cmp_true = z_flag;
            BNE: cmp_true = ~z_flag;
            BLT: cmp_true = less_flag;
            BGE: cmp_true = ~less_flag;
            BLTU: cmp_true = less_unsigned_flag;
            BGEU: cmp_true = ~less_unsigned_flag;
            default: cmp_true = 1'b0
        endcase
    end
endmodule