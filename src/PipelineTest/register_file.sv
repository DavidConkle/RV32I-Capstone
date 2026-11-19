`timescale 1ns / 1ps

module register_file ( input  logic        clk,
                       input  logic [4:0]  read_addr1,
                       input  logic [4:0]  read_addr2,
                       input  logic        write_enable,
                       input  logic [4:0]  write_addr,
                       input  logic [31:0] write_data,       

                       output logic [31:0] read_data1,
                       output logic [31:0] read_data2
);

        logic [31:0] registers [0:31];          // registers

        // read both selected registers
        // reads of x0 always return zero
        always_comb begin
            if (read_addr1 == 5'b0) begin
                read_data1 = 32'b0;
            end else if (write_enable && write_addr == read_addr1)begin    // bypass write_data when reading the register being written. 
              read_data1 = write_data;
            end else begin
                read_data1 = registers[read_addr1];
            end

            if (read_addr2 == 5'b0) begin
                read_data2 = 32'b0;
            end else if(write_enable && write_addr == read_addr2) begin
                read_data2 = write_data;
            end else begin
                read_data2 = registers[read_addr2];
            end
        end

        // ignore writes to x0
        always_ff @( posedge clk ) begin
            if(write_enable && write_addr != 5'b0) begin
                registers[write_addr] <= write_data;
            end         
        end
    
endmodule
