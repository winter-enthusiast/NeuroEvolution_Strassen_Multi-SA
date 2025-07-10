import os
import numpy as np

def create_coe_files(matrix, prefix, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    coe_files = []
    
    # First level splitting: 4 quadrants (each 8x8)
    for outer_i in range(2):  # Outer quadrant row (0-1)
        for outer_j in range(2):  # Outer quadrant column (0-1)

            # Second level splitting: each 8x8 quadrant into 4 4x4 submatrices
            for inner_i in range(2):  # Inner quadrant row (0-1)
                for inner_j in range(2):  # Inner quadrant column (0-1)
                    # Calculate the starting indices
                    start_row = outer_i * 8 + inner_i * 4
                    start_col = outer_j * 8 + inner_j * 4
                    
                    # Generate the submatrix name (1-based indexing)
                    outer_name = f"{outer_i+1}{outer_j+1}"
                    inner_name = f"{inner_i+1}{inner_j+1}"
                    filename = f"{prefix}_{outer_name}_{inner_name}.coe"
                    coe_path = os.path.join(output_dir, filename)
                    coe_files.append((f"{prefix}_{outer_name}_{inner_name}", coe_path))
                    
                    # Extract and flatten the 4x4 submatrix
                    submatrix = matrix[start_row:start_row+4, start_col:start_col+4]
                    flattened = submatrix.flatten().tolist()
                    
                    # Write COE file
                    with open(coe_path, 'w') as f:
                        f.write("memory_initialization_radix=10;\n")
                        f.write("memory_initialization_vector=\n")
                        f.write(",\n".join(map(str, flattened)) + ";\n")

                    print(f"Generated COE file: {filename}")
                    print(f"Submatrix contents:\n{submatrix}\n")
    return coe_files

def generate_tcl_scripts(coe_files, output_dir, base_dir):
    os.makedirs(output_dir, exist_ok=True)
    tcl_scripts = []
    
    for name, coe_path in coe_files:
        tcl_path = os.path.join(output_dir, f"create_{name}.tcl")
        ip_name = f"blk_mem_gen_{name}"
        print(f"Generating tcl script for {ip_name} that will load coe file {coe_path}")
        with open(tcl_path, 'w') as f:
            f.write(f"""create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name {ip_name}
set_property -dict [list \\
    CONFIG.Coe_File {{/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/calc/matrix_to_PARALLEL_brams/{coe_path}}} \\
    CONFIG.Load_Init_File {{true}} \\
    CONFIG.Write_Depth_A {{16}} \\
    CONFIG.Write_Width_A {{3}} \\
] [get_ips {ip_name}]
generate_target {{instantiation_template}} [get_files {{/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/calc/matrix_to_PARALLEL_brams/{ip_name}/{ip_name}.xci}}]
generate_target all [get_files {{/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/calc/matrix_to_PARALLEL_brams/{ip_name}/{ip_name}.xci}}]
""")
        tcl_scripts.append(tcl_path)
    
    # Create master TCL script
    master_path = os.path.join(output_dir, "FAST_BRAM_LOADER.tcl")
    with open(master_path, 'w') as f:
        for script in tcl_scripts:
            f.write(f"source {script}\n")
    
    return master_path

if __name__ == "__main__":
    # A = np.random.randint(0, 8, size=(16, 16))
    # B = np.random.randint(0, 8, size=(16, 16))
    
    A = np.array([
        [3, 4, 2, 4, 4, 1, 2, 2, 2, 4, 3, 2, 5, 4, 1, 3],
        [5, 5, 1, 3, 4, 0, 3, 1, 5, 4, 3, 0, 0, 2, 2, 1],
        [3, 3, 5, 5, 5, 2, 3, 3, 0, 2, 4, 2, 4, 0, 1, 3],
        [0, 3, 5, 1, 1, 0, 1, 4, 1, 3, 3, 3, 3, 4, 2, 5],
        [0, 3, 1, 3, 1, 5, 5, 5, 1, 3, 5, 4, 1, 1, 3, 1],
        [1, 5, 3, 5, 5, 3, 0, 5, 4, 4, 1, 4, 1, 0, 3, 3],
        [3, 4, 0, 4, 4, 0, 0, 0, 0, 3, 2, 2, 0, 2, 2, 0],
        [2, 4, 1, 1, 0, 3, 0, 3, 1, 0, 5, 4, 2, 3, 5, 2],
        [2, 0, 2, 4, 5, 2, 0, 4, 1, 5, 2, 0, 1, 1, 3, 4],
        [2, 0, 3, 4, 3, 5, 4, 4, 2, 4, 3, 4, 2, 2, 5, 3],
        [1, 1, 4, 5, 0, 4, 5, 3, 3, 3, 3, 3, 5, 5, 2, 1],
        [3, 0, 5, 0, 0, 0, 2, 5, 0, 3, 4, 0, 2, 5, 2, 0],
        [5, 4, 0, 2, 1, 3, 2, 5, 0, 3, 0, 5, 0, 1, 3, 3],
        [5, 1, 2, 0, 4, 0, 0, 2, 0, 1, 1, 3, 5, 4, 0, 0],
        [2, 5, 1, 4, 3, 1, 5, 3, 2, 2, 0, 5, 4, 3, 1, 5],
        [5, 2, 0, 0, 3, 2, 5, 4, 2, 3, 3, 2, 3, 2, 1, 2],
    ])

    B = np.array([
        [2, 3, 3, 0, 0, 1, 0, 2, 3, 0, 0, 1, 5, 1, 2, 3],
        [1, 0, 3, 3, 0, 1, 0, 5, 3, 4, 4, 2, 0, 0, 2, 2],
        [2, 3, 5, 0, 3, 2, 0, 3, 5, 3, 5, 2, 5, 0, 2, 0],
        [4, 1, 5, 1, 1, 5, 2, 4, 0, 3, 0, 3, 0, 5, 4, 3],
        [2, 0, 0, 3, 2, 2, 5, 5, 5, 5, 5, 5, 4, 2, 5, 2],
        [2, 1, 4, 5, 0, 3, 0, 4, 3, 4, 2, 3, 2, 0, 0, 3],
        [3, 5, 4, 5, 4, 5, 2, 3, 0, 4, 4, 0, 5, 4, 2, 3],
        [0, 3, 4, 4, 0, 2, 1, 0, 1, 5, 1, 2, 5, 1, 5, 1],
        [2, 1, 1, 1, 0, 0, 0, 2, 5, 4, 1, 1, 2, 1, 0, 4],
        [3, 1, 0, 3, 4, 3, 0, 5, 5, 3, 2, 3, 1, 1, 5, 2],
        [0, 1, 5, 4, 5, 1, 1, 5, 0, 3, 1, 5, 5, 2, 3, 4],
        [0, 4, 3, 3, 3, 4, 3, 5, 4, 3, 5, 2, 3, 4, 1, 3],
        [1, 5, 2, 0, 2, 3, 1, 1, 4, 1, 4, 5, 0, 3, 4, 0],
        [1, 1, 0, 1, 5, 5, 0, 4, 4, 0, 4, 4, 5, 4, 2, 3],
        [1, 2, 4, 5, 0, 4, 5, 3, 4, 0, 5, 5, 5, 3, 4, 3],
        [1, 1, 4, 3, 0, 5, 5, 4, 1, 1, 5, 4, 3, 1, 3, 1],
    ])

    # Generate COE files and TCL scripts for matrix A
    coe_files_A = create_coe_files(A, "A", "coe_files/A")
    master_tcl_A = generate_tcl_scripts(coe_files_A, "tcl_scripts/A", "/home/nira/Documents/code/ece/vivado_projects/fast_BRAMs")
    
    # Generate COE files and TCL scripts for matrix B
    coe_files_B = create_coe_files(B, "B", "coe_files/B")
    master_tcl_B = generate_tcl_scripts(coe_files_B, "tcl_scripts/B", "/home/nira/Documents/code/ece/vivado_projects/fast_BRAMs")
    
    print(f"Generated master TCL scripts:\nA: {master_tcl_A})\nB: {master_tcl_B}")