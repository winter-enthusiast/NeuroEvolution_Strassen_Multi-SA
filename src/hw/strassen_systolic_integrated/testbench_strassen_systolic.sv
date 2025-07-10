`timescale 1ns / 1ps

module strassen_matrix_mult_tb;

    logic clk;
    logic rst;
    logic start;
    
    // Outputs
    logic signed [15:0] C [0:15][0:15];
    logic done;

    // Instantiate the DUT (Device Under Test)
    strassen_matrix_mult uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .C(C),
        .done(done)
    );

    // Clock generation
    always begin
        #5 clk = ~clk; // Generate a 10ns period clock
    end

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        start = 0;

        // Apply reset
        #20;
        rst = 0;
        start = 1;
        
        #10
        start = 0;

        // Wait for operation to complete
//        wait (done);

        // Stop the simulation after completion
//        #20;
//        $display("Matrix Multiplication Completed");
//        $finish;
    end

endmodule
