`timescale 1ns / 1ps

module register_file_tb;           

    // Declare Signals
   logic        clk;
   logic [4:0]  read_addr1;
   logic [4:0]  read_addr2;
   logic        write_enable;
   logic [4:0]  write_addr;
   logic [31:0] write_data;
   
   logic [31:0] read_data1;
   logic [31:0] read_data2;

    // Instantiate DUT
    register_file dut(
        .clk(clk),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),

        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock signal
    initial clk = 0;
    always #5 clk = ~clk;

    // Initialize inputs
    initial begin

        write_enable = 0;
        read_addr1   = 5'd0;
        read_addr2   = 5'd0;
        write_addr   = 5'd0;
        write_data   = 32'd0;

        // Test 1: both ports should read x0 as zero
        #10;

        if (read_data1 != 32'd0 || read_data2 != 32'd0)
            $fatal(1, "Test 1 failed");

        // Test 2: write 5 to x2 and read back
        @(negedge clk);
        write_enable = 1;
        write_addr = 5'd2;
        write_data = 32'd5;
        read_addr1 = 5'd2;

        #10;

        if(read_data1 != 32'd5)
            $fatal(1, "Test 2 failed");

        write_enable = 0;

        // Test 3: write 9 to x3 and read back
        @(negedge clk);
        write_enable = 1;
        write_addr = 5'd3;
        write_data = 32'd9;
        read_addr2 = 5'd3;

        #10;

        if(read_data2 != 32'd9 || read_data1 != 32'd5)
            $fatal(1, "Test 3 failed");

        write_enable = 0;

        // Test 4: write 10 to x2 while disabled
        @(negedge clk);
        write_enable = 0;
        write_addr = 5'd2;
        write_data = 32'd10;
        read_addr1 = 5'd2;

        #10;

        if(read_data1 != 32'd5)
            $fatal(1, "Test 4 failed");
        
        write_enable = 0;

        // Test 5: write to x0 ignored
        @(negedge clk);
        write_enable = 1;
        write_addr = 5'd0;
        write_data = 32'd22;
        read_addr1 = 5'd0;

        #10;

        if(read_data1 != 32'd0)
            $fatal(1, "Test 5 failed");
     
        write_enable = 0;


        // Test 6: changing register value
        @(negedge clk);
        write_enable = 1;
        write_addr = 5'd2;
        write_data = 32'd11;
        read_addr1 = 5'd2;
        read_addr2 = 5'd3;

        #10;

        if(read_data1 != 32'd11 || read_data2 != 32'd9)
            $fatal(1, "Test 6 failed");

        write_enable = 0;


        $display("All tests passed ===================================================");
        $finish;
    end
        
endmodule