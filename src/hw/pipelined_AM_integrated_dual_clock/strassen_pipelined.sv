module  strassen_matrix_mult_top #(
    parameter MAT_A_SIZE = 16,
    parameter MAT_B_SIZE = 16,
    parameter ELEM_BITWIDTH = 8
)(
    input logic clk,
    input logic rst
);
    
    // Declarations for A matrix components
    logic [ELEM_BITWIDTH-1:0] A11_1[MAT_A_SIZE/2], A11_2[MAT_A_SIZE/2], A12_1[MAT_A_SIZE/2], A12_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH-1:0] A21_1[MAT_A_SIZE/2], A21_2[MAT_A_SIZE/2], A22_1[MAT_A_SIZE/2], A22_2[MAT_A_SIZE/2];
    
    // Declarations for B matrix components
    logic [ELEM_BITWIDTH-1:0] B11_1[MAT_B_SIZE/2], B11_2[MAT_B_SIZE/2], B12_1[MAT_B_SIZE/2], B12_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH-1:0] B21_1[MAT_B_SIZE/2], B21_2[MAT_B_SIZE/2], B22_1[MAT_B_SIZE/2], B22_2[MAT_B_SIZE/2];
    
    /*  Difference between  [7:0]A11_1[0:7] and [0:7]A11_1[7:0]
        [0:7] means ascending indices (0, 1, 2, ..., 7)
        - The first element is A11_1[0], and the last is A11_1[7].
        - This is more intuitive for software programmers (like C-style arrays).
        [7:0] means descending indices (7, 6, 5, ..., 0)
        - The first element is A11_1[7], and the last is A11_1[0].
        - If you’re matching a hardware specification or a convention where higher indices come first (e.g., some memory-mapped systems).

        The shorthand logic [7:0] A11_1[8] is equivalent to logic [7:0] A11_1[0:7], not [7:0]
    */


    // Internal signals for BRAM A
    logic ena_a;
    logic [0:0] wea_a;
    logic [1:0] addr_a;
    logic [511:0] douta_a;
    
    // Internal signals for BRAM B
    logic ena_b;
    logic [0:0] wea_b;
    logic [1:0] addr_b;
    logic [511:0] douta_b;

    // Instantiate Xilinx Block RAM IP cores
    blk_mem_gen_A bram_a_inst (
        .clka(clk),         // input wire clka
        .ena(ena_a),        // input wire ena
        .wea(wea_a),     // input wire [0 : 0] wea
        .addra(addr_a),  // input wire [1 : 0] addra
        .dina(din_a_d3),    // input wire [511 : 0] dina
        .douta(douta_a)     // output wire [511 : 0] douta
    );
    
    blk_mem_gen_B bram_b_inst (
        .clka(clk),         // input wire clka
        .ena(ena_b),        // input wire ena
        .wea(wea_b),     // input wire [0 : 0] wea
        .addra(addr_b),  // input wire [1 : 0] addra
        .dina(din_b_d3),    // input wire [511 : 0] dina
        .douta(douta_b)     // output wire [511 : 0] douta
    );

    
    // Address counter
    always_ff @(posedge clk) begin
        if (rst) begin
            addr_a <= '0;
            addr_b <= '0;
            ena_a = 1'b1;
            ena_b = 1'b1;
            wea_a <= 0;
            wea_b <= 0;
        end
        else begin
            addr_a <= addr_a + 1'b1;
            addr_b <= addr_b + 1'b1;
        end
    end

    // =============================================
    // Registered Output Declarations
    // =============================================

    always_comb begin
        //  Extracting A and B matrix components using for loops
        for (int i = 0; i < 8; i++) begin
            A11_1[i] = douta_a[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A21_1[i] = douta_a[(i+8)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A11_2[i] = douta_a[(i+2*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A21_2[i] = douta_a[(i+3*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A12_1[i] = douta_a[(i+4*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A22_1[i] = douta_a[(i+5*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A12_2[i] = douta_a[(i+6*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            A22_2[i] = douta_a[(i+ELEM_BITWIDTH-1*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            
            B11_1[i] = douta_b[i*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B12_1[i] = douta_b[(i+ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B11_2[i] = douta_b[(i+2*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B21_2[i] = douta_b[(i+3*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B21_1[i] = douta_b[(i+4*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B22_1[i] = douta_b[(i+5*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B21_2[i] = douta_b[(i+6*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
            B22_2[i] = douta_b[(i+ELEM_BITWIDTH-1*ELEM_BITWIDTH)*ELEM_BITWIDTH+:ELEM_BITWIDTH];
        end
    end

    // T outputs (registered)
    logic [ELEM_BITWIDTH:0] T1_1[MAT_A_SIZE/2], T1_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T2_1[MAT_A_SIZE/2], T2_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T3_1[MAT_A_SIZE/2], T3_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T4_1[MAT_A_SIZE/2], T4_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T5_1[MAT_A_SIZE/2], T5_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T6_1[MAT_A_SIZE/2], T6_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T7_1[MAT_A_SIZE/2], T7_2[MAT_A_SIZE/2];

    // S outputs (registered)
    logic [ELEM_BITWIDTH:0] S1_1[MAT_B_SIZE/2], S1_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S2_1[MAT_B_SIZE/2], S2_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S3_1[MAT_B_SIZE/2], S3_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S4_1[MAT_B_SIZE/2], S4_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S5_1[MAT_B_SIZE/2], S5_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S6_1[MAT_B_SIZE/2], S6_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S7_1[MAT_B_SIZE/2], S7_2[MAT_B_SIZE/2];
    

    // =============================================
    // Computation Logic (Registered on posedge clk)
    // =============================================
    always_ff @(negedge clk) begin
        // Compute T values (A matrix operations)
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
    end 

endmodule






module strassen_level_2 #(
    parameter MAT_A_SIZE = 8,
    parameter MAT_B_SIZE = 8,
    parameter ELEM_BITWIDTH = 8
)(
    input logic clk,
    input logic rst,
    input logic [ELEM_BITWIDTH-1:0] A11_1[MAT_A_SIZE/2], input logic [ELEM_BITWIDTH-1:0] A11_2[MAT_A_SIZE/2], 
    input logic [ELEM_BITWIDTH-1:0] A12_1[MAT_A_SIZE/2], input logic [ELEM_BITWIDTH-1:0] A12_2[MAT_A_SIZE/2],
    input logic [ELEM_BITWIDTH-1:0] A21_1[MAT_A_SIZE/2], input logic [ELEM_BITWIDTH-1:0] A21_2[MAT_A_SIZE/2], 
    input logic [ELEM_BITWIDTH-1:0] A22_1[MAT_A_SIZE/2], input logic [ELEM_BITWIDTH-1:0] A22_2[MAT_A_SIZE/2],

    input logic [ELEM_BITWIDTH-1:0] B11_1[MAT_B_SIZE/2], input logic [ELEM_BITWIDTH-1:0] B11_2[MAT_B_SIZE/2], 
    input logic [ELEM_BITWIDTH-1:0] B12_1[MAT_B_SIZE/2], input logic [ELEM_BITWIDTH-1:0] B12_2[MAT_B_SIZE/2],
    input logic [ELEM_BITWIDTH-1:0] B21_1[MAT_B_SIZE/2], input logic [ELEM_BITWIDTH-1:0] B21_2[MAT_B_SIZE/2], 
    input logic [ELEM_BITWIDTH-1:0] B22_1[MAT_B_SIZE/2], input logic [ELEM_BITWIDTH-1:0] B22_2[MAT_B_SIZE/2]
);

    // =============================================
    // Registered Output Declarations
    // =============================================

    // T outputs (registered)
    logic [ELEM_BITWIDTH:0] T1_1[MAT_A_SIZE/2], T1_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T2_1[MAT_A_SIZE/2], T2_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T3_1[MAT_A_SIZE/2], T3_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T4_1[MAT_A_SIZE/2], T4_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T5_1[MAT_A_SIZE/2], T5_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T6_1[MAT_A_SIZE/2], T6_2[MAT_A_SIZE/2];
    logic [ELEM_BITWIDTH:0] T7_1[MAT_A_SIZE/2], T7_2[MAT_A_SIZE/2];

    // S outputs (registered)
    logic [ELEM_BITWIDTH:0] S1_1[MAT_B_SIZE/2], S1_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S2_1[MAT_B_SIZE/2], S2_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S3_1[MAT_B_SIZE/2], S3_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S4_1[MAT_B_SIZE/2], S4_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S5_1[MAT_B_SIZE/2], S5_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S6_1[MAT_B_SIZE/2], S6_2[MAT_B_SIZE/2];
    logic [ELEM_BITWIDTH:0] S7_1[MAT_B_SIZE/2], S7_2[MAT_B_SIZE/2];

    // =============================================
    // Computation Logic (Registered on posedge clk)
    // =============================================
    always_ff @(posedge clk) begin
        // Compute T values (A matrix operations)
        for (int i = 0; i < MAT_A_SIZE/2; i++) begin
            // Row _1 computations
            T1_1[i] = A11_1[i] + A22_1[i];
            T2_1[i] = A21_1[i] + A22_1[i];
            T3_1[i] = A11_1[i];
            T4_1[i] = A22_1[i];
            T5_1[i] = A11_1[i] + A12_1[i];
            T6_1[i] = A21_1[i] - A11_1[i];
            T7_1[i] = A12_1[i] - A22_1[i];
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
            
        end
    end
endmodule