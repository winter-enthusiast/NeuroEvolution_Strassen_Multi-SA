import numpy as np
import os

# Step 1: Load the filters from file
def load_dct_filters(file_path):
    filters = []
    with open(file_path, 'r') as f:
        lines = f.readlines()
        current_filter = []
        for line in lines:
            line = line.strip()
            if line.startswith("filter"):
                if current_filter:
                    filters.append(np.array(current_filter, dtype=np.int8))
                    current_filter = []
            elif line:
                row = list(map(int, line.strip().split()))
                current_filter.append(row)
        if current_filter:  # Append last filter
            filters.append(np.array(current_filter, dtype=np.int8))
    return filters  # List of 256 filters, each 16x16

# Step 2: Flatten each filter column-wise to form matrix B_rearranged
def build_B_matrix(filters):
    B = np.zeros((256, 256), dtype=np.int8)  # 256 rows, 256 cols
    for i, filt in enumerate(filters):
        flattened = filt.flatten()  # Row-major order
        B[:, i] = flattened  # Each column is one flattened filter
    return B

# Step 3: Save matrix B row-wise
def save_B_matrix(B, file_path):
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    with open(file_path, 'w') as f:
        for row in B:
            row_str = ' '.join(str(int(x)) for x in row)
            f.write(row_str + '\n')

# Main flow
filters = load_dct_filters('./filters/dct_filters.dat')
assert len(filters) == 256, f"Expected 256 filters, got {len(filters)}"
for i, filt in enumerate(filters):
    assert filt.shape == (16, 16), f"Filter {i} shape is {filt.shape}, expected (16, 16)"

B_rearranged = build_B_matrix(filters)
save_B_matrix(B_rearranged, 'data/mat_B_rearranged.dat')

print("Matrix B_rearranged written successfully to data/mat_B_rearranged.dat")
