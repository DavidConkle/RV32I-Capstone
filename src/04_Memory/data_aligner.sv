// RV32I Data Load Aligner
// Selects the byte/half-word from the word loaded from memory, places in the LSB,
// 		and sign-extendsor zero-extends according to the funct3 field
//
// funct3	instr	operation
// 000		LB		Sign-Extend chosen byte
// 001		LH		Sign-Extend chosen half-word
// 010		LW		Load Word, no extension needed
// 100		LBU		Zero-Extend chosen byte
// 101		LHU		Zero-Extend chosen half-word

module data_aligner(
  input  logic [31:0] mem_data,
  input  logic [2:0]  funct3,
  input  logic [1:0]  addr_lsb,
  output logic [31:0] mem_aligned
);
  
  logic [7:0] byte_load;
  logic [15:0] half_load;
  
  // Assign data to byte_load
  always_comb begin
    unique case (addr_lsb)
      2'b00:    byte_load = mem_data[7:0];
      2'b01:    byte_load = mem_data[15:8];
      2'b10:    byte_load = mem_data[23:16];
      2'b11:    byte_load = mem_data[31:24];
    endcase
  end
    
  // Assign data to half_load
  always_comb begin
    unique case (addr_lsb)
      2'b00:    half_load = mem_data[15:0];
      2'b10:    half_load = mem_data[31:16];
      default:  half_load = '0;
    endcase
  end
    
  // Assign output according to funct3 bits
  always_comb begin
    unique case (funct3)
      3'b000:    mem_aligned = {{24{byte_load[7]}}, byte_load};
      3'b001:    mem_aligned = {{16{half_load[15]}}, half_load};
      3'b010:    mem_aligned = mem_data;
      3'b100:    mem_aligned = {24'b0, byte_load};
      3'b101:    mem_aligned = {16'b0, half_load};
      default:   mem_aligned = mem_data;
    endcase
  end
 
endmodule