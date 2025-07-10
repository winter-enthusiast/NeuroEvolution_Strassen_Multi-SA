create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_A_11_22
set_property -dict [list \
    CONFIG.Coe_File {/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/calc/matrix_to_PARALLEL_brams/coe_files/A/A_11_22.coe} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Write_Depth_A {16} \
    CONFIG.Write_Width_A {3} \
] [get_ips blk_mem_gen_A_11_22]
generate_target {instantiation_template} [get_files {/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/calc/matrix_to_PARALLEL_brams/blk_mem_gen_A_11_22/blk_mem_gen_A_11_22.xci}]
generate_target all [get_files {/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/calc/matrix_to_PARALLEL_brams/blk_mem_gen_A_11_22/blk_mem_gen_A_11_22.xci}]
