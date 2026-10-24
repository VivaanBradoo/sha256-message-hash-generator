set root [file normalize [file join [file dirname [info script]] ..]]
set project_dir [file join $root vivado_project]
if {[file exists [file join $project_dir sha256_hash.xpr]]} {
    open_project [file join $project_dir sha256_hash.xpr]
} else {
    create_project sha256_hash $project_dir -part xc7a35tcpg236-1
}
set_property target_language Verilog [current_project]
add_files [glob [file join $root rtl *.v]]
set_property top sha256_message_hash [get_filesets sources_1]
add_files -fileset sim_1 [list [file join $root sim tb_sha256_message_hash.sv] [file join $root sim test_vectors.mem]]
set_property top tb_sha256_message_hash [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Run Behavioral Simulation, then Run All."
