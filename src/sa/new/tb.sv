`timescale 1ns / 1ps
module SA_tb;
    parameter SIZE = 4;
    parameter DATA_WIDTH = 10;
    
    // Inputs
    logic clk;
    logic rst;
    logic signed [DATA_WIDTH-1:0] A [SIZE-1:0];
    logic signed [DATA_WIDTH-1:0] B [SIZE-1:0];
    
    // Outputs
    logic done;
    logic signed [2*DATA_WIDTH-1:0] C [SIZE-1:0][SIZE-1:0];
    
    // Instantiate the SA module
    SystolicArray #(.SIZE(SIZE), .DATA_WIDTH(DATA_WIDTH)) uut (
        .A(A),
        .B(B),
        .clk(clk),
        .rst(rst),
        .done(done),
        .C(C)
    );
    
    // Clock generation (50% duty cycle, period = 10ns)
    always #5 clk = ~clk;
    
    // Test procedure
    initial begin
        clk = 0;
        // Initialize clock and reset
        rst = 0;
        
        // Initialize arrays to zeros
        for (int i = 0; i < SIZE; i++) begin
            A[i] = 0;
            B[i] = 0;
        end
        
        #100;
        #10 rst = 1; // Release reset after 10ns
        
        // Input matrices (example 4x4 matrices):
        // Matrix A:         Matrix B:
        // [ 1  2  3  4 ]    [ 5  6  7  8 ]
        // [ 9 10 11 12 ]    [ 9 10 11 12 ]
        // [13 14 15 16 ]    [13 14 15 16 ]
        // [17 18 19 20 ]    [17 18 19 20 ]
        
        // First cycle
        A[0] = 10'd1; A[1] = 10'd0; A[2] = 10'd0; A[3] = 10'd0;
        B[0] = 10'd5; B[1] = 10'd0; B[2] = 10'd0; B[3] = 10'd0;
        #10;
        
        // Second cycle
        A[0] = 10'd2; A[1] = 10'd9; A[2] = 10'd0; A[3] = 10'd0;
        B[0] = 10'd6; B[1] = 10'd9; B[2] = 10'd0; B[3] = 10'd0;
        #10;
        
        // Third cycle
        A[0] = 10'd3; A[1] = 10'd10; A[2] = 10'd13; A[3] = 10'd0;
        B[0] = 10'd7; B[1] = 10'd10; B[2] = 10'd13; B[3] = 10'd0;
        #10;
        
        // Fourth cycle
        A[0] = 10'd4; A[1] = 10'd11; A[2] = 10'd14; A[3] = 10'd17;
        B[0] = 10'd8; B[1] = 10'd11; B[2] = 10'd14; B[3] = 10'd17;
        #10;
        
        // Fifth cycle
        A[0] = 10'd0; A[1] = 10'd12; A[2] = 10'd15; A[3] = 10'd18;
        B[0] = 10'd0; B[1] = 10'd12; B[2] = 10'd15; B[3] = 10'd18;
        #10;
        
        // Sixth cycle
        A[0] = 10'd0; A[1] = 10'd0; A[2] = 10'd16; A[3] = 10'd19;
        B[0] = 10'd0; B[1] = 10'd0; B[2] = 10'd16; B[3] = 10'd19;
        #10;
        
        // Seventh cycle
        A[0] = 10'd0; A[1] = 10'd0; A[2] = 10'd0; A[3] = 10'd20;
        B[0] = 10'd0; B[1] = 10'd0; B[2] = 10'd0; B[3] = 10'd20;
        #10;
        
        // Remaining cycles - all zeros (need 2*SIZE+1 cycles in total for computation)
        for (int i = 0; i < (2*SIZE+1 - 7); i++) begin
            A[0] = 10'd0; A[1] = 10'd0; A[2] = 10'd0; A[3] = 10'd0;
            B[0] = 10'd0; B[1] = 10'd0; B[2] = 10'd0; B[3] = 10'd0;
            #10;
        end
        
        // Wait for computation to complete
        wait(done);
        
        // Print the output matrix
        $display("Matrix C Result:");
        for (int i = 0; i < SIZE; i++) begin
            $write("[ ");
            for (int j = 0; j < SIZE; j++) begin
                $write("%d ", C[i][j]);
            end
            $display("]");
        end
        
        // Print in tabular format for easier verification
        $display("\nMatrix C in table format:");
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                $display("C[%0d][%0d] = %0d", i, j, C[i][j]);
            end
        end
        

        // End simulation
        #10;
        $stop;
    end
endmodule