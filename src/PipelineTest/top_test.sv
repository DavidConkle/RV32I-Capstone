`timescale 1ns/1ps
 
module top_test;
    logic clk;
    logic rst;
 
    top_new dut (
        .clk(clk),
        .rst(rst)
    );
 
    // Clock: 10 ns period
    initial clk = 1'b0;
    always #5 clk = ~clk;
 
    // Reset and run
    initial begin
        rst = 1'b1;
        #22;                 // release away from a clock edge
        rst = 1'b0;
 
        #300;                // enough cycles for the program + pipeline drain
 
        // Self-check. Adjust "regs" to your register file's array name.
        // Program: addi x1,x0,5 ; addi x2,x0,7 ; add x3,x1,x2
        if (dut.reg_file.regs[1] !== 32'd5)  $error("x1 = %0d, expected 5",  dut.reg_file.regs[1]);
        if (dut.reg_file.regs[2] !== 32'd7)  $error("x2 = %0d, expected 7",  dut.reg_file.regs[2]);
        if (dut.reg_file.regs[3] !== 32'd12) $error("x3 = %0d, expected 12", dut.reg_file.regs[3]);
        else                                  $display("PASS: forwarding test");
 
        $finish;
    end
 
    // Safety timeout in case something hangs
    initial begin
        #5000;
        $error("Timeout");
        $finish;
    end
 
    // Waveforms
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_test);
    end
endmodule