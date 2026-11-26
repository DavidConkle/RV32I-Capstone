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
  
  // Load a hex file into the instruction memory of the CPU
  /*  Instruction file formating
    -Use hex and one instruction per line, do not add a prefix or radix to the hex value
    -Comments are ignored if they start with //, can be used after hex or on a separate line
  */
  initial begin
    static string file = "instrStoreLoad.hex";
    $readmemh(file, dut.u_instruction_mem.instr_mem); //Load instructions from file instruction memory
  end
  
  // Simple directed testing
  initial begin
    // Reset the processor, advance one clock edge, then set back to low so program can begin
    RST = 1'b1;
    #10
    RST = 1'b0;
    
    //  Advance (time units/10) clock cycles, then display register values and finish
    #500	// 50 clock cycles
    
    $display("===================== Print all register values ======================");
    
    $display("X1: %h", dut.u_register_file.registers[1]);
    $display("X2: %h", dut.u_register_file.registers[2]);
    $display("X3: %h", dut.u_register_file.registers[3]);
    $display("X4: %h", dut.u_register_file.registers[4]);
    $display("X5: %h", dut.u_register_file.registers[5]);
    $display("X6: %h", dut.u_register_file.registers[6]);
    $display("X7: %h", dut.u_register_file.registers[7]);
    $display("X8: %h", dut.u_register_file.registers[8]);
    $display("X9: %h", dut.u_register_file.registers[9]);
    $display("X10: %h", dut.u_register_file.registers[10]);
    $display("X11: %h", dut.u_register_file.registers[11]);
    $display("X12: %h", dut.u_register_file.registers[12]);
    $display("X13: %h", dut.u_register_file.registers[13]);
    $display("X14: %h", dut.u_register_file.registers[14]);
    $display("X15: %h", dut.u_register_file.registers[15]);
    $display("X16: %h", dut.u_register_file.registers[16]);
    $display("X17: %h", dut.u_register_file.registers[17]);
    $display("X18: %h", dut.u_register_file.registers[18]);
    $display("X19: %h", dut.u_register_file.registers[19]);
    $display("X20: %h", dut.u_register_file.registers[20]);
    $display("X21: %h", dut.u_register_file.registers[21]);
    $display("X22: %h", dut.u_register_file.registers[22]);
    $display("X23: %h", dut.u_register_file.registers[23]);
    $display("X24: %h", dut.u_register_file.registers[24]);
    $display("X25: %h", dut.u_register_file.registers[25]);
    $display("X26: %h", dut.u_register_file.registers[26]);
    $display("X27: %h", dut.u_register_file.registers[27]);
    $display("X28: %h", dut.u_register_file.registers[28]);
    $display("X29: %h", dut.u_register_file.registers[29]);
    $display("X30: %h", dut.u_register_file.registers[30]);
    $display("X31: %h", dut.u_register_file.registers[31]);
   
    
    $display("Test finished");
    $finish;
  end
  
endmodule