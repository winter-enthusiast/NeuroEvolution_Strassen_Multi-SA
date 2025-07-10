

remote_configs = {
    "cadencea12@172.16.121.82": {"password": "caduser@123", "subdir" : [ "array_config_1", "array_config_2"] },
    "cadencea1@172.16.121.72": {"password": "caduser@123", "subdir" : [ "array_config_5", "array_config_6"] },
    "cadencea8@172.16.121.78": {"password": "caduser@123", "subdir" : [ "array_config_7", "array_config_8"] },
    "cadencea10@172.16.121.80": {"password": "caduser@123", "subdir" : [ "array_config_9", "array_config_10"] },
    "cadencea15@172.16.121.6": {"password": "caduser@123", "subdir" : [ "array_config_11", "array_config_12"] },
    "cadencea14@172.16.121.84": {"password": "caduser@123", "subdir" : [ "array_config_13", "array_config_14"] },
    "imt2022556_nishit@172.16.121.37": {"password": "$@Rl@1234", "subdir" : [ "array_config_3", "array_config_4"] },
}


  ssh cadencea10@172.16.121.80
  ssh cadencea15@172.16.121.6
  ssh cadencea14@172.16.121.84

cadencea10@172.16.121.80
cadencea15@172.16.121.6
cadencea14@172.16.121.84
- [x] Make code synthesizable 
- [x] Parallelize ( Instantiate 7 strassen level 2 )
- [x] Come up with some way to Progress Track
- [x] PEs and Systolic Array ( parametric ? ) to do 3x3 mult
- [x] Solve LOADING_MATRICES bottle_neck
- [x] Write TCL script + Python partitioner + shell script to run TCL script lots of times 
- [x] Make the TCL scripts runnable in any PC ( paths need to be replaced with os. something )

### Have a automated engine to LOAD inputs INSTANTLY

( achieved using HUGE AMOUNT of parallel hardware )

Instead of using one signle 256-element BRAM for filling a 16x16 reg matrix A, and another same one for reg matrix B ;
We want to use 16 4x4 ( so 16-elemet ) BRAMs for filling the matrix A := we parallely fill all 16 sub quardrants of A SIMULTANEOUSLY.
We hope to reduce our LOADING TIME from 256 * 10ns to 16 * 10ns ( 10ns is clock period ) this way.

write a python code that will accept a 2D array of 16x16 dimension and write 16 4x4 matrice's FLATTENED coe file,
The naming convention is A_11_11, A_11_12, ...
Esseentially the way we name 4 quardrants of A is A_11, A_12, A_21, A_22 ; 
Since we are splitting this 16x16 matrices twice into 4 quardrant ( once into 4 quardrant and then each of the 4 quardrant into 4 smaller quardrants again )
So please follow the naming convention and generate the coe files.

Now we parametrically create 16 different tcl script like the BELOW to load a single 16x16 matrix via 16 16-element BRAM, parametrize the following :-
- blk_mem_gen_Aij_xy (bram name)
- which coe file to load ( python code created coe files according to the same name convention )
- generate_target ALSO has get_files which needs to be parametrize
```sh
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0
set_property -dict [list \
  CONFIG.Coe_File {/home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/src/matrices/input_A.coe} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Write_Depth_A {256} \
  CONFIG.Write_Width_A {3} \
] [get_ips blk_mem_gen_0]
generate_target {instantiation_template} [get_files /home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/vivado_projects/strassen_matmul_sysarray_accelerator/strassen_matmul_sysarray_accelerator.srcs/sources_1/ip/blk_mem_gen_0_1/blk_mem_gen_0.xci]
generate_target all [get_files  /home/nira/Documents/code/ece/Strassen_MatMul_GEMM_NN_Accel/vivado_projects/strassen_matmul_sysarray_accelerator/strassen_matmul_sysarray_accelerator.srcs/sources_1/ip/blk_mem_gen_0_1/blk_mem_gen_0.xci]
```

Then make another tcl script that just source each of these 16 tcl_scripts called FAST_BRAM_LOADER.tcl
I will then just source this single file

Modifications need to made in how I need to instantiate 32 BRAMs in my code ( 16BRAMs for A and 16 BRAMs for B)
    // Instantiate BRAMs with distinct signal in the following fashion
    <!-- assume dina is shared by all brams since we DON'T PLAN on writing to brams ever -->
    blk_mem_gen_A_11_11 bram_A11_11_inst ( .clka(clk), .ena(ena_a[0]), .wea(wea_a[0]), .addra(addr_a_[0]), .dina(dina), .douta(dout_a_[0]) );
    blk_mem_gen_A_11_12 bram_A11_12_inst ( .clka(clk), .ena(ena_a[1]), .wea(wea_a[1]), .addra(addra_a_[1]), .dina(dina), .douta(dout_a_[1]) );
    ... so on for all 16 A BRAMs and 16 B BRAMs
So please give me the 32 lines of all bram instantiation and before that the definition of all the enable arrays, write arrays, address ARRAYS, dout ARRAYS ( in system verilog )



### LOADING MATRIX SOLUTION

When I had only 2 block rams for A and B, I loaded matrix using the below code ; 
- I had to fill a 2D matrix, so I had to index the flattened array properly
- BLOCK RAMs have a 2 clock cycle latency, as in if we update addr_0, at posedge of 0th clock, only in 2nd clock's posedge will BRAM get us the data at addr_0.
- solution to this is using DELAY PIPELINE REGISTERS.
Eg : d1 ( for first clock delay storage, d2 for second clock delay storage )
            read_addr_d1 <= 0;
            read_addr_d2 <= 0;
            row_counter_d1 <= 0;
            row_counter_d2 <= 0;
            col_counter_d1 <= 0;
            col_counter_d2 <= 0;

Before :-
```sv
    always_ff @(posedge clk) begin
        if (rst) begin
            done <= 0;
            ts_pair_idx_l1 <= 0;
            l2_processing_done <= 0;
            l2_start_1 <= 0;
            l2_start_2 <= 0;
            l2_start_3 <= 0;
            l2_start_5 <= 0;
            l2_start_4 <= 0;
            l2_start_6 <= 0;
            l2_start_7 <= 0;
            read_addr_d1 <= 0;
            read_addr_d2 <= 0;
            row_counter_d1 <= 0;
            row_counter_d2 <= 0;
            col_counter_d1 <= 0;
            col_counter_d2 <= 0;
        end else begin
            read_addr_d1 <= read_addr;
            read_addr_d2 <= read_addr_d1;
            row_counter_d1 <= row_counter;
            row_counter_d2 <= row_counter_d1;
            col_counter_d1 <= col_counter;
            col_counter_d2 <= col_counter_d1;

            case(state)
                IDLE: begin
                    done <= 0;
                    ts_pair_idx_l1 <= 0;
                    l2_processing_done <= 0;
                    if (start) begin
                        // Initialize if starting
                        // Initialize variables for reading from block RAMs
                        read_addr <= 0;
                        row_counter <= 0;
                        col_counter <= 0;
                        
                        loading_matrices_done <= 0;
                        SPLIT_MATRICES_done <= 0;
                        COMPUTE_TS_LEVEL1_done <= 0;
                        COMPUTE_Q_LEVEL1_done <= 0;  
                        COMBINE_RESULTS_done <= 0;
                        
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        
                        // Set read enable for both BRAMs
                        ena_0 <= 1;
                        ena_1 <= 1;
                        wea_0 <= 0;
                        wea_1 <= 0;
                    end
                end

                LOADING_MATRICES: begin
                    if (read_addr < 259) begin
                        // Calculate indices for current address
                        row_counter <= read_addr / 16;
                        col_counter <= read_addr % 16;
                        
                        // Set the address for both BRAMs
                        addra_0 <= read_addr;
                        addra_1 <= read_addr;
                        
                        // Only capture data after 2-cycle delay
                        // Use the delayed row and column counters
                        if (read_addr > 2) begin
                            // The values from 2 cycles ago are available now
                            A[row_counter_d2][col_counter_d2] <= {5'b00000, douta_0}; // From blk_mem_gen_0
                            B[row_counter_d2][col_counter_d2] <= {5'b00000, douta_1}; // From blk_mem_gen_1
                        end
                        
                        read_addr <= read_addr + 1;
                    end else begin
                        // We need to continue for 2 more cycles to get the last values

                            ena_0 <= 0;
                            ena_1 <= 0;
                            loading_matrices_done <= 1;
                    end
                end
```

Now modify the above code since we will try to LOAD MATRIX by using 16 brams for A and 16 brams for B ;
We fill A and B matrix's 16 sub-quardrants simltaneously. Follow the EXACT SAME PATTER AS ABOVE CODE, but use the below BRAMS 

```sh
// Signal declarations
logic [15:0] ena_a, ena_b;
logic [15:0] wea_a, wea_b;
logic [3:0] addra_a [15:0], addra_b [15:0];  // 4-bit address for 16 elements
logic [2:0] dina;  // Shared data input (3-bit width)
logic [2:0] dout_a [15:0], dout_b [15:0];  // Output data from each BRAM

// Instantiate all 16 A BRAMs
blk_mem_gen_A_11_11 bram_A11_11_inst ( .clka(clk), .ena(ena_a[0]), .wea(wea_a[0]), .addra(addra_a[0]), .dina(dina), .douta(dout_a[0]) );
blk_mem_gen_A_11_12 bram_A11_12_inst ( .clka(clk), .ena(ena_a[1]), .wea(wea_a[1]), .addra(addra_a[1]), .dina(dina), .douta(dout_a[1]) );
blk_mem_gen_A_11_21 bram_A11_21_inst ( .clka(clk), .ena(ena_a[2]), .wea(wea_a[2]), .addra(addra_a[2]), .dina(dina), .douta(dout_a[2]) );
blk_mem_gen_A_11_22 bram_A11_22_inst ( .clka(clk), .ena(ena_a[3]), .wea(wea_a[3]), .addra(addra_a[3]), .dina(dina), .douta(dout_a[3]) );
blk_mem_gen_A_12_11 bram_A12_11_inst ( .clka(clk), .ena(ena_a[4]), .wea(wea_a[4]), .addra(addra_a[4]), .dina(dina), .douta(dout_a[4]) );
blk_mem_gen_A_12_12 bram_A12_12_inst ( .clka(clk), .ena(ena_a[5]), .wea(wea_a[5]), .addra(addra_a[5]), .dina(dina), .douta(dout_a[5]) );
blk_mem_gen_A_12_21 bram_A12_21_inst ( .clka(clk), .ena(ena_a[6]), .wea(wea_a[6]), .addra(addra_a[6]), .dina(dina), .douta(dout_a[6]) );
blk_mem_gen_A_12_22 bram_A12_22_inst ( .clka(clk), .ena(ena_a[7]), .wea(wea_a[7]), .addra(addra_a[7]), .dina(dina), .douta(dout_a[7]) );
blk_mem_gen_A_21_11 bram_A21_11_inst ( .clka(clk), .ena(ena_a[8]), .wea(wea_a[8]), .addra(addra_a[8]), .dina(dina), .douta(dout_a[8]) );
blk_mem_gen_A_21_12 bram_A21_12_inst ( .clka(clk), .ena(ena_a[9]), .wea(wea_a[9]), .addra(addra_a[9]), .dina(dina), .douta(dout_a[9]) );
blk_mem_gen_A_21_21 bram_A21_21_inst ( .clka(clk), .ena(ena_a[10]), .wea(wea_a[10]), .addra(addra_a[10]), .dina(dina), .douta(dout_a[10]) );
blk_mem_gen_A_21_22 bram_A21_22_inst ( .clka(clk), .ena(ena_a[11]), .wea(wea_a[11]), .addra(addra_a[11]), .dina(dina), .douta(dout_a[11]) );
blk_mem_gen_A_22_11 bram_A22_11_inst ( .clka(clk), .ena(ena_a[12]), .wea(wea_a[12]), .addra(addra_a[12]), .dina(dina), .douta(dout_a[12]) );
blk_mem_gen_A_22_12 bram_A22_12_inst ( .clka(clk), .ena(ena_a[13]), .wea(wea_a[13]), .addra(addra_a[13]), .dina(dina), .douta(dout_a[13]) );
blk_mem_gen_A_22_21 bram_A22_21_inst ( .clka(clk), .ena(ena_a[14]), .wea(wea_a[14]), .addra(addra_a[14]), .dina(dina), .douta(dout_a[14]) );
blk_mem_gen_A_22_22 bram_A22_22_inst ( .clka(clk), .ena(ena_a[15]), .wea(wea_a[15]), .addra(addra_a[15]), .dina(dina), .douta(dout_a[15]) );

// Instantiate all 16 B BRAMs
blk_mem_gen_B_11_11 bram_B11_11_inst ( .clka(clk), .ena(ena_b[0]), .wea(wea_b[0]), .addra(addra_b[0]), .dina(dina), .douta(dout_b[0]) );
blk_mem_gen_B_11_12 bram_B11_12_inst ( .clka(clk), .ena(ena_b[1]), .wea(wea_b[1]), .addra(addra_b[1]), .dina(dina), .douta(dout_b[1]) );
blk_mem_gen_B_11_21 bram_B11_21_inst ( .clka(clk), .ena(ena_b[2]), .wea(wea_b[2]), .addra(addra_b[2]), .dina(dina), .douta(dout_b[2]) );
blk_mem_gen_B_11_22 bram_B11_22_inst ( .clka(clk), .ena(ena_b[3]), .wea(wea_b[3]), .addra(addra_b[3]), .dina(dina), .douta(dout_b[3]) );
blk_mem_gen_B_12_11 bram_B12_11_inst ( .clka(clk), .ena(ena_b[4]), .wea(wea_b[4]), .addra(addra_b[4]), .dina(dina), .douta(dout_b[4]) );
blk_mem_gen_B_12_12 bram_B12_12_inst ( .clka(clk), .ena(ena_b[5]), .wea(wea_b[5]), .addra(addra_b[5]), .dina(dina), .douta(dout_b[5]) );
blk_mem_gen_B_12_21 bram_B12_21_inst ( .clka(clk), .ena(ena_b[6]), .wea(wea_b[6]), .addra(addra_b[6]), .dina(dina), .douta(dout_b[6]) );
blk_mem_gen_B_12_22 bram_B12_22_inst ( .clka(clk), .ena(ena_b[7]), .wea(wea_b[7]), .addra(addra_b[7]), .dina(dina), .douta(dout_b[7]) );
blk_mem_gen_B_21_11 bram_B21_11_inst ( .clka(clk), .ena(ena_b[8]), .wea(wea_b[8]), .addra(addra_b[8]), .dina(dina), .douta(dout_b[8]) );
blk_mem_gen_B_21_12 bram_B21_12_inst ( .clka(clk), .ena(ena_b[9]), .wea(wea_b[9]), .addra(addra_b[9]), .dina(dina), .douta(dout_b[9]) );
blk_mem_gen_B_21_21 bram_B21_21_inst ( .clka(clk), .ena(ena_b[10]), .wea(wea_b[10]), .addra(addra_b[10]), .dina(dina), .douta(dout_b[10]) );
blk_mem_gen_B_21_22 bram_B21_22_inst ( .clka(clk), .ena(ena_b[11]), .wea(wea_b[11]), .addra(addra_b[11]), .dina(dina), .douta(dout_b[11]) );
blk_mem_gen_B_22_11 bram_B22_11_inst ( .clka(clk), .ena(ena_b[12]), .wea(wea_b[12]), .addra(addra_b[12]), .dina(dina), .douta(dout_b[12]) );
blk_mem_gen_B_22_12 bram_B22_12_inst ( .clka(clk), .ena(ena_b[13]), .wea(wea_b[13]), .addra(addra_b[13]), .dina(dina), .douta(dout_b[13]) );
blk_mem_gen_B_22_21 bram_B22_21_inst ( .clka(clk), .ena(ena_b[14]), .wea(wea_b[14]), .addra(addra_b[14]), .dina(dina), .douta(dout_b[14]) );
blk_mem_gen_B_22_22 bram_B22_22_inst ( .clka(clk), .ena(ena_b[15]), .wea(wea_b[15]), .addra(addra_b[15]), .dina(dina), .douta(dout_b[15]) );
```

### Was not able to synthasis 32BRAMs in my laptop ( memory of 16gb got filled )
How we improved Loading times 
- 2560ns -> 160ns -> 10ns
- We would have 160ns LOADING TIME if the we use 32 small BRAMs
- We can assign each of the cells of the matrix in the RTL CODE ITSELF (10ns) !!
- Problem :- In PS-PL Workflow where we'll keep on have to Feed A and B matrices new value ( for every convolutional layer )

### Systolic Arrays Over Pure Combinational
- For MatMul of 4x4, 8x8; Combinational better 
- For sizes like 16x16; Systolics are better



