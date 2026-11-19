module tb_test(
    logic clk,
    logic rst
);
    top dut(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        
        forever #5 clk = ~clk;

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
