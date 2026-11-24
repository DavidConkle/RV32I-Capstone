module pipeline_register (
    input  logic        clk,
    input  logic        reset,           // clears stored value when asserted
    input  logic [31:0]  data_in,        // can change as previous stage calculates its results

    output logic [31:0] data_out        // captures data_in on the rising clock edge and holds it
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 32'b0;          // clear stored output value to 0
        end else begin
            data_out <= data_in;        // set input data to output
        end
            
    end
    
endmodule