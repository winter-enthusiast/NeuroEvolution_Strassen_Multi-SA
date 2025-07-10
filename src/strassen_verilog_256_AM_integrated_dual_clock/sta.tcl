# Full-chip STA analysis for strassen_matrix_mult_top

# Set up variables
set LIB_PATH "./../../global/libfiles/ASAP_7nm_RVT_TT_master.lib"
# 4ns period for fast_clk
set CLK_PERIOD 4.0   
set CLK_NAME "fast_clk"
set TOP_MODULE "strassen_matrix_mult_top"


# Read libraries and design files
read_liberty $LIB_PATH


# Read all Verilog files
read_verilog ./netlists/approx_1_gate_level.v
read_verilog ./netlists/approx_2_gate_level.v
read_verilog ./netlists/approx_3_gate_level.v
read_verilog ./netlists/approx_4_gate_level.v
read_verilog ./netlists/approx_5_gate_level.v
read_verilog ./netlists/approx_6_gate_level.v
read_verilog ./netlists/approx_7_gate_level.v
read_verilog ./netlists/approx_8_gate_level.v
read_verilog ./netlists/approx_9_gate_level.v

read_verilog PE_groups_updated.v
read_verilog systolic_array.v
read_verilog strassen_256.v

# Link the top-level design
link_design $TOP_MODULE

# Create clocks
create_clock -name $CLK_NAME -period $CLK_PERIOD [get_ports fast_clk]
set_clock_uncertainty 0.1 [get_clocks $CLK_NAME]

# Set input/output delays
set_input_delay 0.2 -clock $CLK_NAME [remove_from_collection [all_inputs] [get_ports fast_clk]]
set_output_delay 0.2 -clock $CLK_NAME [all_outputs]

# Set false paths on asynchronous signals
set_false_path -from [get_port rst]

# Set wire load model (adjust based on your technology)
set_wire_load_mode top
set_wire_load_model -name "5K_hvratio_1.4" -library "asap7sc7p5t_24_RVT"

# Set operating conditions
set_operating_conditions -library "asap7sc7p5t_24_RVT" TT_1p1v_25C

# Perform timing analysis
update_timing -full
report_checks -path_delay max -fields {slew cap input_pin nets} -digits 4 > timing_max.rpt
report_checks -path_delay min -fields {slew cap input_pin nets} -digits 4 > timing_min.rpt
report_worst_slack -digits 4 > worst_slack.rpt

# Power analysis (requires switching activity)
# First set default switching activity
set_switching_activity -static_probability 0.5 -toggle_rate 0.1 -sequential_activity 0.1 [all_inputs]
set_switching_activity -static_probability 0.5 -toggle_rate 0.1 -sequential_activity 0.1 [all_registers -data_pins]

# Report power
report_power -hierarchy -digits 4 > power.rpt
report_power -net -digits 4 > power_nets.rpt

# Additional useful reports
report_clock_gating -style > clock_gating.rpt
report_clock_skew > clock_skew.rpt
report_constraint -all_violators > constraints.rpt

puts "STA analysis complete. Reports generated:"
puts "- timing_max.rpt : Worst setup timing paths"
puts "- timing_min.rpt : Worst hold timing paths"
puts "- worst_slack.rpt : Overall timing slack"
puts "- power.rpt : Hierarchical power breakdown"
puts "- power_nets.rpt : Net-level power consumption"