#!/usr/bin/env python3
import os
import glob

# Configuration
rtl_dir = '.'  # Current directory where RTL files are located
netlists_dir = '../netlists'  # Output directory for gate-level netlists
reports_dir = '../reports'    # Output directory for area reports
lib_file = './../../global/libfiles/ASAP_7nm_RVT_TT_master.lib'

# Create output directories if they don't exist
os.makedirs(netlists_dir, exist_ok=True)
os.makedirs(reports_dir, exist_ok=True)

# Get all Verilog files in RTL directory (excluding README.md)
rtl_files = [f for f in glob.glob(os.path.join(rtl_dir, '*.v')) 
            if not f.endswith('README.md')]

for rtl_file in rtl_files:
    # Extract base name (e.g., 'approx_1' from 'approx_1.v')
    base_name = os.path.splitext(os.path.basename(rtl_file))[0]
    
    # Define output filenames
    netlist_file = os.path.join(netlists_dir, f'{base_name}_gate_level.v')
    report_file = os.path.join(reports_dir, f'report_{base_name}.txt')
    
    # Generate Yosys script content
    yosys_script = f"""
# Read design
read_verilog {rtl_file}

# Generic synthesis
synth -top {base_name}

abc -liberty {lib_file}

# Clean up
opt_clean -purge

# Write netlist
write_verilog -noattr {netlist_file}

# Generate area report
tee -o {report_file} stat -liberty {lib_file}
"""
    
    # Write Yosys script to temporary file
    script_filename = f'temp_{base_name}.ys'
    with open(script_filename, 'w') as f:
        f.write(yosys_script)
    
    # Run Yosys
    os.system(f'yosys {script_filename}')
    
    # Remove temporary script file
    # os.remove(script_filename)
    
    print(f"Processed {rtl_file} -> {netlist_file} and {report_file}")

print("All designs processed successfully!")