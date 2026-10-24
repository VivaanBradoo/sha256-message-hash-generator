`timescale 1ns / 1ps
module tb_sha256_message_hash;
    reg clk=0;
    always #5 clk=~clk;
    reg reset=1,start=0;
    reg [439:0] message=0;
    reg [6:0] message_length=0;
    wire busy,digest_valid,length_error;
    wire [255:0] digest;
    wire [5:0] round_index;
    wire [23:0] message_prefix=message[439:416];
    reg [7:0] test_index=0;
    reg [703:0] vectors [0:63];
    integer checks=0,i,r,fd,changed_bits=0;
    reg [255:0] first_digest,changed_digest,held_digest;
    sha256_message_hash dut(.*);
    task automatic check(input bit ok,input string label_text);
        checks++;
        if(!ok) $fatal(1,"FAIL at %0t: %s",$time,label_text);
    endtask
    task automatic tick;
        @(posedge clk); #1;
    endtask
    task automatic run_vector(input integer index,input bit disturb);
        @(negedge clk);
        test_index=index;
        message=vectors[index][695:256];message_length=vectors[index][702:696];start=1;
        tick();check(busy===1 && digest_valid===0,"Request accepted");
        check(length_error===0,"Valid length accepted");
        for(r=0;r<64;r++) begin
            @(negedge clk);
            start=disturb && (r==15);
            // Change all inputs while running; the accepted block must be latched.
            if(disturb) begin message='1;message_length=55;end
            tick();
            if(r<63) begin
                check(busy===1 && digest_valid===0,"No early completion");
                check(round_index===r+1,"One round per clock");
            end else begin
                check(busy===0 && digest_valid===1,"Completion after 64 rounds");
                check(digest===vectors[index][255:0],"Digest matches independent hashlib oracle");
            end
            check(length_error===0,"Busy request ignored");
        end
        $display("HASH vector=%0d length=%0d digest=%064h",index,vectors[index][703:696],digest);
        $fdisplay(fd,"%0d,%0d,%064h",index,vectors[index][703:696],digest);
        held_digest=digest;
        @(negedge clk);start=0;
        tick();check(digest_valid===0 && digest===held_digest,"Valid pulses once and digest holds");
    endtask
    initial begin
        $readmemh("test_vectors.mem",vectors);
        fd=$fopen("sha256_results.csv","w");
        if(!fd) $fatal(1,"Cannot open results file");
        $fdisplay(fd,"vector,length_bytes,digest_hex");
        tick();check(busy===0 && digest_valid===0 && digest===0,"Reset clears status and digest");
        @(negedge clk);reset=0;
        for(i=0;i<64;i++) begin
            run_vector(i,i==5);
            if(i==0) first_digest=digest;
            if(i==1) check(digest===first_digest,"Repeated input gives identical digest");
            if(i==2) begin
                changed_digest=digest;
                for(integer bit_index=0;bit_index<256;bit_index++)
                    if(first_digest[bit_index]!=digest[bit_index]) changed_bits++;
                check(digest!==first_digest,"One changed input bit changes digest");
                $display("AVALANCHE abc versus abb: %0d of 256 digest bits differ",changed_bits);
            end
        end
        // Reject all lengths beyond the supported single-block range.
        for(i=56;i<128;i++) begin
            @(negedge clk);start=1;message_length=i;
            tick();check(length_error===1 && busy===0 && digest_valid===0,"Oversized message rejected");
            @(negedge clk);start=0;
            tick();check(length_error===0,"Error clears when request ends");
        end
        // Reset must cancel a transaction without producing a digest pulse.
        @(negedge clk);message=vectors[0][695:256];message_length=3;start=1;
        tick();
        @(negedge clk);start=0;
        repeat(10) tick();
        @(negedge clk);reset=1;
        tick();check(busy===0 && digest_valid===0 && digest===0,"Reset aborts in-flight hash");
        @(negedge clk);reset=0;
        run_vector(0,0);
        $fclose(fd);
        $display("PASS: %0d checks; 65 hashes verified; lengths 0..55 covered; avalanche=%0d/256 bits",checks,changed_bits);
        $finish;
    end
    initial begin #100000; $fatal(1,"Watchdog timeout");end
endmodule
