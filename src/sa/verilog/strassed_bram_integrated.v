module strassen_matrix_mult (
    input clk,
    input rst,
    input start,
    output reg done
);

    // States for the main FSM
    localparam IDLE = 3'd0;
    localparam LOADING_MATRICES = 3'd1;
    localparam SPLIT_MATRICES = 3'd2;
    localparam COMPUTE_TS_LEVEL1 = 3'd3;
    localparam PROCESS_LEVEL2 = 3'd4;
    localparam COMPUTE_Q_LEVEL1 = 3'd5;
    localparam COMBINE_RESULTS = 3'd6;
    localparam DONE = 3'd7;
    
    // Current state
    reg [2:0] state;
    reg [2:0] next_state;

    // A and B matrices (16x16)
    reg [7:0] A [0:15][0:15];
    reg [7:0] B [0:15][0:15]; 
    reg [15:0] C [0:15][0:15];
    
    // Level 1 matrices (8x8)
    reg [7:0] A11 [0:7][0:7];
    reg [7:0] A12 [0:7][0:7];
    reg [7:0] A21 [0:7][0:7];
    reg [7:0] A22 [0:7][0:7];
    reg [7:0] B11 [0:7][0:7];
    reg [7:0] B12 [0:7][0:7];
    reg [7:0] B21 [0:7][0:7];
    reg [7:0] B22 [0:7][0:7];
    
    // Level 1 T and S matrices (8x8)
    reg [7:0] T1_L1 [0:7][0:7];
    reg [7:0] T2_L1 [0:7][0:7];
    reg [7:0] T3_L1 [0:7][0:7];
    reg [7:0] T4_L1 [0:7][0:7];
    reg [7:0] T5_L1 [0:7][0:7];
    reg [7:0] T6_L1 [0:7][0:7];
    reg [7:0] T7_L1 [0:7][0:7];
    
    reg [7:0] S1_L1 [0:7][0:7];
    reg [7:0] S2_L1 [0:7][0:7];
    reg [7:0] S3_L1 [0:7][0:7];
    reg [7:0] S4_L1 [0:7][0:7];
    reg [7:0] S5_L1 [0:7][0:7];
    reg [7:0] S6_L1 [0:7][0:7];
    reg [7:0] S7_L1 [0:7][0:7];
    
    // Level 1 Q matrices (8x8)
    reg [15:0] Q1_L1 [0:7][0:7];
    reg [15:0] Q2_L1 [0:7][0:7];
    reg [15:0] Q3_L1 [0:7][0:7];
    reg [15:0] Q4_L1 [0:7][0:7];
    reg [15:0] Q5_L1 [0:7][0:7];
    reg [15:0] Q6_L1 [0:7][0:7];
    reg [15:0] Q7_L1 [0:7][0:7];
    
    // Level 1 C matrices (8x8)
    reg [15:0] C11 [0:7][0:7];
    reg [15:0] C12 [0:7][0:7];
    reg [15:0] C21 [0:7][0:7];
    reg [15:0] C22 [0:7][0:7];
    
    // Control signals for level 2 processing
    reg [2:0] ts_pair_idx_l1;
    reg l2_processing_done;
    
    // Level 2 processing module instance
    reg [7:0] T_in [0:7][0:7];
    reg [7:0] S_in [0:7][0:7];
    wire [15:0] Q_out [0:7][0:7];
    reg l2_start;
    wire l2_done;
    
    // For blk_mem_gen_0
    wire [2:0] douta_0;
    reg [7:0] addra_0;
    reg ena_0;
    reg wea_0;

    // For blk_mem_gen_1
    wire [2:0] douta_1;
    reg [7:0] addra_1;
    reg ena_1;
    reg wea_1;

    // Instantiate BRAMs with distinct signal names
    blk_mem_gen_0 bram0_inst (
    .clka(clk),
    .ena(ena_0),
    .wea(wea_0),
    .addra(addra_0),
    .dina(dina),  // Assuming this is shared if you're not writing
    .douta(douta_0)
    );

    blk_mem_gen_1 bram1_inst (
    .clka(clk),
    .ena(ena_1),
    .wea(wea_1),
    .addra(addra_1),
    .dina(dina),  // Assuming this is shared if you're not writing
    .douta(douta_1)
    );


    strassen_level2 level2_processor (
        .clk(clk),
        .rst(rst),
        .start(l2_start),
        .T(T_in),
        .S(S_in),
        .Q(Q_out),
        .done(l2_done)
    );
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case(state)
            IDLE: 
                next_state = start ? LOADING_MATRICES : IDLE;
            LOADING_MATRICES: 
                next_state = SPLIT_MATRICES;
            SPLIT_MATRICES: 
                next_state = COMPUTE_TS_LEVEL1;
            COMPUTE_TS_LEVEL1: 
                next_state = PROCESS_LEVEL2;
            PROCESS_LEVEL2: 
                next_state = l2_processing_done ? COMPUTE_Q_LEVEL1 : PROCESS_LEVEL2;
            COMPUTE_Q_LEVEL1: 
                next_state = COMBINE_RESULTS;
            COMBINE_RESULTS: 
                next_state = DONE;
            DONE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // Main processing
    integer i, j, k;
    
    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
            ts_pair_idx_l1 <= 0;
            l2_processing_done <= 0;
            l2_start <= 0;
        end else begin
            case(state)

                IDLE: begin
                    done <= 0;
                    ts_pair_idx_l1 <= 0;
                    l2_processing_done <= 0;
                    if (start) begin
                        // Initialize if starting
                        // Initialize variables for reading from block RAMs
                        state <= LOADING;
                        read_addr <= 0;
                        row_counter <= 0;
                        col_counter <= 0;
                        
                        // Set read enable for both BRAMs
                        ena_0 <= 1;
                        ena_1 <= 1;
                        wea_0 <= 0;
                        wea_1 <= 0;
                    end
                end

                LOADING: begin
                if (read_addr < 256) begin
                    // Calculate indices
                    row_counter <= read_addr / 16;
                    col_counter <= read_addr % 16;
                    
                    // Set the address for both BRAMs
                    addra_0 <= read_addr;
                    addra_1 <= read_addr;
                    
                    // On the next clock cycle, capture the output data
                    if (read_addr > 0) begin
                        // The values from the previous cycle are available now
                        A[row_counter][col_counter] <= {5'b00000, douta_0}; // From blk_mem_gen_0
                        B[row_counter][col_counter] <= {5'b00000, douta_1}; // From blk_mem_gen_1
                    end
                    
                    read_addr <= read_addr + 1;
                end else begin
                    state <= SPLIT_MATRICES; 
                    ena_0 <= 0;
                    ena_1 <= 0;
                end
            end          

                SPLIT_MATRICES: begin
                    // Split A and B into quadrants
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8; j = j + 1) begin
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
                        end
                    end
                end
                
                COMPUTE_TS_LEVEL1: begin
                    // Compute T matrices for level 1
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8; j = j + 1) begin
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
                        end
                    end
                end
                
                PROCESS_LEVEL2: begin
                    case(ts_pair_idx_l1)
                        0: begin  // Processing Q1 = T1 * S1
                            if (!l2_start && !l2_done) begin
                                // Set inputs for level 2 processor
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i*8+j] <= T1_L1[i][j];
                                        S_in[i*8+j] <= S1_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                // Store result
                                                                
                                
                                
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q1_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                ts_pair_idx_l1 <= ts_pair_idx_l1 + 1;
                            end
                        end
                        
                        1: begin  // Processing Q2 = T2 * S2
                            if (!l2_start && !l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i][j] <= T2_L1[i][j];
                                        S_in[i][j] <= S2_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q2_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                ts_pair_idx_l1 <= ts_pair_idx_l1 + 1;
                            end
                        end
                        
                        2: begin  // Processing Q3 = T3 * S3
                            if (!l2_start && !l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i][j] <= T3_L1[i][j];
                                        S_in[i][j] <= S3_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q3_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                ts_pair_idx_l1 <= ts_pair_idx_l1 + 1;
                            end
                        end
                        
                        3: begin  // Processing Q4 = T4 * S4
                            if (!l2_start && !l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i][j] <= T4_L1[i][j];
                                        S_in[i][j] <= S4_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q4_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                ts_pair_idx_l1 <= ts_pair_idx_l1 + 1;
                            end
                        end
                        
                        4: begin  // Processing Q5 = T5 * S5
                            if (!l2_start && !l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i][j] <= T5_L1[i][j];
                                        S_in[i][j] <= S5_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q5_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                ts_pair_idx_l1 <= ts_pair_idx_l1 + 1;
                            end
                        end
                        
                        5: begin  // Processing Q6 = T6 * S6
                            if (!l2_start && !l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i][j] <= T6_L1[i][j];
                                        S_in[i][j] <= S6_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q6_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                ts_pair_idx_l1 <= ts_pair_idx_l1 + 1;
                            end
                        end
                        
                        6: begin  // Processing Q7 = T7 * S7
                            if (!l2_start && !l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        T_in[i][j] <= T7_L1[i][j];
                                        S_in[i][j] <= S7_L1[i][j];
                                    end
                                end
                                l2_start <= 1;
                            end else if (l2_start && l2_done) begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    for (j = 0; j < 8; j = j + 1) begin
                                        Q7_L1[i][j] <= Q_out[i][j];
                                    end
                                end
                                l2_start <= 0;
                                l2_processing_done <= 1;  // All Q matrices computed
                            end
                        end
                    endcase
                end
                
                COMPUTE_Q_LEVEL1: begin
                    // Compute C matrices using Q matrices
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8; j = j + 1) begin
                            // C11 = Q1 + Q4 - Q5 + Q7
                            C11[i][j] <= Q1_L1[i][j] + Q4_L1[i][j] - Q5_L1[i][j] + Q7_L1[i][j];
                            // C12 = Q3 + Q5
                            C12[i][j] <= Q3_L1[i][j] + Q5_L1[i][j];
                            // C21 = Q2 + Q4
                            C21[i][j] <= Q2_L1[i][j] + Q4_L1[i][j];
                            // C22 = Q1 - Q2 + Q3 + Q6
                            C22[i][j] <= Q1_L1[i][j] - Q2_L1[i][j] + Q3_L1[i][j] + Q6_L1[i][j];
                        end
                    end
                end
                
                COMBINE_RESULTS: begin
                    // Combine C11, C12, C21, C22 into final result C
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8; j = j + 1) begin
                            C[i][j] <= C11[i][j];
                            C[i][j+8] <= C12[i][j];
                            C[i+8][j] <= C21[i][j];
                            C[i+8][j+8] <= C22[i][j];
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
    input clk,
    input rst,
    input start,
    input [7:0] T [0:63],  // 8x8 input matrix T
    input [7:0] S [0:63],  // 8x8 input matrix S
    output reg [15:0] Q_1D [0:63],  // 8x8 output matrix Q
    output reg done
);

    // States for the FSM
    localparam IDLE = 3'd0;
    localparam SPLIT_MATRICES = 3'd1;
    localparam COMPUTE_TS = 3'd2;
    localparam COMPUTE_Q_BASE = 3'd3;
    localparam COMPUTE_Q_RESULTS = 3'd4;
    localparam COMBINE_RESULTS = 3'd5;
    localparam DONE = 3'd6;
    
    // Current state
    reg [2:0] state;
    reg [2:0] next_state;
    
    // Internal 2D representations
    reg [7:0] T_mat [0:7][0:7];
    reg [7:0] S_mat [0:7][0:7];
    reg [15:0] Q_mat [0:7][0:7];
    
    
    reg [15:0] Q [0:7][0:7];
    
    // Level 2 matrices (4x4)
    reg [7:0] T11 [0:3][0:3];
    reg [7:0] T12 [0:3][0:3];
    reg [7:0] T21 [0:3][0:3];
    reg [7:0] T22 [0:3][0:3];
    reg [7:0] S11 [0:3][0:3];
    reg [7:0] S12 [0:3][0:3];
    reg [7:0] S21 [0:3][0:3];
    reg [7:0] S22 [0:3][0:3];
    
    // Level 2 T and S matrices (4x4)
    reg [7:0] T1_L2 [0:3][0:3];
    reg [7:0] T2_L2 [0:3][0:3];
    reg [7:0] T3_L2 [0:3][0:3];
    reg [7:0] T4_L2 [0:3][0:3];
    reg [7:0] T5_L2 [0:3][0:3];
    reg [7:0] T6_L2 [0:3][0:3];
    reg [7:0] T7_L2 [0:3][0:3];
    
    reg [7:0] S1_L2 [0:3][0:3];
    reg [7:0] S2_L2 [0:3][0:3];
    reg [7:0] S3_L2 [0:3][0:3];
    reg [7:0] S4_L2 [0:3][0:3];
    reg [7:0] S5_L2 [0:3][0:3];
    reg [7:0] S6_L2 [0:3][0:3];
    reg [7:0] S7_L2 [0:3][0:3];
    
    // Level 2 Q matrices (4x4) - results of base case multiplications
    reg [15:0] Q1_L2 [0:3][0:3];
    reg [15:0] Q2_L2 [0:3][0:3];
    reg [15:0] Q3_L2 [0:3][0:3];
    reg [15:0] Q4_L2 [0:3][0:3];
    reg [15:0] Q5_L2 [0:3][0:3];
    reg [15:0] Q6_L2 [0:3][0:3];
    reg [15:0] Q7_L2 [0:3][0:3];
    
    // Level 2 C matrices (4x4)
    reg [15:0] C11_L2 [0:3][0:3];
    reg [15:0] C12_L2 [0:3][0:3];
    reg [15:0] C21_L2 [0:3][0:3];
    reg [15:0] C22_L2 [0:3][0:3];
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case(state)
            IDLE: 
                next_state = start ? SPLIT_MATRICES : IDLE;
            SPLIT_MATRICES: 
                next_state = COMPUTE_TS;
            COMPUTE_TS: 
                next_state = COMPUTE_Q_BASE;
            COMPUTE_Q_BASE: 
                next_state = COMPUTE_Q_RESULTS;
            COMPUTE_Q_RESULTS: 
                next_state = COMBINE_RESULTS;
            COMBINE_RESULTS: 
                next_state = DONE;
            DONE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // Main processing
    integer i, j, k;
    
    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else begin
            case(state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        // Initialize if starting
                    end
                end
                
                SPLIT_MATRICES: begin
                     // Convert 1D input arrays to 2D format
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8; j = j + 1) begin
                            T_mat[i][j] <= T[i * 8 + j];
                            S_mat[i][j] <= S[i * 8 + j];
                        end
                    end
                    
                    // Split T and S into quadrants
                    for (i = 0; i < 4; i = i + 1) begin
                        for (j = 0; j < 4; j = j + 1) begin
                            // Split T
                            T11[i][j] <= T_mat[i][j];
                            T12[i][j] <= T_mat[i][j+4];
                            T21[i][j] <= T_mat[i+4][j];
                            T22[i][j] <= T_mat[i+4][j+4];
                            
                            // Split S
                            S11[i][j] <= S_mat[i][j];
                            S12[i][j] <= S_mat[i][j+4];
                            S21[i][j] <= S_mat[i+4][j];
                            S22[i][j] <= S_mat[i+4][j+4];
                        end
                    end
                end
                
                COMPUTE_TS: begin
                    // Compute T matrices for level 2
                    for (i = 0; i < 4; i = i + 1) begin
                        for (j = 0; j < 4; j = j + 1) begin
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
                        end
                    end
                end
                COMPUTE_Q_BASE: begin
                                    // Perform base case matrix multiplications for each T-S pair
                                    // This is the base case where we use regular matrix multiplication
                                    
                                    // Q1 = T1_L2 * S1_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q1_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q1_L2[i][j] <= Q1_L2[i][j] + T1_L2[i][k] * S1_L2[k][j];
                                            end
                                        end
                                    end
                                    
                                    // Q2 = T2_L2 * S2_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q2_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q2_L2[i][j] <= Q2_L2[i][j] + T2_L2[i][k] * S2_L2[k][j];
                                            end
                                        end
                                    end
                                    
                                    // Q3 = T3_L2 * S3_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q3_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q3_L2[i][j] <= Q3_L2[i][j] + T3_L2[i][k] * S3_L2[k][j];
                                            end
                                        end
                                    end
                                    
                                    // Q4 = T4_L2 * S4_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q4_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q4_L2[i][j] <= Q4_L2[i][j] + T4_L2[i][k] * S4_L2[k][j];
                                            end
                                        end
                                    end
                                    
                                    // Q5 = T5_L2 * S5_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q5_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q5_L2[i][j] <= Q5_L2[i][j] + T5_L2[i][k] * S5_L2[k][j];
                                            end
                                        end
                                    end
                                    
                                    // Q6 = T6_L2 * S6_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q6_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q6_L2[i][j] <= Q6_L2[i][j] + T6_L2[i][k] * S6_L2[k][j];
                                            end
                                        end
                                    end
                                    
                                    // Q7 = T7_L2 * S7_L2
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q7_L2[i][j] <= 0; // Initialize result
                                            for (k = 0; k < 4; k = k + 1) begin
                                                Q7_L2[i][j] <= Q7_L2[i][j] + T7_L2[i][k] * S7_L2[k][j];
                                            end
                                        end
                                    end
                                end
                                
                                COMPUTE_Q_RESULTS: begin
                                    // Compute C matrices using Q matrices (Strassen's combination formulas)
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            // C11 = Q1 + Q4 - Q5 + Q7
                                            C11_L2[i][j] <= Q1_L2[i][j] + Q4_L2[i][j] - Q5_L2[i][j] + Q7_L2[i][j];
                                            // C12 = Q3 + Q5
                                            C12_L2[i][j] <= Q3_L2[i][j] + Q5_L2[i][j];
                                            // C21 = Q2 + Q4
                                            C21_L2[i][j] <= Q2_L2[i][j] + Q4_L2[i][j];
                                            // C22 = Q1 - Q2 + Q3 + Q6
                                            C22_L2[i][j] <= Q1_L2[i][j] - Q2_L2[i][j] + Q3_L2[i][j] + Q6_L2[i][j];
                                        end
                                    end
                                end
                                
                                COMBINE_RESULTS: begin
                                    // Combine C11_L2, C12_L2, C21_L2, C22_L2 into final result Q (8x8)
                                    for (i = 0; i < 4; i = i + 1) begin
                                        for (j = 0; j < 4; j = j + 1) begin
                                            Q[i][j] <= C11_L2[i][j];
                                            Q[i][j+4] <= C12_L2[i][j];
                                            Q[i+4][j] <= C21_L2[i][j];
                                            Q[i+4][j+4] <= C22_L2[i][j];
                                        end
                                    end
                                    
                                     // Flatten 2D Q into 1D Q_1D
                                    for (i = 0; i < 8; i = i + 1) begin
                                        for (j = 0; j < 8; j = j + 1) begin
                                            Q_1D[i * 8 + j] <= Q[i][j];  // Flattening by row-major order
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