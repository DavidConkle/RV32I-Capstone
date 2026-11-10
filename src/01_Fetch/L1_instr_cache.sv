/*
* Module: L1_cache
* Parameters:
*   - CACHE_SIZE : Total capacity of the cache in bytes (default: 1024 bytes).
*   - BLOCK_SIZE : Size of each cache line/block in bytes (default: 16 bytes).
*   - BLOCK_BITS : Width of the block data bus in bits (derived: BLOCK_SIZE * 8), important for Memory bus width.
*
* Interfaces:
*   - CPU Side    : Receives 32-bit PC addresses (`cpu_addr`), outputs 32-bit 
*                   instructions (`cpu_instr`) and a single-cycle hit flag (`cache_hit`).
*   - Memory Side : Issues block requests (`mem_req`, `mem_addr`), accepts wide 
*                   block responses (`mem_data`), gated by a ready signal (`mem_ready`), mem_ready is given by the memory when the block is avaliable to write to cache.
*
* Author: Chris Poterek
*/

module L1_cache #(
    parameter int CACHE_SIZE = 1024, //Cache size in bytes
    parameter int BLOCK_SIZE = 16,   //Block size in bytes
    parameter int BLOCK_BITS = BLOCK_SIZE * 8 //Block size in bits

)(
    //Clk and reset(active low)
    input logic clk,
    input logic rst_n,

    //CPU interface
    input logic [31:0] cpu_addr,        //PC addr
    output logic [31:0] cpu_instr,      //Instruction data to CPU
    output logic cache_hit              //Cache hit signal

    //Memory interface
    output logic mem_req,           //Memory request signal
    output logic [31:0] mem_addr,   //Memory request address
    input logic [BLOCK_BITS-1:0] mem_data,    //Memory response data
    input logic mem_ready           //Memory ready signal
);

    //Parameters for cache configuration
    localparam int NUM_BLOCKS = CACHE_SIZE / BLOCK_SIZE; //Number of blocks in cache
    localparam int WORDS_PER_BLOCK = BLOCK_SIZE / 4; //Number of words per block
    localparam int INDEX_BITS = $clog2(NUM_BLOCKS); //Number of index bits
    localparam int OFFSET_BITS = $clog2(BLOCK_SIZE); //Number of offset bits
    localparam int TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS; //Number of tag bits


    //Address slicing
    logic [TAG_BITS-1:0] tag;
    logic [INDEX_BITS-1:0] index;
    logic [OFFSET_BITS-1:0] offset;

    assign tag = cpu_addr[31:32-TAG_BITS];
    assign index = cpu_addr[32-TAG_BITS-1:OFFSET_BITS];
    assign offset = cpu_addr[OFFSET_BITS-1:0];

    //Cache memory
    logic [NUM_BLOCKS-1:0] valid; //Valid bits for each block
    logic [TAG_BITS-1:0] tags [NUM_BLOCKS-1:0]; //Tag storage for each block
    logic [BLOCK_BITS-1:0] data [NUM_BLOCKS]; //Data storage for each block


    //state machine for miss handling
    typedef enum logic {IDLE = 1'b0, REFILL = 1'b1} state_t;
    state_t state;
    logic [TAG_BITS-1:0] miss_tag;
    logic [INDEX_BITS-1:0] miss_index;



    //HIT 
    logic tag_match;
    assign tag_match = (valid[index] && (tags[index] == tag));
    assign cache_hit =  (state == IDLE) && tag_match;   //Makes sure cache isn't trying to get memory data when it is a hit
    assign cpu_instr = (cache_hit) ? data[index][offset[OFFSET_BITS-1:2]*32 +: 32]: 32'b0; //Return instruction if hit, else return 0

    //Memory outputs/requests
    assign mem_req = (state == REFILL);
    assign mem_addr = {miss_tag, miss_index, {OFFSET_BITS{1'b0}}}; //Request memory with the block address


    
    //Data/tag arrays: no reset, so they can map to memory, valid bit will be controlled by state machine
    always_ff @(posedge clk) begin
        if (state == REFILL && mem_ready) begin
            data[miss_index] <= mem_data;
            tags[miss_index] <= miss_tag;
        end
    end
 
    //Control: state and valid bits only
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (!tag_match) begin               //Cache miss
                        state      <= REFILL;
                        miss_tag   <= tag;
                        miss_index <= index;
                    end
                end
 
                REFILL: begin
                    if (mem_ready) begin                //Whole block arrived
                        valid[miss_index] <= 1'b1;
                        state             <= IDLE;
                    end
                end
 
                default: state <= IDLE;
            endcase
        end
    end

endmodule