//`timescale 1ns / 1ps

//module strassen_matrix_mult_tb;

//    logic clk;
//    logic rst;
//    logic start;
    
//    // Outputs
//    logic signed [15:0] C [0:15][0:15];
//    logic done;

//    // Instantiate the DUT (Device Under Test)
//    strassen_matrix_mult uut (
//        .clk(clk),
//        .rst(rst),
//        .start(start),
//        .C(C),
//        .done(done)
//    );

//    // Clock generation
//    always begin
//        #5 clk = ~clk; // Generate a 10ns period clock
//    end

//    initial begin
//        // Initialize inputs
//        clk = 0;
//        rst = 1;
//        start = 0;

//        // Apply reset
//        #20;
//        rst = 0;
//        start = 1;
        
//        #10
//        start = 0;

//        // Wait for operation to complete
////        wait (done);

//        // Stop the simulation after completion
////        #20;
////        $display("Matrix Multiplication Completed");
////        $finish;
//    end

//endmodule



`timescale 1ns / 1ps
module top_tb;
    // Inputs
    logic clk;
    logic rst;
    logic start;
    
    // Outputs
    logic [4095:0] C;  // 16*16*16 = 4096 bits (256 elements * 16 bits each)
    logic done;
    
    // Instantiate the DUT (Device Under Test)
    top uut (
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
    
    // Variables for result display
    int i, j;
//    logic signed [15:0] C_2D [0:15][0:15];
    
    // Function to convert wide bus to 2D array for display
//    task extract_matrix();
//        for (i = 0; i < 16; i++) begin
//            for (j = 0; j < 16; j++) begin
//                C_2D[i][j] = C[(i*16+j)*16 +: 16];
//            end
//        end
//    endtask
    
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        start = 0;
        
        // Apply reset
        #2000;
        rst = 0;
        start = 1;
        
        #1000
        start = 0;
        
        // Wait for operation to complete
//        wait (done);
        
//        // Extract and display the results
//        extract_matrix();
//        $display("Matrix Multiplication Results:");
//        for (i = 0; i < 16; i++) begin
//            for (j = 0; j < 16; j++) begin
//                $write("%6d ", C_2D[i][j]);
//            end
//            $display("");
//        end
        
//        // Stop the simulation after displaying results
//        #20;
//        $display("Matrix Multiplication Completed");
//        $finish;
    end
    
//    // Optional: Add a timeout to prevent infinite simulation
//    initial begin
//        #100000; // 100 microseconds timeout
//        $display("Simulation timeout - done signal not asserted");
//        $finish;
//    end
    
//    // Optional: Generate VCD file for waveform viewing
//    initial begin
//        $dumpfile("top_strassen.vcd");
//        $dumpvars(0, top_tb);
//    end
endmodule
