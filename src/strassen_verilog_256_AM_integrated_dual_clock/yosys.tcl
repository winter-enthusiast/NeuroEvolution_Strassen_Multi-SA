read_verilog approx_1.v  approx_2.v  approx_3.v  approx_4.v  approx_5.v  approx_6.v  approx_7.v  approx_8.v  approx_9.v PE_groups_updated.v systolic_array.v
synth -top SystolicArray
abc -liberty ./../../global/libfiles/ASAP_7nm_RVT_TT_master.lib
opt_clean -purge
write_verilog -noattr ./netlists/strassen_matrix_mult_top_gate_level.v
# area report
tee -o ../report/strassen_matrix_mult_top_gate_level.txt stat -liberty ./../../global/libfiles/ASAP_7nm_RVT_TT_master.lib
