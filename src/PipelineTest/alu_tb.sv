`timescale 1ns/1ps

import rv32i_pkg::*;

module alu_tb;
    logic [31:0] a, b, result;
    logic        zero_flag, less_flag;
    alu_ops      op;

    alu uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero_flag(zero_flag),
        .less_flag(less_flag)
    );

    task run_test(
        input string       op_name,
        input alu_ops      test_op,
        input logic [31:0] in_a,
        input logic [31:0] in_b
    );
        begin
            a = in_a;
            b = in_b;
            op = test_op;
            #10; // wait for combinational logic to settle
            $display("op: %s, a: %h, b: %h, result: %h, zero_flag: %b, less_flag: %b",
                     op_name, a, b, result, zero_flag, less_flag);
        end
    endtask

    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, alu_tb);

        // arithmetic ops (testing normal math and zero_flag)
        run_test("ADD",  ADD,  32'd15,          32'd10);          // 15 + 10 = 25
        run_test("SUB",  SUB,  32'd20,          32'd20);          // 20 - 20 = 0 (zero=1)

        // bitwise conditional logic
        run_test("AND",  AND,  32'hFF00_FF00,   32'h0F0F_0F0F);   // 0x0F000F00
        run_test("OR",   OR,   32'hFF00_0000,   32'h0000_00FF);   // 0xFF0000FF
        run_test("XOR",  XOR,  32'hAAAA_AAAA,   32'hFFFF_FFFF);   // 0x55555555

        // shift ops
        run_test("SLL",  SLL,  32'h0000_0001,   32'd4);           // 0x00000010
        run_test("SRL",  SRL,  32'h8000_0000,   32'd4);           // 0x08000000 (fills with 0)
        run_test("SRA",  SRA,  32'h8000_0000,   32'd4);           // 0xF8000000 (sign-extends 1)

        // comparison ops (also tests less_flag)
        run_test("SLT",  SLT,  -32'd5,          32'd3);           // -5 < 3 is true  (result=1, less=1)
        run_test("SLTU", SLTU, -32'd5,          32'd3);           // 0xFFFFFFFB < 3 is false (result=0, less=0)

        $finish;
    end
endmodule