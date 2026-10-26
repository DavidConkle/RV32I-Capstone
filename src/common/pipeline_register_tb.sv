module pipeline_register_tb;  

    // Declare Signals
   logic         clk;
   logic         reset;
   logic [31:0]  data_in;

   logic [31:0]  data_out;

    // Instantiate DUT
    pipeline_register dut(
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock signal
    initial clk = 0;
    always #5 clk = ~clk;

    // Initialize inputs
    initial begin

        // test 1: reset register to 0
        reset = 1;
        data_in = 32'd10;
        #1;                     // async reset acts immediately

        // verify output has been reset
        if(data_out !== 32'b0) 
            $fatal(1, "Test 1 failed");

        // test 2: on a clock edge with reset low get data_in
        reset = 0;
        data_in = 32'd25;
        @(posedge clk);
        #1;                     // delay to allow signal to settle

        if(data_out !== 32'd25)
            $fatal(1, "Test 2 failed");

        // test 3: on next edge get next new value from data_in
        reset = 0;
        data_in = 32'd12;
        @(posedge clk);
        #1;

        if(data_out !== 32'd12)
            $fatal(1, "Test 3 failed");
        
        // test 4: data value is held when data_in changes between edges
        reset = 0;
        data_in = 32'd22;       // data changed without rising edge

        if(data_out !== 32'd12)
            $fatal(1, "Test 4 failed");
        

    $display("All tests passed ===================================================");
    $finish;
        
    end          
endmodule