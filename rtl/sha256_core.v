`timescale 1ns / 1ps
// SHA-256 compression for one already-padded 512-bit message block.
// One round per clock. Fixed standard IV, no chaining across blocks.
module sha256_core (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [511:0] block,
    output reg busy,
    output reg digest_valid,
    output reg [255:0] digest,
    output reg [5:0] round_index
);
    reg [31:0] a,b,c,d,e,f,g,h;
    reg [31:0] schedule [0:63];
    integer i;
    function [31:0] rotr;
        input [31:0] x;
        input integer n;
        begin rotr=(x >> n) | (x << (32-n)); end
    endfunction
    function [31:0] sigma0;
        input [31:0] x;
        begin sigma0=rotr(x,7)^rotr(x,18)^(x>>3); end
    endfunction
    function [31:0] sigma1;
        input [31:0] x;
        begin sigma1=rotr(x,17)^rotr(x,19)^(x>>10); end
    endfunction
    function [31:0] constant_k;
        input [5:0] index;
        begin
            case(index)
                0:constant_k=32'h428a2f98; 1:constant_k=32'h71374491;
                2:constant_k=32'hb5c0fbcf; 3:constant_k=32'he9b5dba5;
                4:constant_k=32'h3956c25b; 5:constant_k=32'h59f111f1;
                6:constant_k=32'h923f82a4; 7:constant_k=32'hab1c5ed5;
                8:constant_k=32'hd807aa98; 9:constant_k=32'h12835b01;
                10:constant_k=32'h243185be; 11:constant_k=32'h550c7dc3;
                12:constant_k=32'h72be5d74; 13:constant_k=32'h80deb1fe;
                14:constant_k=32'h9bdc06a7; 15:constant_k=32'hc19bf174;
                16:constant_k=32'he49b69c1; 17:constant_k=32'hefbe4786;
                18:constant_k=32'h0fc19dc6; 19:constant_k=32'h240ca1cc;
                20:constant_k=32'h2de92c6f; 21:constant_k=32'h4a7484aa;
                22:constant_k=32'h5cb0a9dc; 23:constant_k=32'h76f988da;
                24:constant_k=32'h983e5152; 25:constant_k=32'ha831c66d;
                26:constant_k=32'hb00327c8; 27:constant_k=32'hbf597fc7;
                28:constant_k=32'hc6e00bf3; 29:constant_k=32'hd5a79147;
                30:constant_k=32'h06ca6351; 31:constant_k=32'h14292967;
                32:constant_k=32'h27b70a85; 33:constant_k=32'h2e1b2138;
                34:constant_k=32'h4d2c6dfc; 35:constant_k=32'h53380d13;
                36:constant_k=32'h650a7354; 37:constant_k=32'h766a0abb;
                38:constant_k=32'h81c2c92e; 39:constant_k=32'h92722c85;
                40:constant_k=32'ha2bfe8a1; 41:constant_k=32'ha81a664b;
                42:constant_k=32'hc24b8b70; 43:constant_k=32'hc76c51a3;
                44:constant_k=32'hd192e819; 45:constant_k=32'hd6990624;
                46:constant_k=32'hf40e3585; 47:constant_k=32'h106aa070;
                48:constant_k=32'h19a4c116; 49:constant_k=32'h1e376c08;
                50:constant_k=32'h2748774c; 51:constant_k=32'h34b0bcb5;
                52:constant_k=32'h391c0cb3; 53:constant_k=32'h4ed8aa4a;
                54:constant_k=32'h5b9cca4f; 55:constant_k=32'h682e6ff3;
                56:constant_k=32'h748f82ee; 57:constant_k=32'h78a5636f;
                58:constant_k=32'h84c87814; 59:constant_k=32'h8cc70208;
                60:constant_k=32'h90befffa; 61:constant_k=32'ha4506ceb;
                62:constant_k=32'hbef9a3f7; 63:constant_k=32'hc67178f2;
            endcase
        end
    endfunction
    wire [31:0] wt = (round_index < 16) ? schedule[round_index] :
        sigma1(schedule[round_index-2]) + schedule[round_index-7] +
        sigma0(schedule[round_index-15]) + schedule[round_index-16];
    wire [31:0] big0=rotr(a,2)^rotr(a,13)^rotr(a,22);
    wire [31:0] big1=rotr(e,6)^rotr(e,11)^rotr(e,25);
    wire [31:0] choose=(e&f)^((~e)&g);
    wire [31:0] majority=(a&b)^(a&c)^(b&c);
    wire [31:0] t1=h+big1+choose+constant_k(round_index)+wt;
    wire [31:0] t2=big0+majority;
    wire [31:0] next_a=t1+t2;
    wire [31:0] next_e=d+t1;
    wire [31:0] out0=32'h6a09e667+next_a;
    wire [31:0] out1=32'hbb67ae85+a;
    wire [31:0] out2=32'h3c6ef372+b;
    wire [31:0] out3=32'ha54ff53a+c;
    wire [31:0] out4=32'h510e527f+next_e;
    wire [31:0] out5=32'h9b05688c+e;
    wire [31:0] out6=32'h1f83d9ab+f;
    wire [31:0] out7=32'h5be0cd19+g;

    always @(posedge clk) begin
        if(reset) begin
            busy<=0; digest_valid<=0; digest<=0; round_index<=0;
            a<=0;b<=0;c<=0;d<=0;e<=0;f<=0;g<=0;h<=0;
            for(i=0;i<64;i=i+1) schedule[i]<=0;
        end else begin
            digest_valid<=0;
            if(!busy) begin
                if(start) begin
                    for(i=0;i<16;i=i+1) schedule[i]<=block[511-i*32 -: 32];
                    a<=32'h6a09e667;b<=32'hbb67ae85;
                    c<=32'h3c6ef372;d<=32'ha54ff53a;
                    e<=32'h510e527f;f<=32'h9b05688c;
                    g<=32'h1f83d9ab;h<=32'h5be0cd19;
                    busy<=1;round_index<=0;
                end
            end else begin
                if(round_index>=16) schedule[round_index]<=wt;
                a<=next_a;b<=a;c<=b;d<=c;e<=next_e;f<=e;g<=f;h<=g;
                if(round_index==63) begin
                    digest<={out0,out1,out2,out3,out4,out5,out6,out7};
                    busy<=0;digest_valid<=1;
                end else round_index<=round_index+1'b1;
            end
        end
    end
endmodule
