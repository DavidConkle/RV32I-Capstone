/*
    All signlas are active high
    Input address is byte address
*/

module mem_interface(
    input logic clk,
    input logic rst,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic write_en,
    output logic [31:0] rdata
);

    // Memory array
    logic [7:0] mem_array [0:1023]; // 1024 words of 8 bits each for byte adressable memory
  

    // Read operation
    always_ff @(posedge clk or negedge rst) begin
        if (rst) begin
            rdata <= 32'b0;
        end else if (!write_en) begin
            for (int i = 0; i < 4; i++) begin
                rdata[i*8 +: 8] <= mem_array[addr + i];
            end
        end
    end

    // Write operation
    always_ff @(posedge clk or negedge rst) begin
        if (rst) begin
            // Reset memory to zero on reset
            for (int i = 0; i < 1024; i++) begin
                mem_array[i] <= 8'b0;
            end
        end else if (write_en) begin
            for (int i = 0; i < 4; i++) begin
                mem_array[addr + i] <= wdata[i*8 +: 8];
            end
        end
    end
endmodule