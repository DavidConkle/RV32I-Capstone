'timescale 1ns/1ps

module tb_test(
    logic clk,
    logic rst
);
    top dut(
        .clk(clk),
        .rst(rst)
    )

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;

        #200;
        $finish;
    end 

    initial begin 
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_test);
    end

endmodule