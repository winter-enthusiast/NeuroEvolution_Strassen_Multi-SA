import numpy as np

def generate_sv_loading_code(A, B, output_file="loading_state.dat"):
    """
    Generate SystemVerilog code for loading individual cell values from matrices A and B.
    
    Args:
        A: First 2D numpy array with integer values
        B: Second 2D numpy array with integer values
        output_file: Path to the output file for the SystemVerilog code
    """
    with open(output_file, 'w') as f:
        # Write initializations for matrix A
        f.write("// Loading values for matrix A\n")
        for i in range(A.shape[0]):
            for j in range(A.shape[1]):
                f.write(f"A[{i}][{j}] <= 8'd{A[i][j]}; ")
            f.write("\n")
        
        f.write("\n// Loading values for matrix B\n")
        for i in range(B.shape[0]):
            for j in range(B.shape[1]):
                f.write(f"B[{i}][{j}] <= 8'd{B[i][j]}; ")
            f.write("\n")
        
        print(f"SystemVerilog initialization code written to {output_file}")


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

generate_sv_loading_code(A, B)