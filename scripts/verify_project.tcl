source [file join [file dirname [info script]] create_project.tcl]
launch_simulation
foreach signal {clk reset start test_index message_prefix message message_length busy digest_valid digest round_index length_error} {
    log_wave /tb_sha256_message_hash/$signal
}
log_wave /tb_sha256_message_hash/dut/padded_block
run all
close_sim
close_project
