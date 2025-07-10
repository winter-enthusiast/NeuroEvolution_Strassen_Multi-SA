module strassen_matrix_mult (
    input logic clk,
    input logic rst,
    input logic start,
    output logic signed [15:0] C [0:15][0:15],
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
                    
                    
                    
//                    A[0][0] <= 8'd3; A[0][1] <= 8'd4; A[0][2] <= 8'd2; A[0][3] <= 8'd4; A[0][4] <= 8'd4; A[0][5] <= 8'd1; A[0][6] <= 8'd2; A[0][7] <= 8'd2; A[0][8] <= 8'd2; A[0][9] <= 8'd4; A[0][10] <= 8'd3; A[0][11] <= 8'd2; A[0][12] <= 8'd5; A[0][13] <= 8'd4; A[0][14] <= 8'd1; A[0][15] <= 8'd3; 
//                    A[1][0] <= 8'd5; A[1][1] <= 8'd5; A[1][2] <= 8'd1; A[1][3] <= 8'd3; A[1][4] <= 8'd4; A[1][5] <= 8'd0; A[1][6] <= 8'd3; A[1][7] <= 8'd1; A[1][8] <= 8'd5; A[1][9] <= 8'd4; A[1][10] <= 8'd3; A[1][11] <= 8'd0; A[1][12] <= 8'd0; A[1][13] <= 8'd2; A[1][14] <= 8'd2; A[1][15] <= 8'd1; 
//                    A[2][0] <= 8'd3; A[2][1] <= 8'd3; A[2][2] <= 8'd5; A[2][3] <= 8'd5; A[2][4] <= 8'd5; A[2][5] <= 8'd2; A[2][6] <= 8'd3; A[2][7] <= 8'd3; A[2][8] <= 8'd0; A[2][9] <= 8'd2; A[2][10] <= 8'd4; A[2][11] <= 8'd2; A[2][12] <= 8'd4; A[2][13] <= 8'd0; A[2][14] <= 8'd1; A[2][15] <= 8'd3; 
//                    A[3][0] <= 8'd0; A[3][1] <= 8'd3; A[3][2] <= 8'd5; A[3][3] <= 8'd1; A[3][4] <= 8'd1; A[3][5] <= 8'd0; A[3][6] <= 8'd1; A[3][7] <= 8'd4; A[3][8] <= 8'd1; A[3][9] <= 8'd3; A[3][10] <= 8'd3; A[3][11] <= 8'd3; A[3][12] <= 8'd3; A[3][13] <= 8'd4; A[3][14] <= 8'd2; A[3][15] <= 8'd5; 
//                    A[4][0] <= 8'd0; A[4][1] <= 8'd3; A[4][2] <= 8'd1; A[4][3] <= 8'd3; A[4][4] <= 8'd1; A[4][5] <= 8'd5; A[4][6] <= 8'd5; A[4][7] <= 8'd5; A[4][8] <= 8'd1; A[4][9] <= 8'd3; A[4][10] <= 8'd5; A[4][11] <= 8'd4; A[4][12] <= 8'd1; A[4][13] <= 8'd1; A[4][14] <= 8'd3; A[4][15] <= 8'd1; 
//                    A[5][0] <= 8'd1; A[5][1] <= 8'd5; A[5][2] <= 8'd3; A[5][3] <= 8'd5; A[5][4] <= 8'd5; A[5][5] <= 8'd3; A[5][6] <= 8'd0; A[5][7] <= 8'd5; A[5][8] <= 8'd4; A[5][9] <= 8'd4; A[5][10] <= 8'd1; A[5][11] <= 8'd4; A[5][12] <= 8'd1; A[5][13] <= 8'd0; A[5][14] <= 8'd3; A[5][15] <= 8'd3; 
//                    A[6][0] <= 8'd3; A[6][1] <= 8'd4; A[6][2] <= 8'd0; A[6][3] <= 8'd4; A[6][4] <= 8'd4; A[6][5] <= 8'd0; A[6][6] <= 8'd0; A[6][7] <= 8'd0; A[6][8] <= 8'd0; A[6][9] <= 8'd3; A[6][10] <= 8'd2; A[6][11] <= 8'd2; A[6][12] <= 8'd0; A[6][13] <= 8'd2; A[6][14] <= 8'd2; A[6][15] <= 8'd0; 
//                    A[7][0] <= 8'd2; A[7][1] <= 8'd4; A[7][2] <= 8'd1; A[7][3] <= 8'd1; A[7][4] <= 8'd0; A[7][5] <= 8'd3; A[7][6] <= 8'd0; A[7][7] <= 8'd3; A[7][8] <= 8'd1; A[7][9] <= 8'd0; A[7][10] <= 8'd5; A[7][11] <= 8'd4; A[7][12] <= 8'd2; A[7][13] <= 8'd3; A[7][14] <= 8'd5; A[7][15] <= 8'd2; 
//                    A[8][0] <= 8'd2; A[8][1] <= 8'd0; A[8][2] <= 8'd2; A[8][3] <= 8'd4; A[8][4] <= 8'd5; A[8][5] <= 8'd2; A[8][6] <= 8'd0; A[8][7] <= 8'd4; A[8][8] <= 8'd1; A[8][9] <= 8'd5; A[8][10] <= 8'd2; A[8][11] <= 8'd0; A[8][12] <= 8'd1; A[8][13] <= 8'd1; A[8][14] <= 8'd3; A[8][15] <= 8'd4; 
//                    A[9][0] <= 8'd2; A[9][1] <= 8'd0; A[9][2] <= 8'd3; A[9][3] <= 8'd4; A[9][4] <= 8'd3; A[9][5] <= 8'd5; A[9][6] <= 8'd4; A[9][7] <= 8'd4; A[9][8] <= 8'd2; A[9][9] <= 8'd4; A[9][10] <= 8'd3; A[9][11] <= 8'd4; A[9][12] <= 8'd2; A[9][13] <= 8'd2; A[9][14] <= 8'd5; A[9][15] <= 8'd3; 
//                    A[10][0] <= 8'd1; A[10][1] <= 8'd1; A[10][2] <= 8'd4; A[10][3] <= 8'd5; A[10][4] <= 8'd0; A[10][5] <= 8'd4; A[10][6] <= 8'd5; A[10][7] <= 8'd3; A[10][8] <= 8'd3; A[10][9] <= 8'd3; A[10][10] <= 8'd3; A[10][11] <= 8'd3; A[10][12] <= 8'd5; A[10][13] <= 8'd5; A[10][14] <= 8'd2; A[10][15] <= 8'd1; 
//                    A[11][0] <= 8'd3; A[11][1] <= 8'd0; A[11][2] <= 8'd5; A[11][3] <= 8'd0; A[11][4] <= 8'd0; A[11][5] <= 8'd0; A[11][6] <= 8'd2; A[11][7] <= 8'd5; A[11][8] <= 8'd0; A[11][9] <= 8'd3; A[11][10] <= 8'd4; A[11][11] <= 8'd0; A[11][12] <= 8'd2; A[11][13] <= 8'd5; A[11][14] <= 8'd2; A[11][15] <= 8'd0; 
//                    A[12][0] <= 8'd5; A[12][1] <= 8'd4; A[12][2] <= 8'd0; A[12][3] <= 8'd2; A[12][4] <= 8'd1; A[12][5] <= 8'd3; A[12][6] <= 8'd2; A[12][7] <= 8'd5; A[12][8] <= 8'd0; A[12][9] <= 8'd3; A[12][10] <= 8'd0; A[12][11] <= 8'd5; A[12][12] <= 8'd0; A[12][13] <= 8'd1; A[12][14] <= 8'd3; A[12][15] <= 8'd3; 
//                    A[13][0] <= 8'd5; A[13][1] <= 8'd1; A[13][2] <= 8'd2; A[13][3] <= 8'd0; A[13][4] <= 8'd4; A[13][5] <= 8'd0; A[13][6] <= 8'd0; A[13][7] <= 8'd2; A[13][8] <= 8'd0; A[13][9] <= 8'd1; A[13][10] <= 8'd1; A[13][11] <= 8'd3; A[13][12] <= 8'd5; A[13][13] <= 8'd4; A[13][14] <= 8'd0; A[13][15] <= 8'd0; 
//                    A[14][0] <= 8'd2; A[14][1] <= 8'd5; A[14][2] <= 8'd1; A[14][3] <= 8'd4; A[14][4] <= 8'd3; A[14][5] <= 8'd1; A[14][6] <= 8'd5; A[14][7] <= 8'd3; A[14][8] <= 8'd2; A[14][9] <= 8'd2; A[14][10] <= 8'd0; A[14][11] <= 8'd5; A[14][12] <= 8'd4; A[14][13] <= 8'd3; A[14][14] <= 8'd1; A[14][15] <= 8'd5; 
//                    A[15][0] <= 8'd5; A[15][1] <= 8'd2; A[15][2] <= 8'd0; A[15][3] <= 8'd0; A[15][4] <= 8'd3; A[15][5] <= 8'd2; A[15][6] <= 8'd5; A[15][7] <= 8'd4; A[15][8] <= 8'd2; A[15][9] <= 8'd3; A[15][10] <= 8'd3; A[15][11] <= 8'd2; A[15][12] <= 8'd3; A[15][13] <= 8'd2; A[15][14] <= 8'd1; A[15][15] <= 8'd2; 

//                    // Loading values for matrix B
//                    B[0][0] <= 8'd2; B[0][1] <= 8'd3; B[0][2] <= 8'd3; B[0][3] <= 8'd0; B[0][4] <= 8'd0; B[0][5] <= 8'd1; B[0][6] <= 8'd0; B[0][7] <= 8'd2; B[0][8] <= 8'd3; B[0][9] <= 8'd0; B[0][10] <= 8'd0; B[0][11] <= 8'd1; B[0][12] <= 8'd5; B[0][13] <= 8'd1; B[0][14] <= 8'd2; B[0][15] <= 8'd3; 
//                    B[1][0] <= 8'd1; B[1][1] <= 8'd0; B[1][2] <= 8'd3; B[1][3] <= 8'd3; B[1][4] <= 8'd0; B[1][5] <= 8'd1; B[1][6] <= 8'd0; B[1][7] <= 8'd5; B[1][8] <= 8'd3; B[1][9] <= 8'd4; B[1][10] <= 8'd4; B[1][11] <= 8'd2; B[1][12] <= 8'd0; B[1][13] <= 8'd0; B[1][14] <= 8'd2; B[1][15] <= 8'd2; 
//                    B[2][0] <= 8'd2; B[2][1] <= 8'd3; B[2][2] <= 8'd5; B[2][3] <= 8'd0; B[2][4] <= 8'd3; B[2][5] <= 8'd2; B[2][6] <= 8'd0; B[2][7] <= 8'd3; B[2][8] <= 8'd5; B[2][9] <= 8'd3; B[2][10] <= 8'd5; B[2][11] <= 8'd2; B[2][12] <= 8'd5; B[2][13] <= 8'd0; B[2][14] <= 8'd2; B[2][15] <= 8'd0; 
//                    B[3][0] <= 8'd4; B[3][1] <= 8'd1; B[3][2] <= 8'd5; B[3][3] <= 8'd1; B[3][4] <= 8'd1; B[3][5] <= 8'd5; B[3][6] <= 8'd2; B[3][7] <= 8'd4; B[3][8] <= 8'd0; B[3][9] <= 8'd3; B[3][10] <= 8'd0; B[3][11] <= 8'd3; B[3][12] <= 8'd0; B[3][13] <= 8'd5; B[3][14] <= 8'd4; B[3][15] <= 8'd3; 
//                    B[4][0] <= 8'd2; B[4][1] <= 8'd0; B[4][2] <= 8'd0; B[4][3] <= 8'd3; B[4][4] <= 8'd2; B[4][5] <= 8'd2; B[4][6] <= 8'd5; B[4][7] <= 8'd5; B[4][8] <= 8'd5; B[4][9] <= 8'd5; B[4][10] <= 8'd5; B[4][11] <= 8'd5; B[4][12] <= 8'd4; B[4][13] <= 8'd2; B[4][14] <= 8'd5; B[4][15] <= 8'd2; 
//                    B[5][0] <= 8'd2; B[5][1] <= 8'd1; B[5][2] <= 8'd4; B[5][3] <= 8'd5; B[5][4] <= 8'd0; B[5][5] <= 8'd3; B[5][6] <= 8'd0; B[5][7] <= 8'd4; B[5][8] <= 8'd3; B[5][9] <= 8'd4; B[5][10] <= 8'd2; B[5][11] <= 8'd3; B[5][12] <= 8'd2; B[5][13] <= 8'd0; B[5][14] <= 8'd0; B[5][15] <= 8'd3; 
//                    B[6][0] <= 8'd3; B[6][1] <= 8'd5; B[6][2] <= 8'd4; B[6][3] <= 8'd5; B[6][4] <= 8'd4; B[6][5] <= 8'd5; B[6][6] <= 8'd2; B[6][7] <= 8'd3; B[6][8] <= 8'd0; B[6][9] <= 8'd4; B[6][10] <= 8'd4; B[6][11] <= 8'd0; B[6][12] <= 8'd5; B[6][13] <= 8'd4; B[6][14] <= 8'd2; B[6][15] <= 8'd3; 
//                    B[7][0] <= 8'd0; B[7][1] <= 8'd3; B[7][2] <= 8'd4; B[7][3] <= 8'd4; B[7][4] <= 8'd0; B[7][5] <= 8'd2; B[7][6] <= 8'd1; B[7][7] <= 8'd0; B[7][8] <= 8'd1; B[7][9] <= 8'd5; B[7][10] <= 8'd1; B[7][11] <= 8'd2; B[7][12] <= 8'd5; B[7][13] <= 8'd1; B[7][14] <= 8'd5; B[7][15] <= 8'd1; 
//                    B[8][0] <= 8'd2; B[8][1] <= 8'd1; B[8][2] <= 8'd1; B[8][3] <= 8'd1; B[8][4] <= 8'd0; B[8][5] <= 8'd0; B[8][6] <= 8'd0; B[8][7] <= 8'd2; B[8][8] <= 8'd5; B[8][9] <= 8'd4; B[8][10] <= 8'd1; B[8][11] <= 8'd1; B[8][12] <= 8'd2; B[8][13] <= 8'd1; B[8][14] <= 8'd0; B[8][15] <= 8'd4; 
//                    B[9][0] <= 8'd3; B[9][1] <= 8'd1; B[9][2] <= 8'd0; B[9][3] <= 8'd3; B[9][4] <= 8'd4; B[9][5] <= 8'd3; B[9][6] <= 8'd0; B[9][7] <= 8'd5; B[9][8] <= 8'd5; B[9][9] <= 8'd3; B[9][10] <= 8'd2; B[9][11] <= 8'd3; B[9][12] <= 8'd1; B[9][13] <= 8'd1; B[9][14] <= 8'd5; B[9][15] <= 8'd2; 
//                    B[10][0] <= 8'd0; B[10][1] <= 8'd1; B[10][2] <= 8'd5; B[10][3] <= 8'd4; B[10][4] <= 8'd5; B[10][5] <= 8'd1; B[10][6] <= 8'd1; B[10][7] <= 8'd5; B[10][8] <= 8'd0; B[10][9] <= 8'd3; B[10][10] <= 8'd1; B[10][11] <= 8'd5; B[10][12] <= 8'd5; B[10][13] <= 8'd2; B[10][14] <= 8'd3; B[10][15] <= 8'd4; 
//                    B[11][0] <= 8'd0; B[11][1] <= 8'd4; B[11][2] <= 8'd3; B[11][3] <= 8'd3; B[11][4] <= 8'd3; B[11][5] <= 8'd4; B[11][6] <= 8'd3; B[11][7] <= 8'd5; B[11][8] <= 8'd4; B[11][9] <= 8'd3; B[11][10] <= 8'd5; B[11][11] <= 8'd2; B[11][12] <= 8'd3; B[11][13] <= 8'd4; B[11][14] <= 8'd1; B[11][15] <= 8'd3; 
//                    B[12][0] <= 8'd1; B[12][1] <= 8'd5; B[12][2] <= 8'd2; B[12][3] <= 8'd0; B[12][4] <= 8'd2; B[12][5] <= 8'd3; B[12][6] <= 8'd1; B[12][7] <= 8'd1; B[12][8] <= 8'd4; B[12][9] <= 8'd1; B[12][10] <= 8'd4; B[12][11] <= 8'd5; B[12][12] <= 8'd0; B[12][13] <= 8'd3; B[12][14] <= 8'd4; B[12][15] <= 8'd0; 
//                    B[13][0] <= 8'd1; B[13][1] <= 8'd1; B[13][2] <= 8'd0; B[13][3] <= 8'd1; B[13][4] <= 8'd5; B[13][5] <= 8'd5; B[13][6] <= 8'd0; B[13][7] <= 8'd4; B[13][8] <= 8'd4; B[13][9] <= 8'd0; B[13][10] <= 8'd4; B[13][11] <= 8'd4; B[13][12] <= 8'd5; B[13][13] <= 8'd4; B[13][14] <= 8'd2; B[13][15] <= 8'd3; 
//                    B[14][0] <= 8'd1; B[14][1] <= 8'd2; B[14][2] <= 8'd4; B[14][3] <= 8'd5; B[14][4] <= 8'd0; B[14][5] <= 8'd4; B[14][6] <= 8'd5; B[14][7] <= 8'd3; B[14][8] <= 8'd4; B[14][9] <= 8'd0; B[14][10] <= 8'd5; B[14][11] <= 8'd5; B[14][12] <= 8'd5; B[14][13] <= 8'd3; B[14][14] <= 8'd4; B[14][15] <= 8'd3; 
//                    B[15][0] <= 8'd1; B[15][1] <= 8'd1; B[15][2] <= 8'd4; B[15][3] <= 8'd3; B[15][4] <= 8'd0; B[15][5] <= 8'd5; B[15][6] <= 8'd5; B[15][7] <= 8'd4; B[15][8] <= 8'd1; B[15][9] <= 8'd1; B[15][10] <= 8'd5; B[15][11] <= 8'd4; B[15][12] <= 8'd3; B[15][13] <= 8'd1; B[15][14] <= 8'd3; B[15][15] <= 8'd1; 
//                    loading_matrices_done <= 1;
                
                    
                    
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
        PROCESS_SYSTOLIC = 3'd3,
        COMPUTE_Q_RESULTS = 3'd4,
        COMBINE_RESULTS = 3'd5,
        DONE = 3'd6
    } state_t;
    
    parameter SIZE = 4;
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
    
    // Output to 7 parallel systolic arrays
    logic signed [7:0] A1_out [0:3];
    logic signed [7:0] B1_out [0:3];
    logic signed [7:0] A2_out [0:3];
    logic signed [7:0] B2_out [0:3];
    logic signed [7:0] A3_out [0:3];
    logic signed [7:0] B3_out [0:3];
    logic signed [7:0] A4_out [0:3];
    logic signed [7:0] B4_out [0:3];
    logic signed [7:0] A5_out [0:3];
    logic signed [7:0] B5_out [0:3];
    logic signed [7:0] A6_out [0:3];
    logic signed [7:0] B6_out [0:3];
    logic signed [7:0] A7_out [0:3];
    logic signed [7:0] B7_out [0:3];
    logic valid_out;
    logic done1, done2, done3, done4, done5, done6, done7;
    
    logic [3:0] cycle_counter;
    
    // Level 2 C matrices (4x4) - now signed
    logic signed [15:0] C11_L2 [0:3][0:3];
    logic signed [15:0] C12_L2 [0:3][0:3];
    logic signed [15:0] C21_L2 [0:3][0:3];
    logic signed [15:0] C22_L2 [0:3][0:3];
    
    
    //  Done signals
    logic SPLIT_MATRICES_done, COMPUTE_TS_done, COMPUTE_Q_BASE_done, COMPUTE_Q_RESULTS_done, COMBINE_RESULTS_done;

    logic [1:0] mult_step;
    logic mult_step_init;
    
    
       // Instantiate seven systolic arrays
    
    // Systolic Array 1 - P1 = T1*S1
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic1 (
        .A(A1_out),
        .B(B1_out),
        .clk(clk),
        .rst(rst),
        .done(done1),
        .C(Q1_L2)
    );
    
    // Systolic Array 2 - P2 = T2*S2
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic2 (
        .A(A2_out),
        .B(B2_out),
        .clk(clk),
        .rst(rst),
        .done(done2),
        .C(Q2_L2)
    );
    
    // Systolic Array 3 - P3 = T3*S3
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic3 (
        .A(A3_out),
        .B(B3_out),
        .clk(clk),
        .rst(rst),
        .done(done3),
        .C(Q3_L2)
    );
    
    // Systolic Array 4 - P4 = T4*S4
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic4 (
        .A(A4_out),
        .B(B4_out),
        .clk(clk),
        .rst(rst),
        .done(done4),
        .C(Q4_L2)
    );
    
    // Systolic Array 5 - P5 = T5*S5
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic5 (
        .A(A5_out),
        .B(B5_out),
        .clk(clk),
        .rst(rst),
        .done(done5),
        .C(Q5_L2)
    );
    
    // Systolic Array 6 - P6 = T6*S6
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic6 (
        .A(A6_out),
        .B(B6_out),
        .clk(clk),
        .rst(rst),
        .done(done6),
        .C(Q6_L2)
    );
    
    // Systolic Array 7 - P7 = T7*S7
    SystolicArray #(
        .SIZE(4),
        .DATA_WIDTH(8)
    ) systolic7 (
        .A(A7_out),
        .B(B7_out),
        .clk(clk),
        .rst(rst),
        .done(done7),
        .C(Q7_L2)
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
                next_state = start ? SPLIT_MATRICES : IDLE;
            SPLIT_MATRICES: 
                next_state = SPLIT_MATRICES_done ? COMPUTE_TS : SPLIT_MATRICES;
            COMPUTE_TS: 
                next_state = COMPUTE_TS_done ? PROCESS_SYSTOLIC : COMPUTE_TS;
            
            PROCESS_SYSTOLIC: begin
                
                if ((cycle_counter > 2*SIZE ) && done7 && done1 && done2 && done3 && done4 && done5 && done6) begin
                    next_state = COMPUTE_Q_RESULTS;
                end 
                else begin
                    next_state = PROCESS_SYSTOLIC;
                end   
            
            end    
                
//            COMPUTE_Q_BASE: 
//                next_state = COMPUTE_Q_BASE_done ?  COMPUTE_Q_RESULTS : COMPUTE_Q_BASE;
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
                    cycle_counter <= 0;
                    valid_out <= 0;


//                    for (i = 0; i < 4; i++) begin
//                        for (j = 0; j < 4; j++) begin
//                            Q1_L2[i][j] <= 16'b0;
//                            Q2_L2[i][j] <= 16'b0;
//                            Q3_L2[i][j] <= 16'b0;
//                            Q4_L2[i][j] <= 16'b0;
//                            Q5_L2[i][j] <= 16'b0;
//                            Q6_L2[i][j] <= 16'b0;
//                            Q7_L2[i][j] <= 16'b0;
//                        end
//                    end
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
                
                
                PROCESS_SYSTOLIC: begin
                    // Process to feed matrices to all systolic arrays in diagonal pattern
                    if (cycle_counter <= 2*SIZE) begin
                        valid_out <= 1;
                        cycle_counter <= cycle_counter + 1;
                    end
                    else begin
                        valid_out <= 0;
//                        done <= 1;
                    end
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
    
    
    // Output generation for systolic array inputs in diagonal pattern for all 7 pairs
    always_comb begin
        // Default: all inputs are 0
        for (int i = 0; i < SIZE; i++) begin
            A1_out[i] = '0; B1_out[i] = '0;
            A2_out[i] = '0; B2_out[i] = '0;
            A3_out[i] = '0; B3_out[i] = '0;
            A4_out[i] = '0; B4_out[i] = '0;
            A5_out[i] = '0; B5_out[i] = '0;
            A6_out[i] = '0; B6_out[i] = '0;
            A7_out[i] = '0; B7_out[i] = '0;
        end
        
        if (state == PROCESS_SYSTOLIC && valid_out) begin
            // Generate diagonal pattern for all 7 pairs
            case (cycle_counter)
                4'd1: begin // First cycle
                    // Pair 1 (T1*S1)
                    A1_out[0] = T1_L2[0][0];
                    B1_out[0] = S1_L2[0][0];
                    
                    // Pair 2 (T2*S2)
                    A2_out[0] = T2_L2[0][0];
                    B2_out[0] = S2_L2[0][0];
                    
                    // Pair 3 (T3*S3)
                    A3_out[0] = T3_L2[0][0];
                    B3_out[0] = S3_L2[0][0];
                    
                    // Pair 4 (T4*S4)
                    A4_out[0] = T4_L2[0][0];
                    B4_out[0] = S4_L2[0][0];
                    
                    // Pair 5 (T5*S5)
                    A5_out[0] = T5_L2[0][0];
                    B5_out[0] = S5_L2[0][0];
                    
                    // Pair 6 (T6*S6)
                    A6_out[0] = T6_L2[0][0];
                    B6_out[0] = S6_L2[0][0];
                    
                    // Pair 7 (T7*S7)
                    A7_out[0] = T7_L2[0][0];
                    B7_out[0] = S7_L2[0][0];
                end
                
                4'd2: begin // Second cycle
                    // Pair 1 (T1*S1)
                    A1_out[0] = T1_L2[0][1];
                    A1_out[1] = T1_L2[1][0];
                    B1_out[0] = S1_L2[1][0];
                    B1_out[1] = S1_L2[0][1];
                    
                    // Pair 2 (T2*S2)
                    A2_out[0] = T2_L2[0][1];
                    A2_out[1] = T2_L2[1][0];
                    B2_out[0] = S2_L2[1][0];
                    B2_out[1] = S2_L2[0][1];
                    
                    // Pair 3 (T3*S3)
                    A3_out[0] = T3_L2[0][1];
                    A3_out[1] = T3_L2[1][0];
                    B3_out[1] = S3_L2[0][1];
                    B3_out[0] = S3_L2[1][0];
                    
                    // Pair 4 (T4*S4)
                    A4_out[0] = T4_L2[0][1];
                    A4_out[1] = T4_L2[1][0];
                    B4_out[1] = S4_L2[0][1];
                    B4_out[0] = S4_L2[1][0];
                    
                    // Pair 5 (T5*S5)
                    A5_out[0] = T5_L2[0][1];
                    A5_out[1] = T5_L2[1][0];
                    B5_out[1] = S5_L2[0][1];
                    B5_out[0] = S5_L2[1][0];
                    
                    // Pair 6 (T6*S6)
                    A6_out[0] = T6_L2[0][1];
                    A6_out[1] = T6_L2[1][0];
                    B6_out[1] = S6_L2[0][1];
                    B6_out[0] = S6_L2[1][0];
                    
                    // Pair 7 (T7*S7)
                    A7_out[0] = T7_L2[0][1];
                    A7_out[1] = T7_L2[1][0];
                    B7_out[1] = S7_L2[0][1];
                    B7_out[0] = S7_L2[1][0];
                end
                
                4'd3: begin // Third cycle
                    // Pair 1 (T1*S1)
                    A1_out[0] = T1_L2[0][2];
                    A1_out[1] = T1_L2[1][1];
                    A1_out[2] = T1_L2[2][0];
                    B1_out[2] = S1_L2[0][2];
                    B1_out[1] = S1_L2[1][1];
                    B1_out[0] = S1_L2[2][0];
                    
                    // Pair 2 (T2*S2)
                    A2_out[0] = T2_L2[0][2];
                    A2_out[1] = T2_L2[1][1];
                    A2_out[2] = T2_L2[2][0];
                    B2_out[2] = S2_L2[0][2];
                    B2_out[1] = S2_L2[1][1];
                    B2_out[0] = S2_L2[2][0];
                    
                    // Pair 3 (T3*S3)
                    A3_out[0] = T3_L2[0][2];
                    A3_out[1] = T3_L2[1][1];
                    A3_out[2] = T3_L2[2][0];
                    B3_out[2] = S3_L2[0][2];
                    B3_out[1] = S3_L2[1][1];
                    B3_out[0] = S3_L2[2][0];
                    
                    // Pair 4 (T4*S4)
                    A4_out[0] = T4_L2[0][2];
                    A4_out[1] = T4_L2[1][1];
                    A4_out[2] = T4_L2[2][0];
                    B4_out[2] = S4_L2[0][2];
                    B4_out[1] = S4_L2[1][1];
                    B4_out[0] = S4_L2[2][0];
                    
                    // Pair 5 (T5*S5)
                    A5_out[0] = T5_L2[0][2];
                    A5_out[1] = T5_L2[1][1];
                    A5_out[2] = T5_L2[2][0];
                    B5_out[2] = S5_L2[0][2];
                    B5_out[1] = S5_L2[1][1];
                    B5_out[0] = S5_L2[2][0];
                    
                    // Pair 6 (T6*S6)
                    A6_out[0] = T6_L2[0][2];
                    A6_out[1] = T6_L2[1][1];
                    A6_out[2] = T6_L2[2][0];
                    B6_out[2] = S6_L2[0][2];
                    B6_out[1] = S6_L2[1][1];
                    B6_out[0] = S6_L2[2][0];
                    
                    // Pair 7 (T7*S7)
                    A7_out[0] = T7_L2[0][2];
                    A7_out[1] = T7_L2[1][1];
                    A7_out[2] = T7_L2[2][0];
                    B7_out[2] = S7_L2[0][2];
                    B7_out[1] = S7_L2[1][1];
                    B7_out[0] = S7_L2[2][0];
                end
                
                4'd4: begin // Fourth cycle
                    // Pair 1 (T1*S1)
                    A1_out[0] = T1_L2[0][3];
                    A1_out[1] = T1_L2[1][2];
                    A1_out[2] = T1_L2[2][1];
                    A1_out[3] = T1_L2[3][0];
                    B1_out[3] = S1_L2[0][3];
                    B1_out[2] = S1_L2[1][2];
                    B1_out[1] = S1_L2[2][1];
                    B1_out[0] = S1_L2[3][0];
                    
                    // Pair 2 (T2*S2)
                    A2_out[0] = T2_L2[0][3];
                    A2_out[1] = T2_L2[1][2];
                    A2_out[2] = T2_L2[2][1];
                    A2_out[3] = T2_L2[3][0];
                    B2_out[3] = S2_L2[0][3];
                    B2_out[2] = S2_L2[1][2];
                    B2_out[1] = S2_L2[2][1];
                    B2_out[0] = S2_L2[3][0];
                    
                    // Pair 3 (T3*S3)
                    A3_out[0] = T3_L2[0][3];
                    A3_out[1] = T3_L2[1][2];
                    A3_out[2] = T3_L2[2][1];
                    A3_out[3] = T3_L2[3][0];
                    B3_out[3] = S3_L2[0][3];
                    B3_out[2] = S3_L2[1][2];
                    B3_out[1] = S3_L2[2][1];
                    B3_out[0] = S3_L2[3][0];
                    
                    // Pair 4 (T4*S4)
                    A4_out[0] = T4_L2[0][3];
                    A4_out[1] = T4_L2[1][2];
                    A4_out[2] = T4_L2[2][1];
                    A4_out[3] = T4_L2[3][0];
                    B4_out[3] = S4_L2[0][3];
                    B4_out[2] = S4_L2[1][2];
                    B4_out[1] = S4_L2[2][1];
                    B4_out[0] = S4_L2[3][0];
                    
                    // Pair 5 (T5*S5)
                    A5_out[0] = T5_L2[0][3];
                    A5_out[1] = T5_L2[1][2];
                    A5_out[2] = T5_L2[2][1];
                    A5_out[3] = T5_L2[3][0];
                    B5_out[3] = S5_L2[0][3];
                    B5_out[2] = S5_L2[1][2];
                    B5_out[1] = S5_L2[2][1];
                    B5_out[0] = S5_L2[3][0];
                    
                    // Pair 6 (T6*S6)
                    A6_out[0] = T6_L2[0][3];
                    A6_out[1] = T6_L2[1][2];
                    A6_out[2] = T6_L2[2][1];
                    A6_out[3] = T6_L2[3][0];
                    B6_out[3] = S6_L2[0][3];
                    B6_out[2] = S6_L2[1][2];
                    B6_out[1] = S6_L2[2][1];
                    B6_out[0] = S6_L2[3][0];
                    
                    // Pair 7 (T7*S7)
                    A7_out[0] = T7_L2[0][3];
                    A7_out[1] = T7_L2[1][2];
                    A7_out[2] = T7_L2[2][1];
                    A7_out[3] = T7_L2[3][0];
                    B7_out[3] = S7_L2[0][3];
                    B7_out[2] = S7_L2[1][2];
                    B7_out[1] = S7_L2[2][1];
                    B7_out[0] = S7_L2[3][0];
                end
                
                4'd5: begin // Fifth cycle
                    // Pair 1 (T1*S1)
                    A1_out[1] = T1_L2[1][3];
                    A1_out[2] = T1_L2[2][2];
                    A1_out[3] = T1_L2[3][1];
                    B1_out[3] = S1_L2[1][3];
                    B1_out[2] = S1_L2[2][2];
                    B1_out[1] = S1_L2[3][1];
                    
                    // Pair 2 (T2*S2)
                    A2_out[1] = T2_L2[1][3];
                    A2_out[2] = T2_L2[2][2];
                    A2_out[3] = T2_L2[3][1];
                    B2_out[3] = S2_L2[1][3];
                    B2_out[2] = S2_L2[2][2];
                    B2_out[1] = S2_L2[3][1];
                    
                    // Pair 3 (T3*S3)
                    A3_out[1] = T3_L2[1][3];
                    A3_out[2] = T3_L2[2][2];
                    A3_out[3] = T3_L2[3][1];
                    B3_out[3] = S3_L2[1][3];
                    B3_out[2] = S3_L2[2][2];
                    B3_out[1] = S3_L2[3][1];
                    
                    // Pair 4 (T4*S4)
                    A4_out[1] = T4_L2[1][3];
                    A4_out[2] = T4_L2[2][2];
                    A4_out[3] = T4_L2[3][1];
                    B4_out[3] = S4_L2[1][3];
                    B4_out[2] = S4_L2[2][2];
                    B4_out[1] = S4_L2[3][1];
                    
                    // Pair 5 (T5*S5)
                    A5_out[1] = T5_L2[1][3];
                    A5_out[2] = T5_L2[2][2];
                    A5_out[3] = T5_L2[3][1];
                    B5_out[3] = S5_L2[1][3];
                    B5_out[2] = S5_L2[2][2];
                    B5_out[1] = S5_L2[3][1];
                    
                    // Pair 6 (T6*S6)
                    A6_out[1] = T6_L2[1][3];
                    A6_out[2] = T6_L2[2][2];
                    A6_out[3] = T6_L2[3][1];
                    B6_out[3] = S6_L2[1][3];
                    B6_out[2] = S6_L2[2][2];
                    B6_out[1] = S6_L2[3][1];
                    
                    // Pair 7 (T7*S7)
                    A7_out[1] = T7_L2[1][3];
                    A7_out[2] = T7_L2[2][2];
                    A7_out[3] = T7_L2[3][1];
                    B7_out[3] = S7_L2[1][3];
                    B7_out[2] = S7_L2[2][2];
                    B7_out[1] = S7_L2[3][1];
                end
                
                4'd6: begin // Sixth cycle
                    // Pair 1 (T1*S1)
                    A1_out[2] = T1_L2[2][3];
                    A1_out[3] = T1_L2[3][2];
                    B1_out[3] = S1_L2[2][3];
                    B1_out[2] = S1_L2[3][2];
                    
                    // Pair 2 (T2*S2)
                    A2_out[2] = T2_L2[2][3];
                    A2_out[3] = T2_L2[3][2];
                    B2_out[3] = S2_L2[2][3];
                    B2_out[2] = S2_L2[3][2];
                    
                    // Pair 3 (T3*S3)
                    A3_out[2] = T3_L2[2][3];
                    A3_out[3] = T3_L2[3][2];
                    B3_out[3] = S3_L2[2][3];
                    B3_out[2] = S3_L2[3][2];
                    
                    // Pair 4 (T4*S4)
                    A4_out[2] = T4_L2[2][3];
                    A4_out[3] = T4_L2[3][2];
                    B4_out[3] = S4_L2[2][3];
                    B4_out[2] = S4_L2[3][2];
                    
                    // Pair 5 (T5*S5)
                    A5_out[2] = T5_L2[2][3];
                    A5_out[3] = T5_L2[3][2];
                    B5_out[3] = S5_L2[2][3];
                    B5_out[2] = S5_L2[3][2];
                    
                    // Pair 6 (T6*S6)
                    A6_out[2] = T6_L2[2][3];
                    A6_out[3] = T6_L2[3][2];
                    B6_out[3] = S6_L2[2][3];
                    B6_out[2] = S6_L2[3][2];
                    
                    // Pair 7 (T7*S7)
                    A7_out[2] = T7_L2[2][3];
                    A7_out[3] = T7_L2[3][2];
                    B7_out[3] = S7_L2[2][3];
                    B7_out[2] = S7_L2[3][2];
                end
                
                4'd7: begin // Seventh cycle
                    // Pair 1 (T1*S1)
                    A1_out[3] = T1_L2[3][3];
                    B1_out[3] = S1_L2[3][3];
                    
                    // Pair 2 (T2*S2)
                    A2_out[3] = T2_L2[3][3];
                    B2_out[3] = S2_L2[3][3];
                    
                    // Pair 3 (T3*S3)
                    A3_out[3] = T3_L2[3][3];
                    B3_out[3] = S3_L2[3][3];
                    
                    // Pair 4 (T4*S4)
                    A4_out[3] = T4_L2[3][3];
                    B4_out[3] = S4_L2[3][3];
                    
                    // Pair 5 (T5*S5)
                    A5_out[3] = T5_L2[3][3];
                    B5_out[3] = S5_L2[3][3];
                    
                    // Pair 6 (T6*S6)
                    A6_out[3] = T6_L2[3][3];
                    B6_out[3] = S6_L2[3][3];
                    
                    // Pair 7 (T7*S7)
                    A7_out[3] = T7_L2[3][3];
                    B7_out[3] = S7_L2[3][3];
                end
                
                default: begin
                    // Remaining cycles - all zeros
                    // Already handled by default assignments
                end
            endcase
        end
    end
endmodule   