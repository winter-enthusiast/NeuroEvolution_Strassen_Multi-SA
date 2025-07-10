module strassen_matrix_mult_top #(
    parameter MAT_A_SIZE = 256,
    parameter MAT_B_SIZE = 256,
    parameter ELEM_BITWIDTH = 8,
    parameter SIZE = 128,
    parameter ELEM_BITS = 16
)(
    input fast_clk,
    input rst,
    input [0:2047] A,
    input [0:2047] B,
    output reg done_C_oneclk,
    output reg [(256*256*23)-1:0] C_packed
);
    
    // A matrix components (128x128 submatrices) - assigned from BRAM in different clock cycles
    reg signed [ELEM_BITWIDTH-1:0] A11_1_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A11_2_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A12_1_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A12_2_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A21_1_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A21_2_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A22_1_sync [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A22_2_sync [0:MAT_A_SIZE/2-1];
    
    // B matrix components (128x128 submatrices) - assigned from BRAM in different clock cycles
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B11_1_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B11_2_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B12_1_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B12_2_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B21_1_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B21_2_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B22_1_sync [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B22_2_sync [0:MAT_B_SIZE/2-1];
    
    // Final synchronized A matrix components - all pairs available simultaneously  
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A11_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A11_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A12_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A12_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A21_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A21_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A22_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A22_2 [0:MAT_A_SIZE/2-1];
    
    // Final synchronized B matrix components - all pairs available simultaneously
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B11_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B11_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B12_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B12_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B21_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B21_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B22_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B22_2 [0:MAT_B_SIZE/2-1];

    // Done signals for complete matrix loading
    reg A_matrix_sync_done, B_matrix_sync_done;
    reg matrix_pairs_ready;
    
    // Final result matrix C (256x256)
    (* ram_style = "block" *)  reg  signed [22:0] C [0:255][0:255];

    // Internal signals for BRAM A - increased address width for 256x256
    reg ena_a;
    reg [0:0] wea_a;
    reg [8:0] addr_a;  // 8 bits for 256 rows
    (* ram_style = "block" *)  reg  [2047:0] din_a_d3, din_b_d3;  // 256 * 8 bits = 2048 bits per row
    
    // Internal signals for BRAM B - increased address width for 256x256
    reg ena_b;
    reg [0:0] wea_b;
    reg [8:0] addr_b;  // 8 bits for 256 rows
    reg done_C;
    
    wire l2_done_1;
    wire l2_done_2;
    wire l2_done_3;
    wire l2_done_4;
    wire l2_done_5;
    wire l2_done_6;
    wire l2_done_7;   

    // T outputs (registered) - 128 elements each for 128x128 submatrices
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T1_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T1_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T2_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T2_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T3_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T3_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T4_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T4_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T5_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T5_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T6_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T6_2 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T7_1 [0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T7_2 [0:MAT_A_SIZE/2-1];

    // S outputs ((* ram_style = "block" *)  reg istered) - 128 elements each for 128x128 submatrices
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S1_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S1_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S2_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S2_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S3_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S3_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S4_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S4_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S5_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S5_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S6_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S6_2 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S7_1 [0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S7_2 [0:MAT_B_SIZE/2-1];
    
    // Packed T values
    (* ram_style = "block" *)  reg  [1023:0] T1_1_packed, T1_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] T2_1_packed, T2_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] T3_1_packed, T3_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] T4_1_packed, T4_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] T5_1_packed, T5_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] T6_1_packed, T6_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] T7_1_packed, T7_2_packed;
    
    // Packed S values
    (* ram_style = "block" *)  reg  [1023:0] S1_1_packed, S1_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] S2_1_packed, S2_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] S3_1_packed, S3_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] S4_1_packed, S4_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] S5_1_packed, S5_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] S6_1_packed, S6_2_packed;
    (* ram_style = "block" *)  reg  [1023:0] S7_1_packed, S7_2_packed;

    reg l2_processing_done, COMPUTE_Q_LEVEL1_done;
    
    reg l2_start_7;
    reg l2_start_6;
    reg l2_start_4;
    reg l2_start_5;
    reg l2_start_3;
    reg l2_start_2;
    reg l2_start_1;
    
    reg done_bram_4_a;
    reg done_bram_4_b;

    integer i, j, k;
    
    // Level 1 Q matrices (128x128) - signed with wider bit width for multiplication results
    (* ram_style = "block" *)  reg  signed [22:0] Q1_L1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q2_L1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q3_L1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q4_L1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q5_L1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q6_L1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q7_L1 [0:127][0:127];
    
    // Level 1 C matrices (128x128) - signed
    (* ram_style = "block" *)  reg  signed [22:0] C11 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] C12 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] C21 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] C22 [0:127][0:127];
    
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_1 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_2 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_3 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_4 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_5 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_6 [0:127][0:127];
    (* ram_style = "block" *)  reg  signed [22:0] Q_out_7 [0:127][0:127];
    
    wire signed [(128*128*23)-1:0] Q_out_1_packed;
    wire signed [(128*128*23)-1:0] Q_out_2_packed;
    wire signed [(128*128*23)-1:0] Q_out_3_packed;
    wire signed [(128*128*23)-1:0] Q_out_4_packed;
    wire signed [(128*128*23)-1:0] Q_out_5_packed;
    wire signed [(128*128*23)-1:0] Q_out_6_packed;
    wire signed [(128*128*23)-1:0] Q_out_7_packed;

    reg [1:0] clk_counter;
    reg clk;
    
    // Clock divider
    always @(posedge fast_clk or negedge fast_clk or posedge rst) begin
        if (rst) begin
            clk_counter <= 2'd0;
            clk <= 1'b0;
        end else begin
            if (clk_counter == 2'd2) begin
                clk_counter <= 2'd0;
                clk <= ~clk;
            end else begin
                clk_counter <= clk_counter + 2'd1;
            end
        end
    end
    
    
    // Instantiate level 2 processors
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T1_S1 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T1_1_packed), .T1_2_packed(T1_2_packed),
        .S1_1_packed(S1_1_packed), .S1_2_packed(S1_2_packed),
        .Q_packed(Q_out_1_packed), .done(l2_done_1)
    );
    
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T2_S2 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T2_1_packed), .T1_2_packed(T2_2_packed),
        .S1_1_packed(S2_1_packed), .S1_2_packed(S2_2_packed),
        .Q_packed(Q_out_2_packed), .done(l2_done_2)
    );
    
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T3_S3 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T3_1_packed), .T1_2_packed(T3_2_packed),
        .S1_1_packed(S3_1_packed), .S1_2_packed(S3_2_packed),
        .Q_packed(Q_out_3_packed), .done(l2_done_3)
    );
    
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T4_S4 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T4_1_packed), .T1_2_packed(T4_2_packed),
        .S1_1_packed(S4_1_packed), .S1_2_packed(S4_2_packed),
        .Q_packed(Q_out_4_packed), .done(l2_done_4)
    );
    
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T5_S5 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T5_1_packed), .T1_2_packed(T5_2_packed),
        .S1_1_packed(S5_1_packed), .S1_2_packed(S5_2_packed),
        .Q_packed(Q_out_5_packed), .done(l2_done_5)
    );
    
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T6_S6 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T6_1_packed), .T1_2_packed(T6_2_packed),
        .S1_1_packed(S6_1_packed), .S1_2_packed(S6_2_packed),
        .Q_packed(Q_out_6_packed), .done(l2_done_6)
    );
    
    strassen_level2 #(.MAT_A_SIZE(128), .MAT_B_SIZE(128), .ELEM_BITWIDTH(8)) level2_processor_T7_S7 (
        .clk(clk), .fast_clk(fast_clk), .rst(rst),
        .T1_1_packed(T7_1_packed), .T1_2_packed(T7_2_packed),
        .S1_1_packed(S7_1_packed), .S1_2_packed(S7_2_packed),
        .Q_packed(Q_out_7_packed), .done(l2_done_7)
    );

    // Address counter for 256 rows
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a <= 9'd0;
            addr_b <= 9'd0;
            ena_a <= 1'b1;
            ena_b <= 1'b1;
            wea_a <= 1'b0;
            wea_b <= 1'b0;
            din_b_d3 <= 2048'd0;
            din_a_d3 <= 2048'd0;
            l2_start_1 <= 1'b0;
            l2_start_2 <= 1'b0;
            l2_start_3 <= 1'b0;
            l2_start_5 <= 1'b0;
            l2_start_4 <= 1'b0;
            l2_start_6 <= 1'b0;
            l2_start_7 <= 1'b0;
        end
        else if(addr_a < 9'd256 && addr_b < 9'd256) begin  // Count to 255 for 256 rows
            addr_a <= addr_a + 1'b1;
            addr_b <= addr_b + 1'b1;
        end
    end

    // Extract matrix components for 256x256 matrices divided into 128x128 submatrices
    always @(*) begin
        // Extracting A and B matrix components using for loops
        // For 256x256 matrices, we need to handle 128 elements per submatrix
        for (i = 0; i < 128; i = i + 1) begin
            // A matrix subcomponents (each element is 8 bits)
            if(addr_a >= 9'd1 && addr_b >= 9'd1) begin
                
                if((addr_a + 9'd3) % 4 == 0) begin
                    A11_1_sync[i] = A[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A12_1_sync[i] = A[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if((addr_a + 9'd3) % 4 == 1) begin
                    A11_2_sync[i] = A[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A12_2_sync[i] = A[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if((addr_a + 9'd3) % 4 == 2) begin    
                    A21_1_sync[i] = A[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A22_1_sync[i] = A[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if((addr_a + 9'd3) % 4 == 3) begin
                    A21_2_sync[i] = A[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    A22_2_sync[i] = A[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                
                // B matrix subcomponents (each element is 8 bits)
                if ((addr_b + 9'd3) % 4 == 0) begin
                    B11_1_sync[i] = B[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B21_1_sync[i] = B[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if ((addr_b + 9'd3) % 4 == 1) begin
                    B11_2_sync[i] = B[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B21_2_sync[i] = B[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if ((addr_b + 9'd3) % 4 == 2) begin    
                    B12_1_sync[i] = B[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B22_1_sync[i] = B[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
                else if ((addr_b + 9'd3) % 4 == 3) begin
                    B12_2_sync[i] = B[(i)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                    B22_2_sync[i] = B[(i+128)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
                end
            end
        end
    end
    
    // Merged logic for tracking ready flags, generating done signals, and assignments
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all final arrays
            for (i = 0; i < 128; i = i + 1) begin
                A11_1[i] <= 8'd0;
                A11_2[i] <= 8'd0;
                A12_1[i] <= 8'd0;
                A12_2[i] <= 8'd0;
                A21_1[i] <= 8'd0;
                A21_2[i] <= 8'd0;
                A22_1[i] <= 8'd0;
                A22_2[i] <= 8'd0;
                
                B11_1[i] <= 8'd0;
                B11_2[i] <= 8'd0;
                B12_1[i] <= 8'd0;
                B12_2[i] <= 8'd0;
                B21_1[i] <= 8'd0;
                B21_2[i] <= 8'd0;
                B22_1[i] <= 8'd0;
                B22_2[i] <= 8'd0;
            end
        end
        else begin
            // Special case: Immediate assignment when addr is between 2 to 5 inclusive
            if (addr_a >= 9'd1 && addr_a < 9'd5 && addr_b >= 9'd1 && addr_b < 9'd5) begin
                // Assign all pairs immediately without waiting for ready signals
                for (i = 0; i < 128; i = i + 1) begin
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
            // Normal operation: Wait for A21_A22_pair2_ready for addresses > 5
            else if (((addr_a) % 4 == 0) && addr_a >= 9'd5 && addr_b >= 9'd5) begin
                // Assign all pairs simultaneously when all are ready
                for (i = 0; i < 128; i = i + 1) begin
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic would go here if needed
        end
        else begin
            for (i = 0; i < MAT_A_SIZE/2; i = i + 1) begin
                // Row _1 computations
                T1_1[i] <= A11_1[i] + A22_1[i];
                T2_1[i] <= A21_1[i] + A22_1[i];
                T3_1[i] <= A11_1[i];
                T4_1[i] <= A22_1[i];
                T5_1[i] <= A11_1[i] + A12_1[i];
                T6_1[i] <= A21_1[i] - A11_1[i];
                T7_1[i] <= A12_1[i] - A22_1[i];
                
                // Row _2 computations
                T1_2[i] <= A11_2[i] + A22_2[i];
                T2_2[i] <= A21_2[i] + A22_2[i];
                T3_2[i] <= A11_2[i];
                T4_2[i] <= A22_2[i];
                T5_2[i] <= A11_2[i] + A12_2[i];
                T6_2[i] <= A21_2[i] - A11_2[i];
                T7_2[i] <= A12_2[i] - A22_2[i];
            end
    
            // Compute S values (B matrix operations)
            for (i = 0; i < MAT_B_SIZE/2; i = i + 1) begin
                // Row _1 computations
                S1_1[i] <= B11_1[i] + B22_1[i];
                S2_1[i] <= B11_1[i];
                S3_1[i] <= B12_1[i] - B22_1[i];
                S4_1[i] <= B21_1[i] - B11_1[i];
                S5_1[i] <= B22_1[i];
                S6_1[i] <= B11_1[i] + B12_1[i];
                S7_1[i] <= B21_1[i] + B22_1[i];

                // Row _2 computations
                S1_2[i] <= B11_2[i] + B22_2[i];
                S2_2[i] <= B11_2[i];
                S3_2[i] <= B12_2[i] - B22_2[i];
                S4_2[i] <= B21_2[i] - B11_2[i];
                S5_2[i] <= B22_2[i];
                S6_2[i] <= B11_2[i] + B12_2[i];
                S7_2[i] <= B21_2[i] + B22_2[i];
            end
        end
    end

    
    always @(*) begin
        for (i = 0; i < MAT_A_SIZE/2; i = i + 1) begin
            T1_1_packed[i*8 +: 8] = T1_1[i];
            T1_2_packed[i*8 +: 8] = T1_2[i];
            T2_1_packed[i*8 +: 8] = T2_1[i];
            T2_2_packed[i*8 +: 8] = T2_2[i];
            T3_1_packed[i*8 +: 8] = T3_1[i];
            T3_2_packed[i*8 +: 8] = T3_2[i];
            T4_1_packed[i*8 +: 8] = T4_1[i];
            T4_2_packed[i*8 +: 8] = T4_2[i];
            T5_1_packed[i*8 +: 8] = T5_1[i];
            T5_2_packed[i*8 +: 8] = T5_2[i];
            T6_1_packed[i*8 +: 8] = T6_1[i];
            T6_2_packed[i*8 +: 8] = T6_2[i];
            T7_1_packed[i*8 +: 8] = T7_1[i];
            T7_2_packed[i*8 +: 8] = T7_2[i];
        end
    
        for (i = 0; i < MAT_B_SIZE/2; i = i + 1) begin
            S1_1_packed[i*8 +: 8] = S1_1[i];
            S1_2_packed[i*8 +: 8] = S1_2[i];
            S2_1_packed[i*8 +: 8] = S2_1[i];
            S2_2_packed[i*8 +: 8] = S2_2[i];
            S3_1_packed[i*8 +: 8] = S3_1[i];
            S3_2_packed[i*8 +: 8] = S3_2[i];
            S4_1_packed[i*8 +: 8] = S4_1[i];
            S4_2_packed[i*8 +: 8] = S4_2[i];
            S5_1_packed[i*8 +: 8] = S5_1[i];
            S5_2_packed[i*8 +: 8] = S5_2[i];
            S6_1_packed[i*8 +: 8] = S6_1[i];
            S6_2_packed[i*8 +: 8] = S6_2[i];
            S7_1_packed[i*8 +: 8] = S7_1[i];
            S7_2_packed[i*8 +: 8] = S7_2[i];
        end
    end
    
    
    
    always @(*) begin
        // Unpack Q_out_1_packed into Q_out_1
        for (i = 0; i < SIZE; i = i + 1) begin
            for (j = 0; j < SIZE; j = j + 1) begin
                Q_out_1[i][j] = Q_out_1_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
                Q_out_2[i][j] = Q_out_2_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
                Q_out_3[i][j] = Q_out_3_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
                Q_out_4[i][j] = Q_out_4_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
                Q_out_5[i][j] = Q_out_5_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
                Q_out_6[i][j] = Q_out_6_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
                Q_out_7[i][j] = Q_out_7_packed[ ((i*SIZE + j + 1)*23) - 1 -: 23 ];
            end
        end
    end

 
    
    
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            l2_processing_done <= 0;
        end
        else if ( l2_done_1 && l2_done_2 && l2_done_3  && l2_done_4 && l2_done_5 && l2_done_6 && l2_done_7) begin
            // Store result
            for (i = 0; i < 128; i = i + 1) begin
                for (j = 0; j < 128; j = j + 1) begin
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
    
    
        
    always @(posedge clk or posedge rst) begin
        if(rst) begin 
            COMPUTE_Q_LEVEL1_done <= 0;            
            done_C <= 0;
        end
        else if ( l2_processing_done ) begin
            for (i = 0; i < 128; i = i + 1) begin
                for (j = 0; j < 128; j = j + 1) begin
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
                        done_C <= 1;                        
                    end
                    
                end
            end
        end
    end
        
        
        
    always @(*) begin
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    // For 23-bit values
                    C_packed[((i * 256 + j) * 23) + 22 -: 23] = C[i][j];
                    
                end
            end
    end
    
    reg [7:0] done_counter;
    reg       done_seen;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done_counter    <= 8'd0;
            done_seen       <= 1'b0;
            done_C_oneclk   <= 1'b0;
        end else begin
            if (!done_seen && done_C) begin
                done_seen     <= 1'b1;      // mark that done_C was seen
                done_counter  <= 8'd1;
            end else if (done_seen && done_counter < 8'd200) begin
                done_counter  <= done_counter + 1;
            end else if (done_seen && done_counter == 8'd200) begin
                done_C_oneclk <= 1'b1;      // assert after 200 cycles
            end
        end
    end





    

endmodule





module strassen_level2 #(
    parameter MAT_A_SIZE = 128,
    parameter MAT_B_SIZE = 128,
    parameter ELEM_BITWIDTH = 8
)(
    input  wire clk,
    input  wire fast_clk,
    input  wire rst,

    // Flattened packed inputs for T
    input  wire signed [(ELEM_BITWIDTH*MAT_A_SIZE)-1:0] T1_1_packed,
    input  wire signed [(ELEM_BITWIDTH*MAT_A_SIZE)-1:0] T1_2_packed,

    // Flattened packed inputs for S
    input  wire signed [(ELEM_BITWIDTH*MAT_B_SIZE)-1:0] S1_1_packed,
    input  wire signed [(ELEM_BITWIDTH*MAT_B_SIZE)-1:0] S1_2_packed,

    // Flattened packed output
    output reg signed [(23*MAT_A_SIZE*MAT_B_SIZE)-1:0] Q_packed,

    output reg done
);

    // Unpacked arrays - using generate blocks for array declarations
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T1_1[0:MAT_A_SIZE-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T1_2[0:MAT_A_SIZE-1]; 
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S1_1[0:MAT_B_SIZE-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S1_2[0:MAT_B_SIZE-1];
    (* ram_style = "block" *)  reg  signed [22:0] Q[0:(MAT_A_SIZE-1)][0:(MAT_B_SIZE-1)];

    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A11[0:MAT_A_SIZE/2-1];   
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A12[0:MAT_A_SIZE/2-1];  
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A21[0:MAT_A_SIZE/2-1];   
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A22[0:MAT_A_SIZE/2-1];  

    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B11[0:MAT_B_SIZE/2-1];   
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B12[0:MAT_B_SIZE/2-1];  
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B21[0:MAT_B_SIZE/2-1];   
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B22[0:MAT_B_SIZE/2-1];  

    // =============================================
    // Registered Output Declarations
    // =============================================

    // T outputs (registered)
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] T1[0:MAT_A_SIZE/2-1], T2[0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] T3[0:MAT_A_SIZE/2-1], T4[0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] T5[0:MAT_A_SIZE/2-1], T6[0:MAT_A_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] T7[0:MAT_A_SIZE/2-1];
    
    // S outputs (registered)
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] S1[0:MAT_B_SIZE/2-1], S2[0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] S3[0:MAT_B_SIZE/2-1], S4[0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] S5[0:MAT_B_SIZE/2-1], S6[0:MAT_B_SIZE/2-1];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH:0] S7[0:MAT_B_SIZE/2-1];

    // Matrices to store rows over time (64x64)
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T1_L2 [0:63][0:63], T2_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T3_L2 [0:63][0:63], T4_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T5_L2 [0:63][0:63], T6_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] T7_L2 [0:63][0:63];
    
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S1_L2 [0:63][0:63], S2_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S3_L2 [0:63][0:63], S4_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S5_L2 [0:63][0:63], S6_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] S7_L2 [0:63][0:63];

    // Row index tracker
    reg [8:0] index;
    wire done1, done2, done3, done4, done5, done6, done7;
    reg [7:0] cycle_counter;
    reg valid_out;
    reg COMPUTE_Q_RESULTS_done;
    reg done_TS;

    integer i, j, k;
    integer diag, row, col, idx;

    // Input to 7 parallel systolic arrays
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A1_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B1_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A2_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B2_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A3_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B3_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A4_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B4_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A5_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B5_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A6_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B6_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] A7_out [0:63];
    (* ram_style = "block" *)  reg  signed [ELEM_BITWIDTH-1:0] B7_out [0:63];
    
    (* ram_style = "block" *)  reg  [512-1:0] A1_out_packed, B1_out_packed;
    (* ram_style = "block" *)  reg  [512-1:0] A2_out_packed, B2_out_packed;
    (* ram_style = "block" *)  reg  [512-1:0] A3_out_packed, B3_out_packed;
    (* ram_style = "block" *)  reg  [512-1:0] A4_out_packed, B4_out_packed;
    (* ram_style = "block" *)  reg  [512-1:0] A5_out_packed, B5_out_packed;
    (* ram_style = "block" *)  reg  [512-1:0] A6_out_packed, B6_out_packed;
    (* ram_style = "block" *)  reg  [512-1:0] A7_out_packed, B7_out_packed;   

    // Level 2 Q matrices (64x64) - results of base case multiplications
    (* ram_style = "block" *)  reg  signed [22:0] Q1_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] Q2_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] Q3_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] Q4_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] Q5_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] Q6_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] Q7_L2 [0:63][0:63];
    
    // Packed versions of Q matrices (each 64x64 of 23-bit signed)
    wire signed [(23*64*64)-1:0] Q1_L2_packed;
    wire signed [(23*64*64)-1:0] Q2_L2_packed;
    wire signed [(23*64*64)-1:0] Q3_L2_packed;
    wire signed [(23*64*64)-1:0] Q4_L2_packed;
    wire signed [(23*64*64)-1:0] Q5_L2_packed;
    wire signed [(23*64*64)-1:0] Q6_L2_packed;
    wire signed [(23*64*64)-1:0] Q7_L2_packed;

    // Level 2 C matrices (64x64)
    (* ram_style = "block" *)  reg  signed [22:0] C11_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] C12_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] C21_L2 [0:63][0:63];
    (* ram_style = "block" *)  reg  signed [22:0] C22_L2 [0:63][0:63];
    
    reg COMPUTE_TS_done;

    // Instantiate seven systolic arrays
    // Systolic Array 1 - P1 = T1*S1
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic1 (
        .A_packed(A1_out_packed),
        .B_packed(B1_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done1),
        .C_packed(Q1_L2_packed)
    );
    
    // Systolic Array 2 - P2 = T2*S2
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic2 (
        .A_packed(A2_out_packed),
        .B_packed(B2_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done2),
        .C_packed(Q2_L2_packed)
    );
    
    // Systolic Array 3 - P3 = T3*S3
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic3 (
        .A_packed(A3_out_packed),
        .B_packed(B3_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done3),
        .C_packed(Q3_L2_packed)
    );
    
    // Systolic Array 4 - P4 = T4*S4
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic4 (
        .A_packed(A4_out_packed),
        .B_packed(B4_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done4),
        .C_packed(Q4_L2_packed)
    );
    
    // Systolic Array 5 - P5 = T5*S5
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic5 (
        .A_packed(A5_out_packed),
        .B_packed(B5_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done5),
        .C_packed(Q5_L2_packed)
    );
    
    // Systolic Array 6 - P6 = T6*S6
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic6 (
        .A_packed(A6_out_packed),
        .B_packed(B6_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done6),
        .C_packed(Q6_L2_packed)
    );
    
    // Systolic Array 7 - P7 = T7*S7
    SystolicArray #(
        .SIZE(64),
        .DATA_WIDTH(8)
    ) systolic7 (
        .A_packed(A7_out_packed),
        .B_packed(B7_out_packed),
        .clk(clk),
        .fast_clk(fast_clk),
        .rst(rst),
        .done(done7),
        .C_packed(Q7_L2_packed)
    );

    // Unpack input arrays - combinational logic
    always @(*) begin
        for (i = 0; i < MAT_A_SIZE; i = i + 1) begin
            T1_1[i] =  T1_1_packed[i*ELEM_BITWIDTH +: ELEM_BITWIDTH];
            T1_2[i] =  T1_2_packed[i*ELEM_BITWIDTH +: ELEM_BITWIDTH];
        end
        for (i = 0; i < MAT_B_SIZE; i = i + 1) begin
            S1_1[i] =  S1_1_packed[i*ELEM_BITWIDTH +: ELEM_BITWIDTH];
            S1_2[i] =  S1_2_packed[i*ELEM_BITWIDTH +: ELEM_BITWIDTH];
        end
    end 

    // Matrix partitioning
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all arrays to 0
            for (i = 0; i < MAT_A_SIZE/2; i = i + 1) begin
                A11[i] <= 0;
                A12[i] <= 0;
                A21[i] <= 0;
                A22[i] <= 0;
                B11[i] <= 0;
                B12[i] <= 0;
                B21[i] <= 0;
                B22[i] <= 0;
            end
        end else begin    
            for (i = 0; i < MAT_A_SIZE/2; i = i + 1) begin
                A11[i] <= T1_1[i];
                A12[i] <= T1_1[(i+64)];
                A21[i] <= T1_2[(i)];
                A22[i] <= T1_2[(i+64)];

                B11[i] <= S1_1[i];
                B21[i] <= S1_1[(i+64)];
                B12[i] <= S1_2[(i)];
                B22[i] <= S1_2[(i+64)]; 
            end 
        end
    end

    // Compute T and S values
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done_TS <= 1'b0;
            for (i = 0; i < MAT_A_SIZE/2; i = i + 1) begin
                T1[i] <= 0; T2[i] <= 0; T3[i] <= 0; T4[i] <= 0;
                T5[i] <= 0; T6[i] <= 0; T7[i] <= 0;
                S1[i] <= 0; S2[i] <= 0; S3[i] <= 0; S4[i] <= 0;
                S5[i] <= 0; S6[i] <= 0; S7[i] <= 0;
            end
        end else begin
            // Compute T values (A matrix operations)
            for (i = 0; i < MAT_A_SIZE/2; i = i + 1) begin
                T1[i] <= A11[i] + A22[i];
                T2[i] <= A21[i] + A22[i];
                T3[i] <= A11[i];
                T4[i] <= A22[i];
                T5[i] <= A11[i] + A12[i];
                T6[i] <= A21[i] - A11[i];
                T7[i] <= A12[i] - A22[i];
            end
        
            // Compute S values (B matrix operations)
            for (i = 0; i < MAT_B_SIZE/2; i = i + 1) begin
                S1[i] <= B11[i] + B22[i];
                S2[i] <= B11[i];
                S3[i] <= B12[i] - B22[i];
                S4[i] <= B21[i] - B11[i];
                S5[i] <= B22[i];
                S6[i] <= B11[i] + B12[i];
                S7[i] <= B21[i] + B22[i];
            end
            
            done_TS <= 1'b1;
        end
    end

    // Counter logic triggered by done_TS
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            index <= 0;
        end else if (done_TS) begin
            index <= index + 1;
        end
    end

    // Store T and S matrices
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            COMPUTE_TS_done <= 0; 
            i <= 0;
            j <= 0;
            k <= 0;
        end else begin 
            if (((index < 261 && index > 7) && ((index) % 4 == 0)) && (!COMPUTE_TS_done)) begin
                for (j = 0; j < (256/4); j = j + 1) begin
                    T1_L2[((index/4)-2)][j] <= T1[j];
                    T2_L2[((index/4)-2)][j] <= T2[j];
                    T3_L2[((index/4)-2)][j] <= T3[j];
                    T4_L2[((index/4)-2)][j] <= T4[j];
                    T5_L2[((index/4)-2)][j] <= T5[j];
                    T6_L2[((index/4)-2)][j] <= T6[j];
                    T7_L2[((index/4)-2)][j] <= T7[j];

                    S1_L2[j][((index/4)-2)] <= S1[j];
                    S2_L2[j][((index/4)-2)] <= S2[j];
                    S3_L2[j][((index/4)-2)] <= S3[j];
                    S4_L2[j][((index/4)-2)] <= S4[j];
                    S5_L2[j][((index/4)-2)] <= S5[j];
                    S6_L2[j][((index/4)-2)] <= S6[j];
                    S7_L2[j][((index/4)-2)] <= S7[j];
                    
                    if( index == 260) begin
                        COMPUTE_TS_done <= 1;
                    end
                end
            end
        end
    end
        
    // Modified cycle counter logic for 64x64 matrix multiplication
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 0;             
            cycle_counter <= 0;
        end else if ((cycle_counter <= 2*64) && COMPUTE_TS_done) begin
            cycle_counter <= cycle_counter + 1;
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
    end

    // Unpack Q matrices from systolic arrays
    always @(*) begin
        for (i = 0; i < 64; i = i + 1) begin
            for (j = 0; j < 64; j = j + 1) begin
                Q1_L2[i][j] = Q1_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
                Q2_L2[i][j] = Q2_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
                Q3_L2[i][j] = Q3_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
                Q4_L2[i][j] = Q4_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
                Q5_L2[i][j] = Q5_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
                Q6_L2[i][j] = Q6_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
                Q7_L2[i][j] = Q7_L2_packed[(((i * 64 + j) + 1) * 23) - 1 -: 23];
            end
        end
    end


    // Compute final results
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
            COMPUTE_Q_RESULTS_done <= 0;
            for (i = 0; i < 64; i = i + 1) begin
                for (j = 0; j < 64; j = j + 1) begin
                    C11_L2[i][j] <= 0;
                    C12_L2[i][j] <= 0;
                    C21_L2[i][j] <= 0;
                    C22_L2[i][j] <= 0;
                end
            end
            for (i = 0; i < MAT_A_SIZE; i = i + 1) begin
                for (j = 0; j < MAT_B_SIZE; j = j + 1) begin
                    Q[i][j] <= 0;
                end
            end
        end    
        else if((cycle_counter > 2*64 ) && done7 && done1 && done2 && done3 && done4 && done5 && done6) begin
            for (i = 0; i < 64; i = i + 1) begin
                for (j = 0; j < 64; j = j + 1) begin
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
      
    // Pack output
    always @(*) begin
        for (i = 0; i < MAT_A_SIZE; i = i + 1) begin
            for (j = 0; j < MAT_B_SIZE; j = j + 1) begin
                Q_packed[(((i * MAT_B_SIZE + j) + 1)*(23)) - 1 -: (23)] = Q[i][j];
            end
        end
    end

    // Combinational logic for 64x64 matrix diagonal feeding
    always @(*) begin
        // Default: all inputs are 0
        for (i = 0; i < 64; i = i + 1) begin
            A1_out[i] = 0; B1_out[i] = 0;
            A2_out[i] = 0; B2_out[i] = 0;
            A3_out[i] = 0; B3_out[i] = 0;
            A4_out[i] = 0; B4_out[i] = 0;
            A5_out[i] = 0; B5_out[i] = 0;
            A6_out[i] = 0; B6_out[i] = 0;
            A7_out[i] = 0; B7_out[i] = 0;
        end
        
        if (valid_out && COMPUTE_TS_done) begin
            for (diag = 0; diag < 64; diag = diag + 1) begin
                if (cycle_counter >= (diag + 1) && cycle_counter <= (diag + 64)) begin
                    row = cycle_counter - diag - 1;
                    col = diag;
                    
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
    
    // Pack arrays for systolic array inputs
    always @(*) begin
        // Default zero
        A1_out_packed = 0; B1_out_packed = 0;
        A2_out_packed = 0; B2_out_packed = 0;
        A3_out_packed = 0; B3_out_packed = 0;
        A4_out_packed = 0; B4_out_packed = 0;
        A5_out_packed = 0; B5_out_packed = 0;
        A6_out_packed = 0; B6_out_packed = 0;
        A7_out_packed = 0; B7_out_packed = 0;
    
        for (i = 0; i < 64; i = i + 1) begin
            A1_out_packed[i*8 +: 8] = A1_out[i];
            B1_out_packed[i*8 +: 8] = B1_out[i];

            A2_out_packed[i*8 +: 8] = A2_out[i];
            B2_out_packed[i*8 +: 8] = B2_out[i];

            A3_out_packed[i*8 +: 8] = A3_out[i];
            B3_out_packed[i*8 +: 8] = B3_out[i];

            A4_out_packed[i*8 +: 8] = A4_out[i];
            B4_out_packed[i*8 +: 8] = B4_out[i];

            A5_out_packed[i*8 +: 8] = A5_out[i];
            B5_out_packed[i*8 +: 8] = B5_out[i];

            A6_out_packed[i*8 +: 8] = A6_out[i];
            B6_out_packed[i*8 +: 8] = B6_out[i];

            A7_out_packed[i*8 +: 8] = A7_out[i];
            B7_out_packed[i*8 +: 8] = B7_out[i];
        end
    end

endmodule
