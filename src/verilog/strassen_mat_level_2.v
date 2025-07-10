// Level 2 Strassen processor - handles 8x8 matrices using Strassen algorithm
module strassen_level2 (
    input clk,
    input rst,
    input start,
    input [7:0] T [0:7][0:7],  // 8x8 input matrix T
    input [7:0] S [0:7][0:7],  // 8x8 input matrix S
    output reg [15:0] Q [0:7][0:7],  // 8x8 output matrix Q
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
                    // Split T and S into quadrants
                    for (i = 0; i < 4; i = i + 1) begin
                        for (j = 0; j < 4; j = j + 1) begin
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
                                end
                                
                                DONE: begin
                                    done <= 1;
                                end
                            endcase
                        end
                    end
endmodule