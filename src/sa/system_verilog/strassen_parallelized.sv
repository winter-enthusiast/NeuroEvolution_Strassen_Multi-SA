module strassen_matrix_mult (
    input logic clk,
    input logic rst,
    input logic start,
    output logic [15:0] C [0:15][0:15],
    output logic done
);

    // States for the main FSM
    typedef enum logic [2:0] {
        IDLE = 3'd0,
        LOADING_MATRICES = 3'd1,
        SPLIT_MATRICES = 3'd2,
        COMPUTE_TS_LEVEL1 = 3'd3,
        PROCESS_LEVEL2 = 3'd4,
        COMPUTE_Q_LEVEL1 = 3'd5,
        COMBINE_RESULTS = 3'd6,
        DONE = 3'd7
    } state_t;
    
    // Current state
    state_t state, next_state;
    // A and B matrices (16x16) - now signed
    logic signed [7:0] A [0:15][0:15];
    logic signed [7:0] B [0:15][0:15]; 
    
    // Level 1 matrices (8x8) - now signed
    logic signed [7:0] A11 [0:7][0:7];
    logic signed [7:0] A12 [0:7][0:7];
    logic signed [7:0] A21 [0:7][0:7];
    logic signed [7:0] A22 [0:7][0:7];
    logic signed [7:0] B11 [0:7][0:7];
    logic signed [7:0] B12 [0:7][0:7];
    logic signed [7:0] B21 [0:7][0:7];
    logic signed [7:0] B22 [0:7][0:7];
    
    // Level 1 T and S matrices (8x8) - now signed
    logic signed [7:0] T1_L1 [0:7][0:7];
    logic signed [7:0] T2_L1 [0:7][0:7];
    logic signed [7:0] T3_L1 [0:7][0:7];
    logic signed [7:0] T4_L1 [0:7][0:7];
    logic signed [7:0] T5_L1 [0:7][0:7];
    logic signed [7:0] T6_L1 [0:7][0:7];
    logic signed [7:0] T7_L1 [0:7][0:7];
    
    logic signed [7:0] S1_L1 [0:7][0:7];
    logic signed [7:0] S2_L1 [0:7][0:7];
    logic signed [7:0] S3_L1 [0:7][0:7];
    logic signed [7:0] S4_L1 [0:7][0:7];
    logic signed [7:0] S5_L1 [0:7][0:7];
    logic signed [7:0] S6_L1 [0:7][0:7];
    logic signed [7:0] S7_L1 [0:7][0:7];
    
    // Level 1 Q matrices (8x8) - now signed with wider bit width for multiplication results
    logic signed [15:0] Q1_L1 [0:7][0:7];
    logic signed [15:0] Q2_L1 [0:7][0:7];
    logic signed [15:0] Q3_L1 [0:7][0:7];
    logic signed [15:0] Q4_L1 [0:7][0:7];
    logic signed [15:0] Q5_L1 [0:7][0:7];
    logic signed [15:0] Q6_L1 [0:7][0:7];
    logic signed [15:0] Q7_L1 [0:7][0:7];
    
    // Level 1 C matrices (8x8) - now signed
    logic signed [15:0] C11 [0:7][0:7];
    logic signed [15:0] C12 [0:7][0:7];
    logic signed [15:0] C21 [0:7][0:7];
    logic signed [15:0] C22 [0:7][0:7];
    
    
    // Variables for BRAM loading
    logic [8:0] read_addr;
    logic [3:0] row_counter;
    logic [3:0] col_counter;
    logic signed [7:0] dina; // Common input data - now signed
    
    // For blk_mem_gen_0
    logic [2:0] douta_0;
    logic [7:0] addra_0;
    logic ena_0;
    logic wea_0;
    
    //done signals
    logic loading_matrices_done, SPLIT_MATRICES_done, COMPUTE_TS_LEVEL1_done, COMPUTE_Q_LEVEL1_done, COMBINE_RESULTS_done;
    // For blk_mem_gen_1
    logic [2:0] douta_1;
    logic [7:0] addra_1;
    logic ena_1;
    logic wea_1;
    // Add pipeline registers to track addresses
    logic [7:0] read_addr_d1, read_addr_d2;
    logic [3:0] row_counter_d1, row_counter_d2;
    logic [3:0] col_counter_d1, col_counter_d2;

    // Instantiate BRAMs with distinct signal names
    //   <----- Remember that .dina(dina),  // Assuming this is shared if you're not writing  ----> 
    blk_mem_gen_0 bram0_inst ( .clka(clk), .ena(ena_0), .wea(wea_0), .addra(addra_0), .dina(dina),  .douta(douta_0) );
    blk_mem_gen_1 bram1_inst ( .clka(clk), .ena(ena_1), .wea(wea_1), .addra(addra_1), .dina(dina),   .douta(douta_1) );


    // LEVEL 2 INTERACTING SIGNALS  

    // Control signals for level 2 processing
    logic [2:0] ts_pair_idx_l1;
    logic l2_processing_done;
    
    logic signed [7:0] T_in_1 [0:7][0:7];
    logic signed [7:0] S_in_1 [0:7][0:7];
    logic signed [15:0] Q_out_1 [0:7][0:7];
    logic l2_start_1;
    logic l2_done_1;

    logic signed [7:0] T_in_2 [0:7][0:7];
    logic signed [7:0] S_in_2 [0:7][0:7];
    logic signed [15:0] Q_out_2 [0:7][0:7];
    logic l2_start_2;
    logic l2_done_2;

    logic signed [7:0] T_in_3 [0:7][0:7];
    logic signed [7:0] S_in_3 [0:7][0:7];
    logic signed [15:0] Q_out_3 [0:7][0:7];
    logic l2_start_3;
    logic l2_done_3;

    logic signed [7:0] T_in_4 [0:7][0:7];
    logic signed [7:0] S_in_4 [0:7][0:7];
    logic signed [15:0] Q_out_4 [0:7][0:7];
    logic l2_start_4;
    logic l2_done_4;

    logic signed [7:0] T_in_5 [0:7][0:7];
    logic signed [7:0] S_in_5 [0:7][0:7];
    logic signed [15:0] Q_out_5 [0:7][0:7];
    logic l2_start_5;
    logic l2_done_5;

    logic signed [7:0] T_in_6 [0:7][0:7];
    logic signed [7:0] S_in_6 [0:7][0:7];
    logic signed [15:0] Q_out_6 [0:7][0:7];
    logic l2_start_6;
    logic l2_done_6;

    logic signed [7:0] T_in_7 [0:7][0:7];
    logic signed [7:0] S_in_7 [0:7][0:7];
    logic signed [15:0] Q_out_7 [0:7][0:7];
    logic l2_start_7;
    logic l2_done_7;   

    strassen_level2 level2_processor_T1_S1 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_1),
        .T(T_in_1),
        .S(S_in_1),
        .Q(Q_out_1),
        .done(l2_done_1)
    );

    strassen_level2 level2_processor_T2_S2 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_2),
        .T(T_in_2),
        .S(S_in_2),
        .Q(Q_out_2),
        .done(l2_done_2)
    );

    strassen_level2 level2_processor_T3_S3 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_3),
        .T(T_in_3),
        .S(S_in_3),
        .Q(Q_out_3),
        .done(l2_done_3)
    );

    strassen_level2 level2_processor_T4_S4 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_4),
        .T(T_in_4),
        .S(S_in_4),
        .Q(Q_out_4),
        .done(l2_done_4)
    );

    strassen_level2 level2_processor_T5_S5 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_5),
        .T(T_in_5),
        .S(S_in_5),
        .Q(Q_out_5),
        .done(l2_done_5)
    );

    strassen_level2 level2_processor_T6_S6 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_6),
        .T(T_in_6),
        .S(S_in_6),
        .Q(Q_out_6),
        .done(l2_done_6)
    );

    strassen_level2 level2_processor_T7_S7 (
        .clk(clk),
        .rst(rst),
        .start(l2_start_7),
        .T(T_in_7),
        .S(S_in_7),
        .Q(Q_out_7),
        .done(l2_done_7)
    );
    
    // State machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        case(state)
            IDLE: 
                next_state = start ? LOADING_MATRICES : IDLE;
            LOADING_MATRICES: 
                next_state = loading_matrices_done ? SPLIT_MATRICES : LOADING_MATRICES;
            SPLIT_MATRICES: 
                next_state = SPLIT_MATRICES_done ? COMPUTE_TS_LEVEL1 : SPLIT_MATRICES;
            COMPUTE_TS_LEVEL1: 
                next_state = COMPUTE_TS_LEVEL1_done ? PROCESS_LEVEL2 : COMPUTE_TS_LEVEL1;
            PROCESS_LEVEL2: 
                next_state = l2_processing_done ? COMPUTE_Q_LEVEL1 : PROCESS_LEVEL2;
            COMPUTE_Q_LEVEL1: 
                next_state = COMPUTE_Q_LEVEL1_done ? COMBINE_RESULTS : COMPUTE_Q_LEVEL1;
            COMBINE_RESULTS: 
                next_state = COMBINE_RESULTS_done ? DONE : COMBINE_RESULTS;
            DONE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // Main processing
    integer i, j, k;

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
            
            // Reset delay registers
            read_addr_d1 <= 0;
            read_addr_d2 <= 0;
            
            // Enable flags for all BRAMs are reset
            for (int i = 0; i < 16; i++) begin
                ena_a[i] <= 0;
                ena_b[i] <= 0;
                wea_a[i] <= 0;
                wea_b[i] <= 0;
            end
        end else begin
            // Update delay registers
            read_addr_d1 <= read_addr;
            read_addr_d2 <= read_addr_d1;
        
            case(state)
                IDLE: begin
                    done <= 0;
                    ts_pair_idx_l1 <= 0;
                    l2_processing_done <= 0;
                    
                    if (start) begin
                        // Initialize variables for reading from block RAMs
                        read_addr <= 0;
                        
                        loading_matrices_done <= 0;
                        SPLIT_MATRICES_done <= 0;
                        COMPUTE_TS_LEVEL1_done <= 0;
                        COMPUTE_Q_LEVEL1_done <= 0;  
                        COMBINE_RESULTS_done <= 0;
                        
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        
                        // Enable all BRAMs for reading
                        for (int i = 0; i < 16; i++) begin
                            ena_a[i] <= 1;
                            ena_b[i] <= 1;
                            wea_a[i] <= 0;
                            wea_b[i] <= 0;
                            // Initialize addresses to 0
                            addra_a[i] <= 0;
                            addra_b[i] <= 0;
                        end
                    end
                end
                
                LOADING_MATRICES: begin
                    if (read_addr < 17) begin  // 16 elements per BRAM + 1 extra cycle for latency
                        // Set the addresses for all BRAMs
                        for (int i = 0; i < 16; i++) begin
                            addra_a[i] <= read_addr[3:0]; // Only need 4 bits for 16 elements
                            addra_b[i] <= read_addr[3:0];
                        end
                        
                        // Only capture data after 2-cycle delay
                        if (read_addr > 1) begin
                            // Load data from all BRAMs into the correct positions in A and B matrices
                            // First quadrant (A_11_xx)
                            A[0][0] <= {5'b00000, dout_a[0]};  // A_11_11
                            A[0][1] <= {5'b00000, dout_a[1]};  // A_11_12
                            A[0][2] <= {5'b00000, dout_a[2]};  // A_11_21
                            A[0][3] <= {5'b00000, dout_a[3]};  // A_11_22
                            
                            // A_12_xx
                            A[0][4] <= {5'b00000, dout_a[4]};  // A_12_11
                            A[0][5] <= {5'b00000, dout_a[5]};  // A_12_12
                            A[0][6] <= {5'b00000, dout_a[6]};  // A_12_21
                            A[0][7] <= {5'b00000, dout_a[7]};  // A_12_22
                            
                            // A_21_xx
                            A[1][0] <= {5'b00000, dout_a[8]};  // A_21_11
                            A[1][1] <= {5'b00000, dout_a[9]};  // A_21_12
                            A[1][2] <= {5'b00000, dout_a[10]}; // A_21_21
                            A[1][3] <= {5'b00000, dout_a[11]}; // A_21_22
                            
                            // A_22_xx
                            A[1][4] <= {5'b00000, dout_a[12]}; // A_22_11
                            A[1][5] <= {5'b00000, dout_a[13]}; // A_22_12
                            A[1][6] <= {5'b00000, dout_a[14]}; // A_22_21
                            A[1][7] <= {5'b00000, dout_a[15]}; // A_22_22
                            
                            // Similarly for B matrix
                            B[0][0] <= {5'b00000, dout_b[0]};  // B_11_11
                            B[0][1] <= {5'b00000, dout_b[1]};  // B_11_12
                            B[0][2] <= {5'b00000, dout_b[2]};  // B_11_21
                            B[0][3] <= {5'b00000, dout_b[3]};  // B_11_22
                            
                            B[0][4] <= {5'b00000, dout_b[4]};  // B_12_11
                            B[0][5] <= {5'b00000, dout_b[5]};  // B_12_12
                            B[0][6] <= {5'b00000, dout_b[6]};  // B_12_21
                            B[0][7] <= {5'b00000, dout_b[7]};  // B_12_22
                            
                            B[1][0] <= {5'b00000, dout_b[8]};  // B_21_11
                            B[1][1] <= {5'b00000, dout_b[9]};  // B_21_12
                            B[1][2] <= {5'b00000, dout_b[10]}; // B_21_21
                            B[1][3] <= {5'b00000, dout_b[11]}; // B_21_22
                            
                            B[1][4] <= {5'b00000, dout_b[12]}; // B_22_11
                            B[1][5] <= {5'b00000, dout_b[13]}; // B_22_12
                            B[1][6] <= {5'b00000, dout_b[14]}; // B_22_21
                            B[1][7] <= {5'b00000, dout_b[15]}; // B_22_22
                        end
                        
                        read_addr <= read_addr + 1;
                    end else begin
                        // Disable all BRAMs when we're done
                        for (int i = 0; i < 16; i++) begin
                            ena_a[i] <= 0;
                            ena_b[i] <= 0;
                        end
                        loading_matrices_done <= 1;
                    end
                end


                SPLIT_MATRICES: begin
                    // Split A and B into quadrants
                    for (i = 0; i < 8; i++) begin
                        for (j = 0; j < 8; j++) begin
                            // Split A
                            A11[i][j] <= A[i][j];
                            A12[i][j] <= A[i][j+8];
                            A21[i][j] <= A[i+8][j];
                            A22[i][j] <= A[i+8][j+8];
                            
                            // Split B
                            B11[i][j] <= B[i][j];
                            B12[i][j] <= B[i][j+8];
                            B21[i][j] <= B[i+8][j];
                            B22[i][j] <= B[i+8][j+8];
                            if(i==7 && j==7) begin
                                SPLIT_MATRICES_done <= 1;
                            end
                        end
                    end
                end
                
                COMPUTE_TS_LEVEL1: begin
                    // Compute T matrices for level 1
                    for (i = 0; i < 8; i++) begin
                        for (j = 0; j < 8; j++) begin
                            // T1 = A11 + A22
                            T1_L1[i][j] <= A11[i][j] + A22[i][j];
                            // T2 = A21 + A22
                            T2_L1[i][j] <= A21[i][j] + A22[i][j];
                            // T3 = A11
                            T3_L1[i][j] <= A11[i][j];
                            // T4 = A22
                            T4_L1[i][j] <= A22[i][j];
                            // T5 = A11 + A12
                            T5_L1[i][j] <= A11[i][j] + A12[i][j];
                            // T6 = A21 - A11
                            T6_L1[i][j] <= A21[i][j] - A11[i][j];
                            // T7 = A12 - A22
                            T7_L1[i][j] <= A12[i][j] - A22[i][j];
                            
                            // Compute S matrices for level 1
                            // S1 = B11 + B22
                            S1_L1[i][j] <= B11[i][j] + B22[i][j];
                            // S2 = B11
                            S2_L1[i][j] <= B11[i][j];
                            // S3 = B12 - B22
                            S3_L1[i][j] <= B12[i][j] - B22[i][j];
                            // S4 = B21 - B11
                            S4_L1[i][j] <= B21[i][j] - B11[i][j];
                            // S5 = B22
                            S5_L1[i][j] <= B22[i][j];
                            // S6 = B11 + B12
                            S6_L1[i][j] <= B11[i][j] + B12[i][j];
                            // S7 = B21 + B22
                            S7_L1[i][j] <= B21[i][j] + B22[i][j];

                            if(i==7 && j==7) begin
                                COMPUTE_TS_LEVEL1_done <= 1;
                            end
                        end
                    end
                end
                
                PROCESS_LEVEL2: begin
                            if (!l2_start_1 && !l2_done_1 && !l2_start_2 && !l2_done_2 && !l2_start_3 && !l2_done_3 && !l2_start_4 && !l2_done_4 && !l2_start_5 && !l2_done_5 && !l2_start_6 && !l2_done_6 && !l2_start_7 && !l2_done_7) begin
                                // Set inputs for level 2 processor
                                for (i = 0; i < 8; i++) begin
                                    for (j = 0; j < 8; j++) begin
                                        T_in_1[i][j] <= T1_L1[i][j];
                                        S_in_1[i][j] <= S1_L1[i][j];
                                        T_in_2[i][j] <= T2_L1[i][j];
                                        S_in_2[i][j] <= S2_L1[i][j];
                                        T_in_3[i][j] <= T3_L1[i][j];
                                        S_in_3[i][j] <= S3_L1[i][j];
                                        T_in_4[i][j] <= T4_L1[i][j];
                                        S_in_4[i][j] <= S4_L1[i][j];
                                        T_in_5[i][j] <= T5_L1[i][j];
                                        S_in_5[i][j] <= S5_L1[i][j];
                                        T_in_6[i][j] <= T6_L1[i][j];
                                        S_in_6[i][j] <= S6_L1[i][j];
                                        T_in_7[i][j] <= T7_L1[i][j];
                                        S_in_7[i][j] <= S7_L1[i][j];
                                    end
                                end
                                l2_start_1 <= 1;
                                l2_start_2 <= 1;
                                l2_start_3 <= 1;
                                l2_start_5 <= 1;
                                l2_start_4 <= 1;
                                l2_start_6 <= 1;
                                l2_start_7 <= 1;

                            end else if (l2_start_1 && l2_done_1 && l2_start_2 && l2_done_2 && l2_start_3 && l2_done_3 && l2_start_4 && l2_done_4 && l2_start_5 && l2_done_5 && l2_start_6 && l2_done_6 && l2_start_7 && l2_done_7) begin
                                // Store result
                                for (i = 0; i < 8; i++) begin
                                    for (j = 0; j < 8; j++) begin
                                        Q1_L1[i][j] <= Q_out_1[i][j];
                                        Q2_L1[i][j] <= Q_out_2[i][j];
                                        Q3_L1[i][j] <= Q_out_3[i][j];
                                        Q4_L1[i][j] <= Q_out_4[i][j];
                                        Q5_L1[i][j] <= Q_out_5[i][j];
                                        Q6_L1[i][j] <= Q_out_6[i][j];
                                        Q7_L1[i][j] <= Q_out_7[i][j];

                                    end
                                end
                                l2_start_1 <= 0;
                                l2_start_2 <= 0;
                                l2_start_3 <= 0;
                                l2_start_5 <= 0;
                                l2_start_4 <= 0;
                                l2_start_6 <= 0;
                                l2_start_7 <= 0;
                                l2_processing_done <= 1;
                            end
                        end                
                COMPUTE_Q_LEVEL1: begin
                    // Compute C matrices using Q matrices
                    for (i = 0; i < 8; i++) begin
                        for (j = 0; j < 8; j++) begin
                            // C11 = Q1 + Q4 - Q5 + Q7
                            C11[i][j] <= Q1_L1[i][j] + Q4_L1[i][j] - Q5_L1[i][j] + Q7_L1[i][j];
                            // C12 = Q3 + Q5
                            C12[i][j] <= Q3_L1[i][j] + Q5_L1[i][j];
                            // C21 = Q2 + Q4
                            C21[i][j] <= Q2_L1[i][j] + Q4_L1[i][j];
                            // C22 = Q1 - Q2 + Q3 + Q6
                            C22[i][j] <= Q1_L1[i][j] - Q2_L1[i][j] + Q3_L1[i][j] + Q6_L1[i][j];

                            if(i==7 && j==7) begin
                                COMPUTE_Q_LEVEL1_done <= 1;
                            end
                        end
                    end
                end
                
                COMBINE_RESULTS: begin
                    // Combine C11, C12, C21, C22 into final result C
                    for (i = 0; i < 8; i++) begin
                        for (j = 0; j < 8; j++) begin
                            C[i][j] <= C11[i][j];
                            C[i][j+8] <= C12[i][j];
                            C[i+8][j] <= C21[i][j];
                            C[i+8][j+8] <= C22[i][j];
                            
                            if(i==7 && j==7) begin
                                COMBINE_RESULTS_done <= 1;
                            end
                        end
                    end
                end
                
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end
endmodule

// Level 2 Strassen processor - handles 8x8 matrices using Strassen algorithm
module strassen_level2 (
    input logic clk,
    input logic rst,
    input logic start,
    input logic signed [7:0] T [0:7][0:7],  // 8x8 input matrix T
    input logic signed [7:0] S [0:7][0:7],  // 8x8 input matrix S
    output logic signed [15:0] Q [0:7][0:7],  // 8x8 output matrix Q
    output logic done
);
    // States for the FSM
    typedef enum logic [2:0] {
        IDLE = 3'd0,
        SPLIT_MATRICES = 3'd1,
        COMPUTE_TS = 3'd2,
        COMPUTE_Q_BASE = 3'd3,
        COMPUTE_Q_RESULTS = 3'd4,
        COMBINE_RESULTS = 3'd5,
        DONE = 3'd6
    } state_t;
    
    // Current state
    state_t state, next_state;
    
    // Level 2 matrices (4x4) - now signed
    logic signed [7:0] T11 [0:3][0:3];
    logic signed [7:0] T12 [0:3][0:3];
    logic signed [7:0] T21 [0:3][0:3];
    logic signed [7:0] T22 [0:3][0:3];
    logic signed [7:0] S11 [0:3][0:3];
    logic signed [7:0] S12 [0:3][0:3];
    logic signed [7:0] S21 [0:3][0:3];
    logic signed [7:0] S22 [0:3][0:3];
    
    // Level 2 T and S matrices (4x4) - now signed
    logic signed [7:0] T1_L2 [0:3][0:3];
    logic signed [7:0] T2_L2 [0:3][0:3];
    logic signed [7:0] T3_L2 [0:3][0:3];
    logic signed [7:0] T4_L2 [0:3][0:3];
    logic signed [7:0] T5_L2 [0:3][0:3];
    logic signed [7:0] T6_L2 [0:3][0:3];
    logic signed [7:0] T7_L2 [0:3][0:3];
    
    logic signed [7:0] S1_L2 [0:3][0:3];
    logic signed [7:0] S2_L2 [0:3][0:3];
    logic signed [7:0] S3_L2 [0:3][0:3];
    logic signed [7:0] S4_L2 [0:3][0:3];
    logic signed [7:0] S5_L2 [0:3][0:3];
    logic signed [7:0] S6_L2 [0:3][0:3];
    logic signed [7:0] S7_L2 [0:3][0:3];
    
    // Level 2 Q matrices (4x4) - results of base case multiplications - now signed
    logic signed [15:0] Q1_L2 [0:3][0:3];
    logic signed [15:0] Q2_L2 [0:3][0:3];
    logic signed [15:0] Q3_L2 [0:3][0:3];
    logic signed [15:0] Q4_L2 [0:3][0:3];
    logic signed [15:0] Q5_L2 [0:3][0:3];
    logic signed [15:0] Q6_L2 [0:3][0:3];
    logic signed [15:0] Q7_L2 [0:3][0:3];
    
    // Level 2 C matrices (4x4) - now signed
    logic signed [15:0] C11_L2 [0:3][0:3];
    logic signed [15:0] C12_L2 [0:3][0:3];
    logic signed [15:0] C21_L2 [0:3][0:3];
    logic signed [15:0] C22_L2 [0:3][0:3];
    
    //  Done signals
    logic SPLIT_MATRICES_done, COMPUTE_TS_done, COMPUTE_Q_BASE_done, COMPUTE_Q_RESULTS_done, COMBINE_RESULTS_done;

    logic [1:0] mult_step;
    logic mult_step_init;
    
    // State machine
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        case(state)
            IDLE: 
                next_state = start ? SPLIT_MATRICES : IDLE;
            SPLIT_MATRICES: 
                next_state = SPLIT_MATRICES_done ? COMPUTE_TS : SPLIT_MATRICES;
            COMPUTE_TS: 
                next_state = COMPUTE_TS_done ? COMPUTE_Q_BASE : COMPUTE_TS;
            COMPUTE_Q_BASE: 
                next_state = COMPUTE_Q_BASE_done ?  COMPUTE_Q_RESULTS : COMPUTE_Q_BASE;
            COMPUTE_Q_RESULTS: 
                next_state = COMPUTE_Q_RESULTS_done ? COMBINE_RESULTS   : COMPUTE_Q_RESULTS;
            COMBINE_RESULTS: 
                next_state = COMBINE_RESULTS_done ? DONE : COMBINE_RESULTS;
            DONE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // Main processing
    integer i, j, k;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else begin
            case(state)
                IDLE: begin
                    done <= 0;
                    SPLIT_MATRICES_done <= 0;
                    COMPUTE_TS_done <= 0;
                    COMPUTE_Q_BASE_done <= 0;  
                    COMPUTE_Q_RESULTS_done <= 0;
                    COMBINE_RESULTS_done <= 0;
                    i <= 0;
                    j <= 0;
                    k <= 0;
                    mult_step_init <= 0;
                    
                    for (i = 0; i < 4; i++) begin
                        for (j = 0; j < 4; j++) begin
                            Q1_L2[i][j] <= 16'b0;
                            Q2_L2[i][j] <= 16'b0;
                            Q3_L2[i][j] <= 16'b0;
                            Q4_L2[i][j] <= 16'b0;
                            Q5_L2[i][j] <= 16'b0;
                            Q6_L2[i][j] <= 16'b0;
                            Q7_L2[i][j] <= 16'b0;
                        end
                    end
                end
                SPLIT_MATRICES: begin
                    // Split T and S into quadrants
                    for (i = 0; i < 4; i++) begin
                        for (j = 0; j < 4; j++) begin
                            // Split T
                            T11[i][j] <= T[i][j];
                            T12[i][j] <= T[i][j+4];
                            T21[i][j] <= T[i+4][j];
                            T22[i][j] <= T[i+4][j+4];
                            
                            // Split S
                            S11[i][j] <= S[i][j];
                            S12[i][j] <= S[i][j+4];
                            S21[i][j] <= S[i+4][j];
                            S22[i][j] <= S[i+4][j+4];

                            if(i==3 && j==3) begin
                                SPLIT_MATRICES_done <= 1;
                            end
                        end
                    end
                end
                
                COMPUTE_TS: begin
                    // Compute T matrices for level 2
                    for (i = 0; i < 4; i++) begin
                        for (j = 0; j < 4; j++) begin
                            // T1 = T11 + T22
                            T1_L2[i][j] <= T11[i][j] + T22[i][j];
                            // T2 = T21 + T22
                            T2_L2[i][j] <= T21[i][j] + T22[i][j];
                            // T3 = T11
                            T3_L2[i][j] <= T11[i][j];
                            // T4 = T22
                            T4_L2[i][j] <= T22[i][j];
                            // T5 = T11 + T12
                            T5_L2[i][j] <= T11[i][j] + T12[i][j];
                            // T6 = T21 - T11
                            T6_L2[i][j] <= T21[i][j] - T11[i][j];
                            // T7 = T12 - T22
                            T7_L2[i][j] <= T12[i][j] - T22[i][j];
                            
                            // Compute S matrices for level 2
                            // S1 = S11 + S22
                            S1_L2[i][j] <= S11[i][j] + S22[i][j];
                            // S2 = S11
                            S2_L2[i][j] <= S11[i][j];
                            // S3 = S12 - S22
                            S3_L2[i][j] <= S12[i][j] - S22[i][j];
                            // S4 = S21 - S11
                            S4_L2[i][j] <= S21[i][j] - S11[i][j];
                            // S5 = S22
                            S5_L2[i][j] <= S22[i][j];
                            // S6 = S11 + S12
                            S6_L2[i][j] <= S11[i][j] + S12[i][j];
                            // S7 = S21 + S22
                            S7_L2[i][j] <= S21[i][j] + S22[i][j];

                            if(i==3 && j==3) begin
                                COMPUTE_TS_done <= 1;
                            end
                        end
                    end
                end
                
                /*COMPUTE_Q_BASE: begin
                    // Perform base case matrix multiplications for each
                    // Perform base case matrix multiplications for each Q
                    for (i = 0; i < 4; i++) begin
                        for (j = 0; j < 4; j++) begin
//                            Q1_L2[i][j] <= 16'b0;
//                            Q2_L2[i][j] <= 16'b0;
//                            Q3_L2[i][j] <= 16'b0;
//                            Q4_L2[i][j] <= 16'b0;
//                            Q5_L2[i][j] <= 16'b0;
//                            Q6_L2[i][j] <= 16'b0;
//                            Q7_L2[i][j] <= 16'b0;
                            
                            // Perform standard matrix multiplication for 4x4 matrices
                            for (k = 0; k < 4; k++) begin
                                // Q1 = T1_L2 * S1_L2
                                Q1_L2[i][j] <= Q1_L2[i][j] + T1_L2[i][k] * S1_L2[k][j];
                                // Q2 = T2_L2 * S2_L2
                                Q2_L2[i][j] <= Q2_L2[i][j] + T2_L2[i][k] * S2_L2[k][j];
                                // Q3 = T3_L2 * S3_L2
                                Q3_L2[i][j] <= Q3_L2[i][j] + T3_L2[i][k] * S3_L2[k][j];
                                // Q4 = T4_L2 * S4_L2
                                Q4_L2[i][j] <= Q4_L2[i][j] + T4_L2[i][k] * S4_L2[k][j];
                                // Q5 = T5_L2 * S5_L2
                                Q5_L2[i][j] <= Q5_L2[i][j] + T5_L2[i][k] * S5_L2[k][j];
                                // Q6 = T6_L2 * S6_L2
                                Q6_L2[i][j] <= Q6_L2[i][j] + T6_L2[i][k] * S6_L2[k][j];
                                // Q7 = T7_L2 * S7_L2
                                Q7_L2[i][j] <= Q7_L2[i][j] + T7_L2[i][k] * S7_L2[k][j];
                                
                                
                                if(i==3 && j==3 && k==3 ) begin
                                    COMPUTE_Q_BASE_done <= 1;
                                end
                            end
//                                if(i==3 && j==3 && k==3 ) begin
//                                    COMPUTE_Q_BASE_done <= 1;
//                                end
                        end
                    end
                end*/
                
/*                COMPUTE_Q_BASE: begin
                    if (!mult_step_init) begin
                        // Initialize counter at the start of the state
                        mult_step <= 2'b00;
                        mult_step_init <= 1'b1;
                        COMPUTE_Q_BASE_done <= 1'b0;
                    end
                    else begin
                        // Accumulate results one k at a time, across multiple clock cycles
                        for (i = 0; i < 4; i = i + 1) begin
                            for (j = 0; j < 4; j = j + 1) begin
                                // Only accumulate for the current step (k value)
                                // Q1 = T1_L2 * S1_L2
                                Q1_L2[i][j] <= Q1_L2[i][j] + T1_L2[i][mult_step] * S1_L2[mult_step][j];
                                // Q2 = T2_L2 * S2_L2
                                Q2_L2[i][j] <= Q2_L2[i][j] + T2_L2[i][mult_step] * S2_L2[mult_step][j];
                                // Q3 = T3_L2 * S3_L2
                                Q3_L2[i][j] <= Q3_L2[i][j] + T3_L2[i][mult_step] * S3_L2[mult_step][j];
                                // Q4 = T4_L2 * S4_L2
                                Q4_L2[i][j] <= Q4_L2[i][j] + T4_L2[i][mult_step] * S4_L2[mult_step][j];
                                // Q5 = T5_L2 * S5_L2
                                Q5_L2[i][j] <= Q5_L2[i][j] + T5_L2[i][mult_step] * S5_L2[mult_step][j];
                                // Q6 = T6_L2 * S6_L2
                                Q6_L2[i][j] <= Q6_L2[i][j] + T6_L2[i][mult_step] * S6_L2[mult_step][j];
                                // Q7 = T7_L2 * S7_L2
                                Q7_L2[i][j] <= Q7_L2[i][j] + T7_L2[i][mult_step] * S7_L2[mult_step][j];
                            end
                        end
                        
                        // Increment step counter
                        mult_step <= mult_step + 1'b1;
                        
                        // Check if we've completed all 4 steps (k=0,1,2,3)
                        if (mult_step == 2'b11) begin
//                            COMPUTE_Q_BASE_done <= 1'b1;
                            mult_step_init <= 1'b0; // Reset for next time
                        end
                    end
                end*/
                
                COMPUTE_Q_BASE: begin
                    // Q1 = T1_L2 * S1_L2 (first row)
                    Q1_L2[0][0] <= T1_L2[0][0] * S1_L2[0][0] + T1_L2[0][1] * S1_L2[1][0] + T1_L2[0][2] * S1_L2[2][0] + T1_L2[0][3] * S1_L2[3][0];
                    Q1_L2[0][1] <= T1_L2[0][0] * S1_L2[0][1] + T1_L2[0][1] * S1_L2[1][1] + T1_L2[0][2] * S1_L2[2][1] + T1_L2[0][3] * S1_L2[3][1];
                    Q1_L2[0][2] <= T1_L2[0][0] * S1_L2[0][2] + T1_L2[0][1] * S1_L2[1][2] + T1_L2[0][2] * S1_L2[2][2] + T1_L2[0][3] * S1_L2[3][2];
                    Q1_L2[0][3] <= T1_L2[0][0] * S1_L2[0][3] + T1_L2[0][1] * S1_L2[1][3] + T1_L2[0][2] * S1_L2[2][3] + T1_L2[0][3] * S1_L2[3][3];
                    
                    // Q1 = T1_L2 * S1_L2 (second row)
                    Q1_L2[1][0] <= T1_L2[1][0] * S1_L2[0][0] + T1_L2[1][1] * S1_L2[1][0] + T1_L2[1][2] * S1_L2[2][0] + T1_L2[1][3] * S1_L2[3][0];
                    Q1_L2[1][1] <= T1_L2[1][0] * S1_L2[0][1] + T1_L2[1][1] * S1_L2[1][1] + T1_L2[1][2] * S1_L2[2][1] + T1_L2[1][3] * S1_L2[3][1];
                    Q1_L2[1][2] <= T1_L2[1][0] * S1_L2[0][2] + T1_L2[1][1] * S1_L2[1][2] + T1_L2[1][2] * S1_L2[2][2] + T1_L2[1][3] * S1_L2[3][2];
                    Q1_L2[1][3] <= T1_L2[1][0] * S1_L2[0][3] + T1_L2[1][1] * S1_L2[1][3] + T1_L2[1][2] * S1_L2[2][3] + T1_L2[1][3] * S1_L2[3][3];
                    
                    // Q1 = T1_L2 * S1_L2 (third row)
                    Q1_L2[2][0] <= T1_L2[2][0] * S1_L2[0][0] + T1_L2[2][1] * S1_L2[1][0] + T1_L2[2][2] * S1_L2[2][0] + T1_L2[2][3] * S1_L2[3][0];
                    Q1_L2[2][1] <= T1_L2[2][0] * S1_L2[0][1] + T1_L2[2][1] * S1_L2[1][1] + T1_L2[2][2] * S1_L2[2][1] + T1_L2[2][3] * S1_L2[3][1];
                    Q1_L2[2][2] <= T1_L2[2][0] * S1_L2[0][2] + T1_L2[2][1] * S1_L2[1][2] + T1_L2[2][2] * S1_L2[2][2] + T1_L2[2][3] * S1_L2[3][2];
                    Q1_L2[2][3] <= T1_L2[2][0] * S1_L2[0][3] + T1_L2[2][1] * S1_L2[1][3] + T1_L2[2][2] * S1_L2[2][3] + T1_L2[2][3] * S1_L2[3][3];
                    
                    // Q1 = T1_L2 * S1_L2 (fourth row)
                    Q1_L2[3][0] <= T1_L2[3][0] * S1_L2[0][0] + T1_L2[3][1] * S1_L2[1][0] + T1_L2[3][2] * S1_L2[2][0] + T1_L2[3][3] * S1_L2[3][0];
                    Q1_L2[3][1] <= T1_L2[3][0] * S1_L2[0][1] + T1_L2[3][1] * S1_L2[1][1] + T1_L2[3][2] * S1_L2[2][1] + T1_L2[3][3] * S1_L2[3][1];
                    Q1_L2[3][2] <= T1_L2[3][0] * S1_L2[0][2] + T1_L2[3][1] * S1_L2[1][2] + T1_L2[3][2] * S1_L2[2][2] + T1_L2[3][3] * S1_L2[3][2];
                    Q1_L2[3][3] <= T1_L2[3][0] * S1_L2[0][3] + T1_L2[3][1] * S1_L2[1][3] + T1_L2[3][2] * S1_L2[2][3] + T1_L2[3][3] * S1_L2[3][3];
                    
                    // Q2 = T2_L2 * S2_L2 (first row)
                    Q2_L2[0][0] <= T2_L2[0][0] * S2_L2[0][0] + T2_L2[0][1] * S2_L2[1][0] + T2_L2[0][2] * S2_L2[2][0] + T2_L2[0][3] * S2_L2[3][0];
                    Q2_L2[0][1] <= T2_L2[0][0] * S2_L2[0][1] + T2_L2[0][1] * S2_L2[1][1] + T2_L2[0][2] * S2_L2[2][1] + T2_L2[0][3] * S2_L2[3][1];
                    Q2_L2[0][2] <= T2_L2[0][0] * S2_L2[0][2] + T2_L2[0][1] * S2_L2[1][2] + T2_L2[0][2] * S2_L2[2][2] + T2_L2[0][3] * S2_L2[3][2];
                    Q2_L2[0][3] <= T2_L2[0][0] * S2_L2[0][3] + T2_L2[0][1] * S2_L2[1][3] + T2_L2[0][2] * S2_L2[2][3] + T2_L2[0][3] * S2_L2[3][3];
                    
                    // Q2 = T2_L2 * S2_L2 (second row)
                    Q2_L2[1][0] <= T2_L2[1][0] * S2_L2[0][0] + T2_L2[1][1] * S2_L2[1][0] + T2_L2[1][2] * S2_L2[2][0] + T2_L2[1][3] * S2_L2[3][0];
                    Q2_L2[1][1] <= T2_L2[1][0] * S2_L2[0][1] + T2_L2[1][1] * S2_L2[1][1] + T2_L2[1][2] * S2_L2[2][1] + T2_L2[1][3] * S2_L2[3][1];
                    Q2_L2[1][2] <= T2_L2[1][0] * S2_L2[0][2] + T2_L2[1][1] * S2_L2[1][2] + T2_L2[1][2] * S2_L2[2][2] + T2_L2[1][3] * S2_L2[3][2];
                    Q2_L2[1][3] <= T2_L2[1][0] * S2_L2[0][3] + T2_L2[1][1] * S2_L2[1][3] + T2_L2[1][2] * S2_L2[2][3] + T2_L2[1][3] * S2_L2[3][3];
                    
                    // Q2 = T2_L2 * S2_L2 (third row)
                    Q2_L2[2][0] <= T2_L2[2][0] * S2_L2[0][0] + T2_L2[2][1] * S2_L2[1][0] + T2_L2[2][2] * S2_L2[2][0] + T2_L2[2][3] * S2_L2[3][0];
                    Q2_L2[2][1] <= T2_L2[2][0] * S2_L2[0][1] + T2_L2[2][1] * S2_L2[1][1] + T2_L2[2][2] * S2_L2[2][1] + T2_L2[2][3] * S2_L2[3][1];
                    Q2_L2[2][2] <= T2_L2[2][0] * S2_L2[0][2] + T2_L2[2][1] * S2_L2[1][2] + T2_L2[2][2] * S2_L2[2][2] + T2_L2[2][3] * S2_L2[3][2];
                    Q2_L2[2][3] <= T2_L2[2][0] * S2_L2[0][3] + T2_L2[2][1] * S2_L2[1][3] + T2_L2[2][2] * S2_L2[2][3] + T2_L2[2][3] * S2_L2[3][3];
                    
                    // Q2 = T2_L2 * S2_L2 (fourth row)
                    Q2_L2[3][0] <= T2_L2[3][0] * S2_L2[0][0] + T2_L2[3][1] * S2_L2[1][0] + T2_L2[3][2] * S2_L2[2][0] + T2_L2[3][3] * S2_L2[3][0];
                    Q2_L2[3][1] <= T2_L2[3][0] * S2_L2[0][1] + T2_L2[3][1] * S2_L2[1][1] + T2_L2[3][2] * S2_L2[2][1] + T2_L2[3][3] * S2_L2[3][1];
                    Q2_L2[3][2] <= T2_L2[3][0] * S2_L2[0][2] + T2_L2[3][1] * S2_L2[1][2] + T2_L2[3][2] * S2_L2[2][2] + T2_L2[3][3] * S2_L2[3][2];
                    Q2_L2[3][3] <= T2_L2[3][0] * S2_L2[0][3] + T2_L2[3][1] * S2_L2[1][3] + T2_L2[3][2] * S2_L2[2][3] + T2_L2[3][3] * S2_L2[3][3];
                    
                    // Q3 = T3_L2 * S3_L2 (first row)
                    Q3_L2[0][0] <= T3_L2[0][0] * S3_L2[0][0] + T3_L2[0][1] * S3_L2[1][0] + T3_L2[0][2] * S3_L2[2][0] + T3_L2[0][3] * S3_L2[3][0];
                    Q3_L2[0][1] <= T3_L2[0][0] * S3_L2[0][1] + T3_L2[0][1] * S3_L2[1][1] + T3_L2[0][2] * S3_L2[2][1] + T3_L2[0][3] * S3_L2[3][1];
                    Q3_L2[0][2] <= T3_L2[0][0] * S3_L2[0][2] + T3_L2[0][1] * S3_L2[1][2] + T3_L2[0][2] * S3_L2[2][2] + T3_L2[0][3] * S3_L2[3][2];
                    Q3_L2[0][3] <= T3_L2[0][0] * S3_L2[0][3] + T3_L2[0][1] * S3_L2[1][3] + T3_L2[0][2] * S3_L2[2][3] + T3_L2[0][3] * S3_L2[3][3];
                    
                    // Q3 = T3_L2 * S3_L2 (second row)
                    Q3_L2[1][0] <= T3_L2[1][0] * S3_L2[0][0] + T3_L2[1][1] * S3_L2[1][0] + T3_L2[1][2] * S3_L2[2][0] + T3_L2[1][3] * S3_L2[3][0];
                    Q3_L2[1][1] <= T3_L2[1][0] * S3_L2[0][1] + T3_L2[1][1] * S3_L2[1][1] + T3_L2[1][2] * S3_L2[2][1] + T3_L2[1][3] * S3_L2[3][1];
                    Q3_L2[1][2] <= T3_L2[1][0] * S3_L2[0][2] + T3_L2[1][1] * S3_L2[1][2] + T3_L2[1][2] * S3_L2[2][2] + T3_L2[1][3] * S3_L2[3][2];
                    Q3_L2[1][3] <= T3_L2[1][0] * S3_L2[0][3] + T3_L2[1][1] * S3_L2[1][3] + T3_L2[1][2] * S3_L2[2][3] + T3_L2[1][3] * S3_L2[3][3];
                    
                    // Q3 = T3_L2 * S3_L2 (third row)
                    Q3_L2[2][0] <= T3_L2[2][0] * S3_L2[0][0] + T3_L2[2][1] * S3_L2[1][0] + T3_L2[2][2] * S3_L2[2][0] + T3_L2[2][3] * S3_L2[3][0];
                    Q3_L2[2][1] <= T3_L2[2][0] * S3_L2[0][1] + T3_L2[2][1] * S3_L2[1][1] + T3_L2[2][2] * S3_L2[2][1] + T3_L2[2][3] * S3_L2[3][1];
                    Q3_L2[2][2] <= T3_L2[2][0] * S3_L2[0][2] + T3_L2[2][1] * S3_L2[1][2] + T3_L2[2][2] * S3_L2[2][2] + T3_L2[2][3] * S3_L2[3][2];
                    Q3_L2[2][3] <= T3_L2[2][0] * S3_L2[0][3] + T3_L2[2][1] * S3_L2[1][3] + T3_L2[2][2] * S3_L2[2][3] + T3_L2[2][3] * S3_L2[3][3];
                    
                    // Q3 = T3_L2 * S3_L2 (fourth row)
                    Q3_L2[3][0] <= T3_L2[3][0] * S3_L2[0][0] + T3_L2[3][1] * S3_L2[1][0] + T3_L2[3][2] * S3_L2[2][0] + T3_L2[3][3] * S3_L2[3][0];
                    Q3_L2[3][1] <= T3_L2[3][0] * S3_L2[0][1] + T3_L2[3][1] * S3_L2[1][1] + T3_L2[3][2] * S3_L2[2][1] + T3_L2[3][3] * S3_L2[3][1];
                    Q3_L2[3][2] <= T3_L2[3][0] * S3_L2[0][2] + T3_L2[3][1] * S3_L2[1][2] + T3_L2[3][2] * S3_L2[2][2] + T3_L2[3][3] * S3_L2[3][2];
                    Q3_L2[3][3] <= T3_L2[3][0] * S3_L2[0][3] + T3_L2[3][1] * S3_L2[1][3] + T3_L2[3][2] * S3_L2[2][3] + T3_L2[3][3] * S3_L2[3][3];
                    
                    // Q4 = T4_L2 * S4_L2 (first row)
                    Q4_L2[0][0] <= T4_L2[0][0] * S4_L2[0][0] + T4_L2[0][1] * S4_L2[1][0] + T4_L2[0][2] * S4_L2[2][0] + T4_L2[0][3] * S4_L2[3][0];
                    Q4_L2[0][1] <= T4_L2[0][0] * S4_L2[0][1] + T4_L2[0][1] * S4_L2[1][1] + T4_L2[0][2] * S4_L2[2][1] + T4_L2[0][3] * S4_L2[3][1];
                    Q4_L2[0][2] <= T4_L2[0][0] * S4_L2[0][2] + T4_L2[0][1] * S4_L2[1][2] + T4_L2[0][2] * S4_L2[2][2] + T4_L2[0][3] * S4_L2[3][2];
                    Q4_L2[0][3] <= T4_L2[0][0] * S4_L2[0][3] + T4_L2[0][1] * S4_L2[1][3] + T4_L2[0][2] * S4_L2[2][3] + T4_L2[0][3] * S4_L2[3][3];
                    
                    // Q4 = T4_L2 * S4_L2 (second row)
                    Q4_L2[1][0] <= T4_L2[1][0] * S4_L2[0][0] + T4_L2[1][1] * S4_L2[1][0] + T4_L2[1][2] * S4_L2[2][0] + T4_L2[1][3] * S4_L2[3][0];
                    Q4_L2[1][1] <= T4_L2[1][0] * S4_L2[0][1] + T4_L2[1][1] * S4_L2[1][1] + T4_L2[1][2] * S4_L2[2][1] + T4_L2[1][3] * S4_L2[3][1];
                    Q4_L2[1][2] <= T4_L2[1][0] * S4_L2[0][2] + T4_L2[1][1] * S4_L2[1][2] + T4_L2[1][2] * S4_L2[2][2] + T4_L2[1][3] * S4_L2[3][2];
                    Q4_L2[1][3] <= T4_L2[1][0] * S4_L2[0][3] + T4_L2[1][1] * S4_L2[1][3] + T4_L2[1][2] * S4_L2[2][3] + T4_L2[1][3] * S4_L2[3][3];
                    
                    // Q4 = T4_L2 * S4_L2 (third row)
                    Q4_L2[2][0] <= T4_L2[2][0] * S4_L2[0][0] + T4_L2[2][1] * S4_L2[1][0] + T4_L2[2][2] * S4_L2[2][0] + T4_L2[2][3] * S4_L2[3][0];
                    Q4_L2[2][1] <= T4_L2[2][0] * S4_L2[0][1] + T4_L2[2][1] * S4_L2[1][1] + T4_L2[2][2] * S4_L2[2][1] + T4_L2[2][3] * S4_L2[3][1];
                    Q4_L2[2][2] <= T4_L2[2][0] * S4_L2[0][2] + T4_L2[2][1] * S4_L2[1][2] + T4_L2[2][2] * S4_L2[2][2] + T4_L2[2][3] * S4_L2[3][2];
                    Q4_L2[2][3] <= T4_L2[2][0] * S4_L2[0][3] + T4_L2[2][1] * S4_L2[1][3] + T4_L2[2][2] * S4_L2[2][3] + T4_L2[2][3] * S4_L2[3][3];
                    
                    // Q4 = T4_L2 * S4_L2 (fourth row)
                    Q4_L2[3][0] <= T4_L2[3][0] * S4_L2[0][0] + T4_L2[3][1] * S4_L2[1][0] + T4_L2[3][2] * S4_L2[2][0] + T4_L2[3][3] * S4_L2[3][0];
                    Q4_L2[3][1] <= T4_L2[3][0] * S4_L2[0][1] + T4_L2[3][1] * S4_L2[1][1] + T4_L2[3][2] * S4_L2[2][1] + T4_L2[3][3] * S4_L2[3][1];
                    Q4_L2[3][2] <= T4_L2[3][0] * S4_L2[0][2] + T4_L2[3][1] * S4_L2[1][2] + T4_L2[3][2] * S4_L2[2][2] + T4_L2[3][3] * S4_L2[3][2];
                    Q4_L2[3][3] <= T4_L2[3][0] * S4_L2[0][3] + T4_L2[3][1] * S4_L2[1][3] + T4_L2[3][2] * S4_L2[2][3] + T4_L2[3][3] * S4_L2[3][3];
                    
                    // Q5 = T5_L2 * S5_L2 (first row)
                    Q5_L2[0][0] <= T5_L2[0][0] * S5_L2[0][0] + T5_L2[0][1] * S5_L2[1][0] + T5_L2[0][2] * S5_L2[2][0] + T5_L2[0][3] * S5_L2[3][0];
                    Q5_L2[0][1] <= T5_L2[0][0] * S5_L2[0][1] + T5_L2[0][1] * S5_L2[1][1] + T5_L2[0][2] * S5_L2[2][1] + T5_L2[0][3] * S5_L2[3][1];
                    Q5_L2[0][2] <= T5_L2[0][0] * S5_L2[0][2] + T5_L2[0][1] * S5_L2[1][2] + T5_L2[0][2] * S5_L2[2][2] + T5_L2[0][3] * S5_L2[3][2];
                    Q5_L2[0][3] <= T5_L2[0][0] * S5_L2[0][3] + T5_L2[0][1] * S5_L2[1][3] + T5_L2[0][2] * S5_L2[2][3] + T5_L2[0][3] * S5_L2[3][3];
                    
                    // Q5 = T5_L2 * S5_L2 (second row)
                    Q5_L2[1][0] <= T5_L2[1][0] * S5_L2[0][0] + T5_L2[1][1] * S5_L2[1][0] + T5_L2[1][2] * S5_L2[2][0] + T5_L2[1][3] * S5_L2[3][0];
                    Q5_L2[1][1] <= T5_L2[1][0] * S5_L2[0][1] + T5_L2[1][1] * S5_L2[1][1] + T5_L2[1][2] * S5_L2[2][1] + T5_L2[1][3] * S5_L2[3][1];
                    Q5_L2[1][2] <= T5_L2[1][0] * S5_L2[0][2] + T5_L2[1][1] * S5_L2[1][2] + T5_L2[1][2] * S5_L2[2][2] + T5_L2[1][3] * S5_L2[3][2];
                    Q5_L2[1][3] <= T5_L2[1][0] * S5_L2[0][3] + T5_L2[1][1] * S5_L2[1][3] + T5_L2[1][2] * S5_L2[2][3] + T5_L2[1][3] * S5_L2[3][3];
                    
                    // Q5 = T5_L2 * S5_L2 (third row)
                    Q5_L2[2][0] <= T5_L2[2][0] * S5_L2[0][0] + T5_L2[2][1] * S5_L2[1][0] + T5_L2[2][2] * S5_L2[2][0] + T5_L2[2][3] * S5_L2[3][0];
                    Q5_L2[2][1] <= T5_L2[2][0] * S5_L2[0][1] + T5_L2[2][1] * S5_L2[1][1] + T5_L2[2][2] * S5_L2[2][1] + T5_L2[2][3] * S5_L2[3][1];
                    Q5_L2[2][2] <= T5_L2[2][0] * S5_L2[0][2] + T5_L2[2][1] * S5_L2[1][2] + T5_L2[2][2] * S5_L2[2][2] + T5_L2[2][3] * S5_L2[3][2];
                    Q5_L2[2][3] <= T5_L2[2][0] * S5_L2[0][3] + T5_L2[2][1] * S5_L2[1][3] + T5_L2[2][2] * S5_L2[2][3] + T5_L2[2][3] * S5_L2[3][3];
                    
                    // Q5 = T5_L2 * S5_L2 (fourth row)
                    Q5_L2[3][0] <= T5_L2[3][0] * S5_L2[0][0] + T5_L2[3][1] * S5_L2[1][0] + T5_L2[3][2] * S5_L2[2][0] + T5_L2[3][3] * S5_L2[3][0];
                    Q5_L2[3][1] <= T5_L2[3][0] * S5_L2[0][1] + T5_L2[3][1] * S5_L2[1][1] + T5_L2[3][2] * S5_L2[2][1] + T5_L2[3][3] * S5_L2[3][1];
                    Q5_L2[3][2] <= T5_L2[3][0] * S5_L2[0][2] + T5_L2[3][1] * S5_L2[1][2] + T5_L2[3][2] * S5_L2[2][2] + T5_L2[3][3] * S5_L2[3][2];
                    Q5_L2[3][3] <= T5_L2[3][0] * S5_L2[0][3] + T5_L2[3][1] * S5_L2[1][3] + T5_L2[3][2] * S5_L2[2][3] + T5_L2[3][3] * S5_L2[3][3];
                    
                    // Q6 = T6_L2 * S6_L2 (first row)
                    Q6_L2[0][0] <= T6_L2[0][0] * S6_L2[0][0] + T6_L2[0][1] * S6_L2[1][0] + T6_L2[0][2] * S6_L2[2][0] + T6_L2[0][3] * S6_L2[3][0];
                    Q6_L2[0][1] <= T6_L2[0][0] * S6_L2[0][1] + T6_L2[0][1] * S6_L2[1][1] + T6_L2[0][2] * S6_L2[2][1] + T6_L2[0][3] * S6_L2[3][1];
                    Q6_L2[0][2] <= T6_L2[0][0] * S6_L2[0][2] + T6_L2[0][1] * S6_L2[1][2] + T6_L2[0][2] * S6_L2[2][2] + T6_L2[0][3] * S6_L2[3][2];
                    Q6_L2[0][3] <= T6_L2[0][0] * S6_L2[0][3] + T6_L2[0][1] * S6_L2[1][3] + T6_L2[0][2] * S6_L2[2][3] + T6_L2[0][3] * S6_L2[3][3];
                    
                    // Q6 = T6_L2 * S6_L2 (second row)
                    Q6_L2[1][0] <= T6_L2[1][0] * S6_L2[0][0] + T6_L2[1][1] * S6_L2[1][0] + T6_L2[1][2] * S6_L2[2][0] + T6_L2[1][3] * S6_L2[3][0];
                    Q6_L2[1][1] <= T6_L2[1][0] * S6_L2[0][1] + T6_L2[1][1] * S6_L2[1][1] + T6_L2[1][2] * S6_L2[2][1] + T6_L2[1][3] * S6_L2[3][1];
                    Q6_L2[1][2] <= T6_L2[1][0] * S6_L2[0][2] + T6_L2[1][1] * S6_L2[1][2] + T6_L2[1][2] * S6_L2[2][2] + T6_L2[1][3] * S6_L2[3][2];
                    Q6_L2[1][3] <= T6_L2[1][0] * S6_L2[0][3] + T6_L2[1][1] * S6_L2[1][3] + T6_L2[1][2] * S6_L2[2][3] + T6_L2[1][3] * S6_L2[3][3];
                    
                    // Q6 = T6_L2 * S6_L2 (third row)
                    Q6_L2[2][0] <= T6_L2[2][0] * S6_L2[0][0] + T6_L2[2][1] * S6_L2[1][0] + T6_L2[2][2] * S6_L2[2][0] + T6_L2[2][3] * S6_L2[3][0];
                    Q6_L2[2][1] <= T6_L2[2][0] * S6_L2[0][1] + T6_L2[2][1] * S6_L2[1][1] + T6_L2[2][2] * S6_L2[2][1] + T6_L2[2][3] * S6_L2[3][1];
                    Q6_L2[2][2] <= T6_L2[2][0] * S6_L2[0][2] + T6_L2[2][1] * S6_L2[1][2] + T6_L2[2][2] * S6_L2[2][2] + T6_L2[2][3] * S6_L2[3][2];
                    Q6_L2[2][3] <= T6_L2[2][0] * S6_L2[0][3] + T6_L2[2][1] * S6_L2[1][3] + T6_L2[2][2] * S6_L2[2][3] + T6_L2[2][3] * S6_L2[3][3];
                    
                    // Q6 = T6_L2 * S6_L2 (fourth row)
                    Q6_L2[3][0] <= T6_L2[3][0] * S6_L2[0][0] + T6_L2[3][1] * S6_L2[1][0] + T6_L2[3][2] * S6_L2[2][0] + T6_L2[3][3] * S6_L2[3][0];
                    Q6_L2[3][1] <= T6_L2[3][0] * S6_L2[0][1] + T6_L2[3][1] * S6_L2[1][1] + T6_L2[3][2] * S6_L2[2][1] + T6_L2[3][3] * S6_L2[3][1];
                    Q6_L2[3][2] <= T6_L2[3][0] * S6_L2[0][2] + T6_L2[3][1] * S6_L2[1][2] + T6_L2[3][2] * S6_L2[2][2] + T6_L2[3][3] * S6_L2[3][2];
                    Q6_L2[3][3] <= T6_L2[3][0] * S6_L2[0][3] + T6_L2[3][1] * S6_L2[1][3] + T6_L2[3][2] * S6_L2[2][3] + T6_L2[3][3] * S6_L2[3][3];
                    
                    // Q7 = T7_L2 * S7_L2 (first row)
                    Q7_L2[0][0] <= T7_L2[0][0] * S7_L2[0][0] + T7_L2[0][1] * S7_L2[1][0] + T7_L2[0][2] * S7_L2[2][0] + T7_L2[0][3] * S7_L2[3][0];
                    Q7_L2[0][1] <= T7_L2[0][0] * S7_L2[0][1] + T7_L2[0][1] * S7_L2[1][1] + T7_L2[0][2] * S7_L2[2][1] + T7_L2[0][3] * S7_L2[3][1];
                    Q7_L2[0][2] <= T7_L2[0][0] * S7_L2[0][2] + T7_L2[0][1] * S7_L2[1][2] + T7_L2[0][2] * S7_L2[2][2] + T7_L2[0][3] * S7_L2[3][2];
                    Q7_L2[0][3] <= T7_L2[0][0] * S7_L2[0][3] + T7_L2[0][1] * S7_L2[1][3] + T7_L2[0][2] * S7_L2[2][3] + T7_L2[0][3] * S7_L2[3][3];
                    
                    // Q7 = T7_L2 * S7_L2 (second row)
                    Q7_L2[1][0] <= T7_L2[1][0] * S7_L2[0][0] + T7_L2[1][1] * S7_L2[1][0] + T7_L2[1][2] * S7_L2[2][0] + T7_L2[1][3] * S7_L2[3][0];
                    Q7_L2[1][1] <= T7_L2[1][0] * S7_L2[0][1] + T7_L2[1][1] * S7_L2[1][1] + T7_L2[1][2] * S7_L2[2][1] + T7_L2[1][3] * S7_L2[3][1];
                    Q7_L2[1][2] <= T7_L2[1][0] * S7_L2[0][2] + T7_L2[1][1] * S7_L2[1][2] + T7_L2[1][2] * S7_L2[2][2] + T7_L2[1][3] * S7_L2[3][2];
                    Q7_L2[1][3] <= T7_L2[1][0] * S7_L2[0][3] + T7_L2[1][1] * S7_L2[1][3] + T7_L2[1][2] * S7_L2[2][3] + T7_L2[1][3] * S7_L2[3][3];
                    
                    // Q7 = T7_L2 * S7_L2 (third row)
                    Q7_L2[2][0] <= T7_L2[2][0] * S7_L2[0][0] + T7_L2[2][1] * S7_L2[1][0] + T7_L2[2][2] * S7_L2[2][0] + T7_L2[2][3] * S7_L2[3][0];
                    Q7_L2[2][1] <= T7_L2[2][0] * S7_L2[0][1] + T7_L2[2][1] * S7_L2[1][1] + T7_L2[2][2] * S7_L2[2][1] + T7_L2[2][3] * S7_L2[3][1];
                    Q7_L2[2][2] <= T7_L2[2][0] * S7_L2[0][2] + T7_L2[2][1] * S7_L2[1][2] + T7_L2[2][2] * S7_L2[2][2] + T7_L2[2][3] * S7_L2[3][2];
                    Q7_L2[2][3] <= T7_L2[2][0] * S7_L2[0][3] + T7_L2[2][1] * S7_L2[1][3] + T7_L2[2][2] * S7_L2[2][3] + T7_L2[2][3] * S7_L2[3][3];
                    
                    // Q7 = T7_L2 * S7_L2 (fourth row)
                    Q7_L2[3][0] <= T7_L2[3][0] * S7_L2[0][0] + T7_L2[3][1] * S7_L2[1][0] + T7_L2[3][2] * S7_L2[2][0] + T7_L2[3][3] * S7_L2[3][0];
                    Q7_L2[3][1] <= T7_L2[3][0] * S7_L2[0][1] + T7_L2[3][1] * S7_L2[1][1] + T7_L2[3][2] * S7_L2[2][1] + T7_L2[3][3] * S7_L2[3][1];
                    Q7_L2[3][2] <= T7_L2[3][0] * S7_L2[0][2] + T7_L2[3][1] * S7_L2[1][2] + T7_L2[3][2] * S7_L2[2][2] + T7_L2[3][3] * S7_L2[3][2];
                    Q7_L2[3][3] <= T7_L2[3][0] * S7_L2[0][3] + T7_L2[3][1] * S7_L2[1][3] + T7_L2[3][2] * S7_L2[2][3] + T7_L2[3][3] * S7_L2[3][3];
                    
                    // Set done flag when all calculations are complete
                    COMPUTE_Q_BASE_done <= 1;
                end                                
                
                
                
                COMPUTE_Q_RESULTS: begin
                    // Compute C matrices using Q matrices
                    for (i = 0; i < 4; i++) begin
                        for (j = 0; j < 4; j++) begin
                            // C11 = Q1 + Q4 - Q5 + Q7
                            C11_L2[i][j] <= Q1_L2[i][j] + Q4_L2[i][j] - Q5_L2[i][j] + Q7_L2[i][j];
                            // C12 = Q3 + Q5
                            C12_L2[i][j] <= Q3_L2[i][j] + Q5_L2[i][j];
                            // C21 = Q2 + Q4
                            C21_L2[i][j] <= Q2_L2[i][j] + Q4_L2[i][j];
                            // C22 = Q1 - Q2 + Q3 + Q6
                            C22_L2[i][j] <= Q1_L2[i][j] - Q2_L2[i][j] + Q3_L2[i][j] + Q6_L2[i][j];
                            if(i==3 && j==3) begin
                                COMPUTE_Q_RESULTS_done <= 1;
                            end
                        end
                    end
                end
                
                COMBINE_RESULTS: begin
                    // Combine C11, C12, C21, C22 into final result Q
                    for (i = 0; i < 4; i++) begin
                        for (j = 0; j < 4; j++) begin
                            Q[i][j] <= C11_L2[i][j];
                            Q[i][j+4] <= C12_L2[i][j];
                            Q[i+4][j] <= C21_L2[i][j];
                            Q[i+4][j+4] <= C22_L2[i][j];
                            if(i==3 && j==3) begin
                                COMBINE_RESULTS_done <= 1;
                            end
                        end
                    end
                end
                
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end
endmodule   