// Simple Directed testing of the program counter
module program_counter_tb();
  
  // Declare signals
  reg clk;
  reg en;
  reg rst;
  reg [31:0] pc_next;
  wire [31:0] pc;

  // Instantiate the DUT
  program_counter dut(
    .clk(clk),
    .en(en),
    .rst(rst),
    .pc_next(pc_next),
    .pc(pc)
  );
  
  // Create the clk signal with a period of 10 time units
  initial clk = 0;
  always #5 clk = ~ clk;
  
  // Dump the waveform
  initial begin
    $dumpfile("program_counter_tb.vcd");
    $dumpvars(0, program_counter_tb);
  end
  
  // Drive input signals
  initial begin
    
    // Test 1: PC Updates address when enabled
    en = 1;
    rst = 0;
    pc_next = 32'h0000_0004;
    #10
    if(pc != 32'h0000_0004)
      $fatal(1, "Test 1 failed");
    
    // Test 2: PC retains value when enable is low
    en = 0;
    rst = 0;
    pc_next = 32'h0000_0003;
    #10
    if(pc != 32'h0000_0004)
      $fatal(1, "Test 2 failed");
    
    // Test 3: PC Resets value when reset is high and enable is low
    rst = 1;
    en = 0;
    pc_next = 32'h0000_0003;
    #10
    if(pc != 32'h0000_0000)
      $fatal(1, "Test 3 failed");
    
    // Test 4: PC Updates value after a reset where enable is low
    rst = 0;
    en = 1;
    pc_next = 32'h0000_0008;
    #10
    if(pc != 32'h0000_0008)
      $fatal(1, "Test 4 failed");
    
    // Test 5: PC Resets value when reset is high and enable is high
    rst = 1;
    en = 1;
    pc_next = 32'h0000_0003;
    #10
    if(pc != 32'h0000_0000)
      $fatal(1, "Test 5 failed");
    
    // Test 6: PC Updates value after a reset where enable is high
    rst = 0;
    en = 1;
    pc_next = 32'h0000_000C;
    #10
    if(pc != 32'h0000_000C)
      $fatal(1, "Test 6 failed");
    
    $display("All tests passed ===================================================");
    $finish;
  end
  
endmodule
