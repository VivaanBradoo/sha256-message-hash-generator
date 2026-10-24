`timescale 1ns / 1ps
// SHA-256 for byte-aligned messages of 0..55 bytes (one padded block).
// First byte is message[439:432]. Unused trailing bytes are ignored.
module sha256_message_hash (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [439:0] message,
    input wire [6:0] message_length,
    output wire busy,
    output wire digest_valid,
    output wire [255:0] digest,
    output wire [5:0] round_index,
    output reg length_error
);
    reg [511:0] padded_block;
    integer j;
    always @* begin
        padded_block=512'b0;
        if(message_length<=55) begin
            for(j=0;j<55;j=j+1)
                if(j<message_length) padded_block[511-j*8 -: 8]=message[439-j*8 -: 8];
            // Append 1 bit, then zeros, then the 64-bit big-endian bit length.
            padded_block[511-message_length*8 -: 8]=8'h80;
            padded_block[63:0]={57'b0,message_length} << 3;
        end
    end
    wire accepted_start=start && !busy && (message_length<=55);
    sha256_core core(clk,reset,accepted_start,padded_block,busy,digest_valid,digest,round_index);
    always @(posedge clk) begin
        if(reset) length_error<=0;
        else length_error<=start && !busy && (message_length>55);
    end
endmodule
