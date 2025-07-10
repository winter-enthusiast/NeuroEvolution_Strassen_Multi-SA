module strassen_matrix_mult (
    input clk,
    input rst,
    input start,
    output reg done,
    input reg [7:0] A [0:15][0:15],
    input reg [7:0] B [0:15][0:15], 
    output reg [15:0] C [0:15][0:15]
);

    // States for the main FSM
    localparam IDLE = 3'd0;
    localparam SPLIT_MATRICES = 3'd1;
    localparam COMPUTE_TS_LEVEL1 = 3'd2;
    localparam PROCESS_LEVEL2 = 3'd3;
    localparam COMPUTE_Q_LEVEL1 = 3'd4;
    localparam COMBINE_RESULTS = 3'd5;
    localparam DONE = 3'd6;
    
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
                next_state = start ? SPLIT_MATRICES : IDLE;
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
                                        T_in[i][j] <= T1_L1[i][j];
                                        S_in[i][j] <= S1_L1[i][j];
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
