// Simple Directed testing of the data aligner
module data_aligner_tb();
  
  // Declare signals
  logic [31:0] mem_data;
  logic [2:0] funct3;
  logic [1:0] addr_lsb;
  logic [31:0] mem_aligned;

  // Instantiate the DUT
  data_aligner dut(
    .mem_data(mem_data),
    .funct3(funct3),
    .addr_lsb(addr_lsb),
    .mem_aligned(mem_aligned)
  );
  
  // Dump the waveform
  initial begin
    $dumpfile("data_aligner_tb.vcd");
    $dumpvars(0, data_aligner_tb);
  end
  
  // Simple directed testing for a single mem_data value
  initial begin
    // Set memdata value
    mem_data = 32'h7EAD_BEEF;
    
    // Test for LB =============================================
   
    // Test 1, Load byte sign extend (LB)
    funct3 = 3'b000;
    addr_lsb = 2'b00;
    #1;
    if(mem_aligned !== 32'hFFFF_FFEF)
      $fatal(1, "Test 1 failed: got %h, expected FFFF_FFEF", mem_aligned);
    
    #1;
    // Test 2, Load byte sign extend (LB)
    funct3 = 3'b000;
    addr_lsb = 2'b01;
    #1;
    if(mem_aligned !== 32'hFFFF_FFBE)
      $fatal(1, "Test 2 failed: got %h, expected FFFF_FFBE", mem_aligned);
    
    #1;
    // Test 3, Load byte sign extend (LB)
    funct3 = 3'b000;
    addr_lsb = 2'b10;
    #1;
    if(mem_aligned !== 32'hFFFF_FFAD)
      $fatal(1, "Test 3 failed: got %h, expected FFFF_FFAD", mem_aligned);
    
    #1;
    // Test 4, Load byte sign extend (LB)
    funct3 = 3'b000;
    addr_lsb = 2'b11;
    #1;
    if(mem_aligned !== 32'h0000_007E)
      $fatal(1, "Test 4 failed: got %h, expected 0000_007E", mem_aligned);
    
    // Test for LH =============================================
    
    #1;
    // Test 5, Load Half-word sign extend (LH)
    funct3 = 3'b001;
    addr_lsb = 2'b00;
    #1;
    if(mem_aligned !== 32'hFFFF_BEEF)
      $fatal(1, "Test 5 failed: got %h, expected FFFF_BEEF", mem_aligned);
    
    #1;
    // Test 6, Load Half-word sign extend (LH)
    funct3 = 3'b001;
    addr_lsb = 2'b10;
    #1;
    if(mem_aligned !== 32'h0000_7EAD)
      $fatal(1, "Test 6 failed: got %h, expected 0000_7EAD", mem_aligned);
    
    // Test for LW =============================================
    
    #1;
    // Test 7, Load Word (LW)
    funct3 = 3'b010;
    addr_lsb = 2'b00;
    #1;
    if(mem_aligned !== 32'h7EAD_BEEF)
      $fatal(1, "Test 7 failed: got %h, expected 7EAD_BEEF", mem_aligned);
    
    // Test for LBU =============================================
   
    // Test 8, Load byte unsigned (LBU)
    funct3 = 3'b100;
    addr_lsb = 2'b00;
    #1;
    if(mem_aligned !== 32'h0000_00EF)
      $fatal(1, "Test 8 failed: got %h, expected 0000_00EF", mem_aligned);
    
    #1;
    // Test 9, Load byte unsigned (LBU)
    funct3 = 3'b100;
    addr_lsb = 2'b01;
    #1;
    if(mem_aligned !== 32'h0000_00BE)
      $fatal(1, "Test 9 failed: got %h, expected 0000_00BE", mem_aligned);
    
    #1;
    // Test 10, Load byte unsigned (LBU)
    funct3 = 3'b100;
    addr_lsb = 2'b10;
    #1;
    if(mem_aligned !== 32'h0000_00AD)
      $fatal(1, "Test 10 failed: got %h, expected 0000_00AD", mem_aligned);
    
    #1;
    // Test 11, Load byte unsigned (LBU)
    funct3 = 3'b100;
    addr_lsb = 2'b11;
    #1;
    if(mem_aligned !== 32'h0000_007E)
      $fatal(1, "Test 11 failed: got %h, expected 0000_007E", mem_aligned);
    
    // Test for LHU =============================================
    
    #1;
    // Test 12, Load Half-word unsigned (LHU)
    funct3 = 3'b101;
    addr_lsb = 2'b00;
    #1;
    if(mem_aligned !== 32'h0000_BEEF)
      $fatal(1, "Test 12 failed: got %h, expected 0000_BEEF", mem_aligned);
    
    #1;
    // Test 13, Load Half-word unsigned (LHU)
    funct3 = 3'b101;
    addr_lsb = 2'b10;
    #1;
    if(mem_aligned !== 32'h0000_7EAD)
      $fatal(1, "Test 13 failed: got %h, expected 0000_7EAD", mem_aligned);
    
    
    $display("All tests passed ===================================================");
    $finish;
  end
  
endmodule