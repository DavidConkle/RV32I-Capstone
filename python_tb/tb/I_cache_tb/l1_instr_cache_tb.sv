module l1_instr_cache_tb (
    input logic clk,
    input logic rst_n,
    input logic [31:0] cpu_addr,
    input logic [127:0] mem_data,
    input logic mem_ready,

    output logic [31:0] cpu_instr,
    output logic cache_hit,
    output logic mem_req,
    output logic [31:0] mem_addr
);

l1_instr_cache u_l1_instr_cache (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_addr(cpu_addr),
    .mem_data(mem_data),
    .mem_ready(mem_ready),
    .cpu_instr(cpu_instr),
    .cache_hit(cache_hit),
    .mem_req(mem_req),
    .mem_addr(mem_addr)
);

initial begin
   $dumpfile("dump.vcd");
   $dumpvars(0, l1_instr_cache_tb); 
end
    
endmodule