import rv32i_pkg::*;		// Import package

module top_tb();
  
  // Declare signals
  logic CLK = 1'b0;
  logic RST = 1'b1;

  // Instantiate the DUT
  rv32i_top dut(
    .CLK(CLK),
    .RST(RST)
  );
  
  // Dump the waveform
  initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
  end
  
  // Clock with period of 10 time units
  always #5 CLK = ~CLK;
  
  // Simple directed testing
  // NOTE: Instruction_mem file needs to be modified to select instructions that are loaded, this should be
  // changed later so that it can be chosen within the testbench
  initial begin
    // Reset the processor, advance one clock edge, then set back to low so program can begin
    RST = 1'b1;
    #10
    RST = 1'b0;
    
    //  Advance (time units/10) clock cycles, then display register values and finish
    #200	// 20 clock cycles
    
    $display("============================");
    
    $display("%h", dut.u_register_file.registers[1]);
    $display("%h", dut.u_register_file.registers[2]);
    $display("%h", dut.u_register_file.registers[3]);
    $display("%h", dut.u_register_file.registers[4]);
    $display("%h", dut.u_register_file.registers[5]);
    $display("%h", dut.u_register_file.registers[6]);
    $display("%h", dut.u_register_file.registers[7]);
    $display("%h", dut.u_register_file.registers[8]);
    $display("%h", dut.u_register_file.registers[9]);
    $display("%h", dut.u_register_file.registers[10]);
    $display("%h", dut.u_register_file.registers[11]);
    $display("%h", dut.u_register_file.registers[12]);
    $display("%h", dut.u_register_file.registers[13]);
   
    
    $display("Test finished");
    $finish;
  end
  
endmodule