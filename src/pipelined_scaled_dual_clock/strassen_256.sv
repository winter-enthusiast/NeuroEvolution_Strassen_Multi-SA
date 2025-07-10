module strassen_matrix_mult_top #(
    parameter MAT_A_SIZE = 256,
    parameter MAT_B_SIZE = 256,
    parameter ELEM_BITWIDTH = 8
)(
    input logic fast_clk,
    input logic rst,
    output logic done_final
);
    
    // A matrix components (128x128 submatrices) - assigned from BRAM in different clock cycles
    logic signed [ELEM_BITWIDTH-1:0] A11_1_sync[MAT_A_SIZE/2], A11_2_sync[MAT_A_SIZE/2], A12_1_sync[MAT_A_SIZE/2], A12_2_sync[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] A21_1_sync[MAT_A_SIZE/2], A21_2_sync[MAT_A_SIZE/2], A22_1_sync[MAT_A_SIZE/2], A22_2_sync[MAT_A_SIZE/2];
    
    // B matrix components (128x128 submatrices) - assigned from BRAM in different clock cycles
    logic signed [ELEM_BITWIDTH-1:0] B11_1_sync[MAT_B_SIZE/2], B11_2_sync[MAT_B_SIZE/2], B12_1_sync[MAT_B_SIZE/2], B12_2_sync[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] B21_1_sync[MAT_B_SIZE/2], B21_2_sync[MAT_B_SIZE/2], B22_1_sync[MAT_B_SIZE/2], B22_2_sync[MAT_B_SIZE/2];
    
    // Final synchronized A matrix components - all pairs available simultaneously  
    logic signed [ELEM_BITWIDTH-1:0] A11_1[MAT_A_SIZE/2], A11_2[MAT_A_SIZE/2], A12_1[MAT_A_SIZE/2], A12_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] A21_1[MAT_A_SIZE/2], A21_2[MAT_A_SIZE/2], A22_1[MAT_A_SIZE/2], A22_2[MAT_A_SIZE/2];
    
    // Final synchronized B matrix components - all pairs available simultaneously
    logic signed [ELEM_BITWIDTH-1:0] B11_1[MAT_B_SIZE/2], B11_2[MAT_B_SIZE/2], B12_1[MAT_B_SIZE/2], B12_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] B21_1[MAT_B_SIZE/2], B21_2[MAT_B_SIZE/2], B22_1[MAT_B_SIZE/2], B22_2[MAT_B_SIZE/2];
    
    // Flags to track when each pair is ready
    logic A11_A12_pair1_ready, A11_A12_pair2_ready, A21_A22_pair1_ready, A21_A22_pair2_ready;
    logic B11_B21_pair1_ready, B11_B21_pair2_ready, B12_B22_pair1_ready, B12_B22_pair2_ready;
    
    // Done signals for complete matrix loading
    logic A_matrix_sync_done, B_matrix_sync_done;
    logic matrix_pairs_ready;
    
    // Final result matrix C (256x256)
    logic signed [15:0] C [0:255][0:255];

    // Internal signals for BRAM A - increased address width for 256x256
    logic ena_a;
    logic [0:0] wea_a;
    logic [8:0] addr_a;  // 8 bits for 256 rows
    logic [2047:0] douta_a, din_a_d3, din_b_d3;  // 256 * 8 bits = 2048 bits per row
    
    // Internal signals for BRAM B - increased address width for 256x256
    logic ena_b;
    logic [0:0] wea_b;
    logic [8:0] addr_b;  // 8 bits for 256 rows
    logic [2047:0] douta_b;  // 256 * 8 bits = 2048 bits per row
    
    logic l2_done_1;
    logic l2_done_2;
    logic l2_done_3;
    logic l2_done_4;
    logic l2_done_5;
    logic l2_done_6;
    logic l2_done_7;   

    // T outputs (registered) - 128 elements each for 128x128 submatrices
    logic signed [ELEM_BITWIDTH-1:0] T1_1[MAT_A_SIZE/2], T1_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] T2_1[MAT_A_SIZE/2], T2_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] T3_1[MAT_A_SIZE/2], T3_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] T4_1[MAT_A_SIZE/2], T4_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] T5_1[MAT_A_SIZE/2], T5_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] T6_1[MAT_A_SIZE/2], T6_2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] T7_1[MAT_A_SIZE/2], T7_2[MAT_A_SIZE/2];

    // S outputs (registered) - 128 elements each for 128x128 submatrices
    logic signed [ELEM_BITWIDTH-1:0] S1_1[MAT_B_SIZE/2], S1_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] S2_1[MAT_B_SIZE/2], S2_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] S3_1[MAT_B_SIZE/2], S3_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] S4_1[MAT_B_SIZE/2], S4_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] S5_1[MAT_B_SIZE/2], S5_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] S6_1[MAT_B_SIZE/2], S6_2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH-1:0] S7_1[MAT_B_SIZE/2], S7_2[MAT_B_SIZE/2];
    
    logic l2_processing_done, COMPUTE_Q_LEVEL1_done;
    
    logic l2_start_7;
    logic l2_start_6;
    logic l2_start_4;
    logic l2_start_5;
    logic l2_start_3;
    logic l2_start_2;
    logic l2_start_1;
    
    logic done_bram_4_a;
    logic done_bram_4_b;

    integer i, j, k;
    
    // Level 1 Q matrices (128x128) - signed with wider bit width for multiplication results
    logic signed [15:0] Q1_L1 [0:127][0:127];
    logic signed [15:0] Q2_L1 [0:127][0:127];
    logic signed [15:0] Q3_L1 [0:127][0:127];
    logic signed [15:0] Q4_L1 [0:127][0:127];
    logic signed [15:0] Q5_L1 [0:127][0:127];
    logic signed [15:0] Q6_L1 [0:127][0:127];
    logic signed [15:0] Q7_L1 [0:127][0:127];
    
    // Level 1 C matrices (128x128) - signed
    logic signed [15:0] C11 [0:127][0:127];
    logic signed [15:0] C12 [0:127][0:127];
    logic signed [15:0] C21 [0:127][0:127];
    logic signed [15:0] C22 [0:127][0:127];
    
    logic signed [15:0] Q_out_1 [0:127][0:127];
    logic signed [15:0] Q_out_2 [0:127][0:127];
    logic signed [15:0] Q_out_3 [0:127][0:127];
    logic signed [15:0] Q_out_4 [0:127][0:127];
    logic signed [15:0] Q_out_5 [0:127][0:127];
    logic signed [15:0] Q_out_6 [0:127][0:127];
    logic signed [15:0] Q_out_7 [0:127][0:127];
    
    
    logic [1:0] clk_counter;
    logic clk;
    
    always_ff @(posedge fast_clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 2'd0;
            clk <= 1'b0;
        end else begin
            if (clk_counter == 2'd2) begin
                clk_counter <= 2'd0;
                clk <= ~clk;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end
    
    

    // Instantiate Xilinx Block RAM IP cores with updated parameters for 256x256
    blk_mem_gen_A bram_a_inst (
        .clka(clk),         // input wire clka
        .ena(ena_a),        // input wire ena
        .wea(wea_a),        // input wire [0 : 0] wea
        .addra(addr_a),     // input wire [7 : 0] addra (8 bits for 256 addresses)
        .dina(din_a_d3),    // input wire [2047 : 0] dina (256 * 8 bits)
        .douta(douta_a)     // output wire [2047 : 0] douta
    );
    
    blk_mem_gen_0 bram_b_inst (
        .clka(clk),         // input wire clka
        .ena(ena_b),        // input wire ena
        .wea(wea_b),        // input wire [0 : 0] wea
        .addra(addr_b),     // input wire [7 : 0] addra (8 bits for 256 addresses)
        .dina(din_b_d3),    // input wire [2047 : 0] dina (256 * 8 bits)
        .douta(douta_b)     // output wire [2047 : 0] douta
    );
    
    
    
                
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T1_S1 (
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
//            .start(l2_start_1),
            .T1_1(T1_1),
            .T1_2(T1_2),
            .S1_1(S1_1),
            .S1_2(S1_2),
            .Q(Q_out_1),
            .done(l2_done_1)
        );
        
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T2_S2 (
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
//            .start(l2_start_2),
            .T1_1(T2_1),
            .T1_2(T2_2),
            .S1_1(S2_1),
            .S1_2(S2_2),
            .Q(Q_out_2),
            .done(l2_done_2)
        );
        
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T3_S3 (
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
//            .start(l2_start_3),
            .T1_1(T3_1),
            .T1_2(T3_2),
            .S1_1(S3_1),
            .S1_2(S3_2),
            .Q(Q_out_3),
            .done(l2_done_3)
        );
        
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T4_S4 (
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
//            .start(l2_start_4),
            .T1_1(T4_1),
            .T1_2(T4_2),
            .S1_1(S4_1),
            .S1_2(S4_2),
            .Q(Q_out_4),
            .done(l2_done_4)
        );
        
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T5_S5 (
            .clk(clk),
            .fast_clk(fast_clk),           
            .rst(rst),
//            .start(l2_start_5),
            .T1_1(T5_1),
            .T1_2(T5_2),
            .S1_1(S5_1),
            .S1_2(S5_2),
            .Q(Q_out_5),
            .done(l2_done_5)
        );
        
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T6_S6 (
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
//            .start(l2_start_6),
            .T1_1(T6_1),
            .T1_2(T6_2),
            .S1_1(S6_1),
            .S1_2(S6_2),
            .Q(Q_out_6),
            .done(l2_done_6)
        );
        
        strassen_level2 #(
            .MAT_A_SIZE(128),
            .MAT_B_SIZE(128),
            .ELEM_BITWIDTH(8)
        ) level2_processor_T7_S7 (
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
//            .start(l2_start_7),
            .T1_1(T7_1),
            .T1_2(T7_2),
            .S1_1(S7_1),
            .S1_2(S7_2),
            .Q(Q_out_7),
            .done(l2_done_7)
        );
        
    
    // Address counter for 256 rows
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a <= '0;
            addr_b <= '0;
            ena_a = 1'b1;
            ena_b = 1'b1;
            wea_a <= 0;
            wea_b <= 0;
            din_b_d3 <= 0;
            din_a_d3 <= 0;
            l2_start_1 <= 0;
            l2_start_2 <= 0;
            l2_start_3 <= 0;
            l2_start_5 <= 0;
            l2_start_4 <= 0;
            l2_start_6 <= 0;
            l2_start_7 <= 0;
            
            
        end
        else if(addr_a < 'd259 && addr_b < 'd259) begin  // Count to 255 for 256 rows
            addr_a <= addr_a + 1'b1;
            addr_b <= addr_b + 1'b1;
        end
        else begin
            ena_a <= 1'b0;
            ena_b <= 1'b0;
        end
    end

    // Extract matrix components for 256x256 matrices divided into 128x128 submatrices
    always_comb begin
        // Extracting A and B matrix components using for loops
        // For 256x256 matrices, we need to handle 128 elements per submatrix
        for (int i = 0; i < 128; i++) begin
            // A matrix subcomponents (each element is 8 bits)
            if(addr_a >= 'd2 && addr_b >= 'd2) begin
                
                if((addr_a+ 'd2) % 4 == 0) begin
                    A11_1_sync[i] = douta_a[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A12_1_sync[i] = douta_a[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if((addr_a+ 'd2) % 4 == 1) begin
                    A11_2_sync[i] = douta_a[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A12_2_sync[i] = douta_a[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if((addr_a+ 'd2) % 4 == 2) begin    
                    A21_1_sync[i] = douta_a[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A22_1_sync[i] = douta_a[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if((addr_a+ 'd2) % 4 == 3) begin
                    A21_2_sync[i] = douta_a[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A22_2_sync[i] = douta_a[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                
                // B matrix subcomponents (each element is 8 bits)
                if ((addr_b+ 'd2) % 4 == 0) begin
                    B11_1_sync[i] = douta_b[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B21_1_sync[i] = douta_b[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if ((addr_b+ 'd2) % 4 == 1) begin
                    B11_2_sync[i] = douta_b[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B21_2_sync[i] = douta_b[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if ((addr_b+ 'd2) % 4 == 2) begin    
                    B12_1_sync[i] = douta_b[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B22_1_sync[i] = douta_b[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if ((addr_b+ 'd2) % 4 == 3) begin
                    B12_2_sync[i] = douta_b[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B22_2_sync[i] = douta_b[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
            end
        end
    end
    

    
    // Merged logic for tracking ready flags, generating done signals, and assignments
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all final arrays
            for (int i = 0; i < 128; i++) begin
                A11_1[i] <= 0;
                A11_2[i] <= 0;
                A12_1[i] <= 0;
                A12_2[i] <= 0;
                A21_1[i] <= 0;
                A21_2[i] <= 0;
                A22_1[i] <= 0;
                A22_2[i] <= 0;
                
                B11_1[i] <= 0;
                B11_2[i] <= 0;
                B12_1[i] <= 0;
                B12_2[i] <= 0;
                B21_1[i] <= 0;
                B21_2[i] <= 0;
                B22_1[i] <= 0;
                B22_2[i] <= 0;
            end
        end
        else begin
            // Special case: Immediate assignment when addr is between 2 to 5 inclusive
            if (addr_a >= 'd2 && addr_a < 'd5 && addr_b >= 'd2 && addr_b < 'd5) begin
                // Assign all pairs immediately without waiting for ready signals
                for (int i = 0; i < 128; i++) begin
                    // A matrix final assignments - all pairs available simultaneously
                    A11_1[i] <= A11_1_sync[i];
                    A11_2[i] <= A11_2_sync[i];
                    A12_1[i] <= A12_1_sync[i];
                    A12_2[i] <= A12_2_sync[i];
                    A21_1[i] <= A21_1_sync[i];
                    A21_2[i] <= A21_2_sync[i];
                    A22_1[i] <= A22_1_sync[i];
                    A22_2[i] <= A22_2_sync[i];
                    
                    // B matrix final assignments - all pairs available simultaneously
                    B11_1[i] <= B11_1_sync[i];
                    B11_2[i] <= B11_2_sync[i];
                    B12_1[i] <= B12_1_sync[i];
                    B12_2[i] <= B12_2_sync[i];
                    B21_1[i] <= B21_1_sync[i];
                    B21_2[i] <= B21_2_sync[i];
                    B22_1[i] <= B22_1_sync[i];
                    B22_2[i] <= B22_2_sync[i];
                end
                
                // Don't set ready flags for addr 2-5, keep them at 0
                // This allows normal operation to continue for subsequent addresses
            end
            // Normal operation: Wait for A21_A22_pair2_ready for addresses > 5
            else if (((addr_a+ 'd2) % 4 == 3) && addr_a >= 'd5 && addr_b >= 'd5) begin
                // Assign all pairs simultaneously when all are ready
                for (int i = 0; i < 128; i++) begin
                    // A matrix final assignments - all pairs available simultaneously
                    A11_1[i] <= A11_1_sync[i];
                    A11_2[i] <= A11_2_sync[i];
                    A12_1[i] <= A12_1_sync[i];
                    A12_2[i] <= A12_2_sync[i];
                    A21_1[i] <= A21_1_sync[i];
                    A21_2[i] <= A21_2_sync[i];
                    A22_1[i] <= A22_1_sync[i];
                    A22_2[i] <= A22_2_sync[i];
                    
                    // B matrix final assignments - all pairs available simultaneously
                    B11_1[i] <= B11_1_sync[i];
                    B11_2[i] <= B11_2_sync[i];
                    B12_1[i] <= B12_1_sync[i];
                    B12_2[i] <= B12_2_sync[i];
                    B21_1[i] <= B21_1_sync[i];
                    B21_2[i] <= B21_2_sync[i];
                    B22_1[i] <= B22_1_sync[i];
                    B22_2[i] <= B22_2_sync[i];
                end
                
            end

        end
    end    
    
    
    
        // =============================================
    // Computation Logic (Registered on posedge clk)
    // =============================================
    always_ff @(posedge clk or posedge rst) begin
        // Compute T values (A matrix operations)
//        if(!l2_start_1 && !l2_done_1 && !l2_start_2 && !l2_done_2 && !l2_start_3 && !l2_done_3 && !l2_start_4 && !l2_done_4 && !l2_start_5 && !l2_done_5 && !l2_start_6 && !l2_done_6 && !l2_start_7 && !l2_done_7 ) begin
//          if(addr_a >= 'd5 && addr_b >= 'd5) begin 
            for (int i = 0; i < MAT_A_SIZE/2; i++) begin
                // Row _1 computations
                T1_1[i] = A11_1[i] + A22_1[i];
                T2_1[i] = A21_1[i] + A22_1[i];
                T3_1[i] = A11_1[i];
                T4_1[i] = A22_1[i];
                T5_1[i] = A11_1[i] + A12_1[i];
                T6_1[i] = A21_1[i] - A11_1[i];
                T7_1[i] = A12_1[i] - A22_1[i];
                
                // Row _2 computations
                T1_2[i] = A11_2[i] + A22_2[i];
                T2_2[i] = A21_2[i] + A22_2[i];
                T3_2[i] = A11_2[i];
                T4_2[i] = A22_2[i];
                T5_2[i] = A11_2[i] + A12_2[i];
                T6_2[i] = A21_2[i] - A11_2[i];
                T7_2[i] = A12_2[i] - A22_2[i];
            end
            
            // Compute S values (B matrix operations)
            for (int i = 0; i < MAT_B_SIZE/2; i++) begin
                // Row _1 computations
                S1_1[i] = B11_1[i] + B22_1[i];
                S2_1[i] = B11_1[i];
                S3_1[i] = B12_1[i] - B22_1[i];
                S4_1[i] = B21_1[i] - B11_1[i];
                S5_1[i] = B22_1[i];
                S6_1[i] = B11_1[i] + B12_1[i];
                S7_1[i] = B21_1[i] + B22_1[i];
                
                // Row _2 computations
                S1_2[i] = B11_2[i] + B22_2[i];
                S2_2[i] = B11_2[i];
                S3_2[i] = B12_2[i] - B22_2[i];
                S4_2[i] = B21_2[i] - B11_2[i];
                S5_2[i] = B22_2[i];
                S6_2[i] = B11_2[i] + B12_2[i];
                S7_2[i] = B21_2[i] + B22_2[i];
            end
//        end
    end 
    
    
    
    always_ff @(posedge clk or posedge rst) begin
            if(rst) begin
                l2_processing_done <= 0;
            end
            else if ( l2_done_1 && l2_done_2 && l2_done_3  && l2_done_4 && l2_done_5 && l2_done_6 && l2_done_7) begin
                // Store result
                for (i = 0; i < 128; i++) begin
                    for (j = 0; j < 128; j++) begin
                        Q1_L1[i][j] <= Q_out_1[i][j];
                        Q2_L1[i][j] <= Q_out_2[i][j];
                        Q3_L1[i][j] <= Q_out_3[i][j];
                        Q4_L1[i][j] <= Q_out_4[i][j];
                        Q5_L1[i][j] <= Q_out_5[i][j];
                        Q6_L1[i][j] <= Q_out_6[i][j];
                        Q7_L1[i][j] <= Q_out_7[i][j];
    
                    end
                end
                
//                l2_start_1 <= 0;
//                l2_start_2 <= 0;
//                l2_start_3 <= 0;
//                l2_start_5 <= 0;
//                l2_start_4 <= 0;
//                l2_start_6 <= 0;
//                l2_start_7 <= 0;
                l2_processing_done <= 1;
            end
    end
    
    
        
    always_ff @(posedge clk or posedge rst) begin
            if(rst) begin 
                COMPUTE_Q_LEVEL1_done <= 0;            
                done_final <= 0;
            end
            else if ( l2_processing_done ) begin
                for (i = 0; i < 128; i++) begin
                    for (j = 0; j < 128; j++) begin
                        // C11 = Q1 + Q4 - Q5 + Q7
                        C11[i][j] <= Q1_L1[i][j] + Q4_L1[i][j] - Q5_L1[i][j] + Q7_L1[i][j];
                        // C12 = Q3 + Q5
                        C12[i][j] <= Q3_L1[i][j] + Q5_L1[i][j];
                        // C21 = Q2 + Q4
                        C21[i][j] <= Q2_L1[i][j] + Q4_L1[i][j];
                        // C22 = Q1 - Q2 + Q3 + Q6
                        C22[i][j] <= Q1_L1[i][j] - Q2_L1[i][j] + Q3_L1[i][j] + Q6_L1[i][j];
                        
                        
                        C[i][j] <= C11[i][j];
                        C[i][j+128] <= C12[i][j];
                        C[i+128][j] <= C21[i][j];
                        C[i+128][j+128] <= C22[i][j];

                        if(i==127 && j==127) begin
                            COMPUTE_Q_LEVEL1_done <= 1;
                            done_final <= 1;                        
                        end
                    end
                end
            end
    end
    
    
    

endmodule








module strassen_level2 #(
    parameter MAT_A_SIZE = 128,
    parameter MAT_B_SIZE = 128,
    parameter ELEM_BITWIDTH = 8
)(
    input logic clk,
    input logic rst,
    input logic fast_clk,
//    input logic start,
    input logic signed [ELEM_BITWIDTH-1:0] T1_1[MAT_A_SIZE], input logic signed [ELEM_BITWIDTH-1:0] T1_2[MAT_A_SIZE], 
    input logic signed [ELEM_BITWIDTH-1:0] S1_1[MAT_B_SIZE], input logic signed [ELEM_BITWIDTH-1:0] S1_2[MAT_B_SIZE],
    output logic signed [(2*ELEM_BITWIDTH)-1:0] Q[0:(MAT_A_SIZE-1)][0:(MAT_B_SIZE-1)],  // doubt array decalration
    output logic done


);


     logic signed [ELEM_BITWIDTH-1:0] A11[MAT_A_SIZE/2];   
     logic signed [ELEM_BITWIDTH-1:0] A12[MAT_A_SIZE/2];  
     logic signed [ELEM_BITWIDTH-1:0] A21[MAT_A_SIZE/2];   
     logic signed [ELEM_BITWIDTH-1:0] A22[MAT_A_SIZE/2];  

     logic signed [ELEM_BITWIDTH-1:0] B11[MAT_B_SIZE/2];   
     logic signed [ELEM_BITWIDTH-1:0] B12[MAT_B_SIZE/2];  
     logic signed [ELEM_BITWIDTH-1:0] B21[MAT_B_SIZE/2];   
     logic signed [ELEM_BITWIDTH-1:0] B22[MAT_B_SIZE/2];  

    // =============================================
    // Registered Output Declarations
    // =============================================

    // T outputs (registered)
    logic signed [ELEM_BITWIDTH:0] T1[MAT_A_SIZE/2], T2[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH:0] T3[MAT_A_SIZE/2], T4[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH:0] T5[MAT_A_SIZE/2], T6[MAT_A_SIZE/2];
    logic signed [ELEM_BITWIDTH:0] T7[MAT_A_SIZE/2];
    
    // S outputs (registered)
    logic signed [ELEM_BITWIDTH:0] S1[MAT_B_SIZE/2], S2[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH:0] S3[MAT_B_SIZE/2], S4[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH:0] S5[MAT_B_SIZE/2], S6[MAT_B_SIZE/2];
    logic signed [ELEM_BITWIDTH:0] S7[MAT_B_SIZE/2];


    // Matrices to store rows over time (64x64)
    logic signed [ELEM_BITWIDTH-1:0] T1_L2 [0:63][0:63], T2_L2 [0:63][0:63];
    logic signed [ELEM_BITWIDTH-1:0] T3_L2 [0:63][0:63], T4_L2 [0:63][0:63];
    logic signed [ELEM_BITWIDTH-1:0] T5_L2 [0:63][0:63], T6_L2 [0:63][0:63];
    logic signed [ELEM_BITWIDTH-1:0] T7_L2 [0:63][0:63];
    
    logic signed [ELEM_BITWIDTH-1:0] S1_L2 [0:63][0:63], S2_L2 [0:63][0:63];
    logic signed [ELEM_BITWIDTH-1:0] S3_L2 [0:63][0:63], S4_L2 [0:63][0:63];
    logic signed [ELEM_BITWIDTH-1:0] S5_L2 [0:63][0:63], S6_L2 [0:63][0:63];
    logic signed [ELEM_BITWIDTH-1:0] S7_L2 [0:63][0:63];

    
    
        // Row index tracker
    logic [8:0] index;    // change  (waiting for all the 64 or 256 row ?)(i think 256)
    logic done1, done2, done3, done4, done5, done6, done7;
    logic [7:0] cycle_counter;  // change(updated)
    logic valid_out;
    logic COMPUTE_Q_RESULTS_done;
    logic done_TS;

    integer i, j, k;



    
    // Input to 7 parallel systolic arrays
    logic signed [ELEM_BITWIDTH-1:0] A1_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B1_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] A2_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B2_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] A3_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B3_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] A4_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B4_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] A5_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B5_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] A6_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B6_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] A7_out [0:63];
    logic signed [ELEM_BITWIDTH-1:0] B7_out [0:63];
    
    
        // Level 2 Q matrices (4x4) - results of base case multiplications - now signed
    logic signed [15:0] Q1_L2 [0:63][0:63];
    logic signed [15:0] Q2_L2 [0:63][0:63];
    logic signed [15:0] Q3_L2 [0:63][0:63];
    logic signed [15:0] Q4_L2 [0:63][0:63];
    logic signed [15:0] Q5_L2 [0:63][0:63];
    logic signed [15:0] Q6_L2 [0:63][0:63];
    logic signed [15:0] Q7_L2 [0:63][0:63];
    
    
    
        // Level 2 C matrices (4x4) - now signed
    logic signed [15:0] C11_L2 [0:63][0:63];
    logic signed [15:0] C12_L2 [0:63][0:63];
    logic signed [15:0] C21_L2 [0:63][0:63];
    logic signed [15:0] C22_L2 [0:63][0:63];
    
    logic COMPUTE_TS_done;
    


           // Instantiate seven systolic arrays
        
        // Systolic Array 1 - P1 = T1*S1
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic1 (
            .A(A1_out),
            .B(B1_out),
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
            .done(done1),
            .C(Q1_L2)
        );
        
        // Systolic Array 2 - P2 = T2*S2
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic2 (
            .A(A2_out),
            .B(B2_out),
            .fast_clk(fast_clk),
            .clk(clk),
            .rst(rst),
            .done(done2),
            .C(Q2_L2)
        );
        
        // Systolic Array 3 - P3 = T3*S3
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic3 (
            .A(A3_out),
            .B(B3_out),
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
            .done(done3),
            .C(Q3_L2)
        );
        
        // Systolic Array 4 - P4 = T4*S4
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic4 (
            .A(A4_out),
            .B(B4_out),
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
            .done(done4),
            .C(Q4_L2)
        );
        
        // Systolic Array 5 - P5 = T5*S5
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic5 (
            .A(A5_out),
            .B(B5_out),
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
            .done(done5),
            .C(Q5_L2)
        );
        
        // Systolic Array 6 - P6 = T6*S6
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic6 (
            .A(A6_out),
            .B(B6_out),
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
            .done(done6),
            .C(Q6_L2)
        );
        
        // Systolic Array 7 - P7 = T7*S7
        SystolicArray #(
            .SIZE(64),
            .DATA_WIDTH(8)
        ) systolic7 (
            .A(A7_out),
            .B(B7_out),
            .clk(clk),
            .fast_clk(fast_clk),
            .rst(rst),
            .done(done7),
            .C(Q7_L2)
        );
        
   
    always_ff @(posedge clk or posedge rst) begin
//        if(start) begin    
            for (int i = 0; i < MAT_A_SIZE/2; i++) begin
                
                A11[i] <= T1_1[i];
                A12[i] <= T1_1[(i+64)];
                A21[i] <= T1_2[(i)];
                A22[i] <= T1_2[(i+64)];
    
    
                B11[i] <= S1_1[i];
                B21[i] <= S1_1[(i+64)];
                B12[i] <= S1_2[(i)];
                B22[i] <= S1_2[(i+64)]; 
    
                
            end 
//        end
    end
        


    
 
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done_TS <= 1'b0;
        end else begin
            // Compute T values (A matrix operations)
            for (int i = 0; i < MAT_A_SIZE/2; i++) begin
                // Row computations
                T1[i] <= A11[i] + A22[i]; // A11, A22, etc. assumed to be defined
                T2[i] <= A21[i] + A22[i];
                T3[i] <= A11[i];
                T4[i] <= A22[i];
                T5[i] <= A11[i] + A12[i];
                T6[i] <= A21[i] - A11[i];
                T7[i] <= A12[i] - A22[i];
            end
        
            // Compute S values (B matrix operations)
            for (int i = 0; i < MAT_B_SIZE/2; i++) begin
                // Row computations
                S1[i] <= B11[i] + B22[i];
                S2[i] <= B11[i];
                S3[i] <= B12[i] - B22[i];
                S4[i] <= B21[i] - B11[i];
                S5[i] <= B22[i];
                S6[i] <= B11[i] + B12[i];
                S7[i] <= B21[i] + B22[i];
            end
            
            // Set done signal after T and S computations
            done_TS <= 1'b1;
        end
    end

    // Counter logic triggered by done_TS
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            index <= 0;
        end else if (done_TS) begin
            index <= index + 'd1;
        end
    end
 
 
 
    
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
//            index <= 0;
            COMPUTE_TS_done <= 0; 
            i <= 0;
            j <= 0;
            k <= 0;
        end else begin 
            if (((index < 'd261 && index > 'd7) && ((index) % 4 == 0)) && (!COMPUTE_TS_done)) begin
                for (int j = 0; j < (256/4); j++) begin
                    T1_L2[((index/4)-'d2)][j] <= T1[j];
                    T2_L2[((index/4)-'d2)][j] <= T2[j];
                    T3_L2[((index/4)-'d2)][j] <= T3[j];
                    T4_L2[((index/4)-'d2)][j] <= T4[j];
                    T5_L2[((index/4)-'d2)][j] <= T5[j];
                    T6_L2[((index/4)-'d2)][j] <= T6[j];
                    T7_L2[((index/4)-'d2)][j] <= T7[j];
    
                    S1_L2[j][((index/4)-'d2)] <= S1[j];
                    S2_L2[j][((index/4)-'d2)] <= S2[j];
                    S3_L2[j][((index/4)-'d2)] <= S3[j];
                    S4_L2[j][((index/4)-'d2)] <= S4[j];
                    S5_L2[j][((index/4)-'d2)] <= S5[j];
                    S6_L2[j][((index/4)-'d2)] <= S6[j];
                    S7_L2[j][((index/4)-'d2)] <= S7[j];
                    
                    if( index == 'd260) begin
                        COMPUTE_TS_done <= 1;
                    end
                    
                end
            end
            
//            index <= index + 'd1;
        
        end
    end
    
        
    // Modified cycle counter logic for 64x64 matrix multiplication
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 0;             
            cycle_counter <= 0;
        end else if ((cycle_counter <= 2*64) && COMPUTE_TS_done) begin  // Changed from 2*4 to 2*64
            cycle_counter <= cycle_counter + 1;
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
    end
    

        
       always_ff @(posedge clk or posedge rst) begin
          if (rst) begin
                done <= 0;
                COMPUTE_Q_RESULTS_done <= 0;
          end    
          else if((cycle_counter > 2*64 ) && done7 && done1 && done2 && done3 && done4 && done5 && done6) begin
                for (i = 0; i < 64; i++) begin
                    for (j = 0; j < 64; j++) begin
                        // C11 = Q1 + Q4 - Q5 + Q7
                        C11_L2[i][j] <= Q1_L2[i][j] + Q4_L2[i][j] - Q5_L2[i][j] + Q7_L2[i][j];
                        // C12 = Q3 + Q5
                        C12_L2[i][j] <= Q3_L2[i][j] + Q5_L2[i][j];
                        // C21 = Q2 + Q4
                        C21_L2[i][j] <= Q2_L2[i][j] + Q4_L2[i][j];
                        // C22 = Q1 - Q2 + Q3 + Q6
                        C22_L2[i][j] <= Q1_L2[i][j] - Q2_L2[i][j] + Q3_L2[i][j] + Q6_L2[i][j];
                        
                        
                        Q[i][j] <= C11_L2[i][j];
                        Q[i][j+64] <= C12_L2[i][j];
                        Q[i+64][j] <= C21_L2[i][j];
                        Q[i+64][j+64] <= C22_L2[i][j];
                        
                        
                        if(i==63 && j==63) begin
                            COMPUTE_Q_RESULTS_done <= 1;
                            done <= 1;

                        end
                    end
                end    
          end
       end
      

      
        
 
    // Modified combinational always block for 64x64 matrix diagonal feeding
    always_comb begin
        // Default: all inputs are 0
        for (int i = 0; i < 64; i++) begin  // Changed from 4 to 64
            A1_out[i] = '0; B1_out[i] = '0;
            A2_out[i] = '0; B2_out[i] = '0;
            A3_out[i] = '0; B3_out[i] = '0;
            A4_out[i] = '0; B4_out[i] = '0;
            A5_out[i] = '0; B5_out[i] = '0;
            A6_out[i] = '0; B6_out[i] = '0;
            A7_out[i] = '0; B7_out[i] = '0;
        end
        
        if (valid_out && COMPUTE_TS_done) begin
            // This pattern feeds data diagonally starting from top-left corner
//            for (int i = 0; i < 64; i++) begin
//                for (int j = 0; j < 64; j++) begin
//                    if (cycle_counter == (i + j + 1)) begin
//                        // Pair 1 (T1*S1)
//                        A1_out[i] = T1_L2[i][j];
//                        B1_out[i] = S1_L2[j][i];
                        
//                        // Pair 2 (T2*S2)
//                        A2_out[i] = T2_L2[i][j];
//                        B2_out[i] = S2_L2[j][i];
                        
//                        // Pair 3 (T3*S3)
//                        A3_out[i] = T3_L2[i][j];
//                        B3_out[i] = S3_L2[j][i];
                        
//                        // Pair 4 (T4*S4)
//                        A4_out[i] = T4_L2[i][j];
//                        B4_out[i] = S4_L2[j][i];
                        
//                        // Pair 5 (T5*S5)
//                        A5_out[i] = T5_L2[i][j];
//                        B5_out[i] = S5_L2[j][i];
                        
//                        // Pair 6 (T6*S6)
//                        A6_out[i] = T6_L2[i][j];
//                        B6_out[i] = S6_L2[j][i];
                        
//                        // Pair 7 (T7*S7)
//                        A7_out[i] = T7_L2[i][j];
//                        B7_out[i] = S7_L2[j][i];
//                    end
//                end
//            end


            for (int diag = 0; diag < 64; diag++) begin
                    if (cycle_counter >= (diag + 1) && cycle_counter <= (diag + 64)) begin
                        int row = cycle_counter - diag - 1;
                        int col = diag;
                        
                        if (row < 64 && col < 64) begin
                            // Pair 1 (T1*S1)
                            A1_out[row] = T1_L2[row][col];
                            B1_out[row] = S1_L2[col][row];
                            
                            // Pair 2 (T2*S2)
                            A2_out[row] = T2_L2[row][col];
                            B2_out[row] = S2_L2[col][row];
                            
                            // Pair 3 (T3*S3)
                            A3_out[row] = T3_L2[row][col];
                            B3_out[row] = S3_L2[col][row];
                            
                            // Pair 4 (T4*S4)
                            A4_out[row] = T4_L2[row][col];
                            B4_out[row] = S4_L2[col][row];
                            
                            // Pair 5 (T5*S5)
                            A5_out[row] = T5_L2[row][col];
                            B5_out[row] = S5_L2[col][row];
                            
                            // Pair 6 (T6*S6)
                            A6_out[row] = T6_L2[row][col];
                            B6_out[row] = S6_L2[col][row];
                            
                            // Pair 7 (T7*S7)
                            A7_out[row] = T7_L2[row][col];
                            B7_out[row] = S7_L2[col][row];
                        end
                    end
                end
            end
        end
    
    
    


endmodule

