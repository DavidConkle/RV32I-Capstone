module data_mem#(
    parameter DEPTH = 256 //Store up to 256 instructions, arbitrary number since no tapeout
)(
  input logic         clk,
  input logic         rst,
  input logic [2:0]   funct3,
  input logic [31:0]  addr,
  input logic [31:0]  wdata,
  input logic         write_en,
  input logic         read_en,
  output logic [31:0] rdata
);

    // Memory array
    logic [7:0] mem_array [0:DEPTH-1];
  
    // Read operation, reads an entire word starting at the aligned word address
    // The data aligner units deals with selecting and extending the byte/half-word/word 
    logic [31:0] addr_read;
    assign addr_read = {addr[31:2], 2'b00};
    always_comb begin
      rdata = '0;
      if(read_en) begin
        for (int i = 0; i < 4; i++) begin
          rdata[i*8 +: 8] = mem_array[addr_read + i];
        end
      end
    end

    // Write operation
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset memory to zero on reset
            for (int i = 0; i < DEPTH; i++) begin
                mem_array[i] <= 8'b0;
            end
        end else if (write_en) begin
          case(funct3)
            3'b000: begin		// Store least significant byte
              mem_array[addr] <= wdata[7:0];
            end
            3'b001: begin		// Store lower two bytes
              for (int i = 0; i < 2; i++) begin
                mem_array[addr + i] <= wdata[i*8 +: 8];
              end   
            end
            3'b010: begin		// Store word instruction
              for (int i = 0; i < 4; i++) begin
                mem_array[addr + i] <= wdata[i*8 +: 8];
              end
            end
          endcase
        end
    end
endmodule