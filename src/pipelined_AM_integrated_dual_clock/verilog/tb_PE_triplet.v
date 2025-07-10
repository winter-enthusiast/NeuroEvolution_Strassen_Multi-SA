`timescale 1ns/1ps

module tb_PE_systolic_array();
    
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 12;      // 12ns
    parameter FAST_CLK_PERIOD = 4;  // 4ns (CLK_PERIOD/3)
    
    // Testbench signals
    reg signed [DATA_WIDTH-1:0] a0, b0, a1, b1, a2, b2;
    reg fast_clk, clk, rst;
    reg [1:0] counter_for_exact_mult_usage;
    
    // PE outputs
    wire signed [DATA_WIDTH-1:0] c0, d0, c1, d1, c2, d2;
    wire signed [2*DATA_WIDTH-1:0] C_out0, C_out1, C_out2;
    
    // Expected results for comparison
    reg signed [2*DATA_WIDTH-1:0] expected_result0, expected_result1, expected_result2;
    
    // Test case counter
    integer test_case = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Instantiate the PEs
    PE_3_00_5 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) pe0 (
        .a(a2), .b(b2),
        .fast_clk(fast_clk), .clk(clk), .rst(rst),
        .counter_for_exact_mult_usage(counter_for_exact_mult_usage),
        .c(c2), .d(d2), .C_out(C_out2)
    );

    PE_1_00_5 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) pe1 (
        .a(a0), .b(b0),
        .fast_clk(fast_clk), .clk(clk), .rst(rst),
        .counter_for_exact_mult_usage(counter_for_exact_mult_usage),
        .c(c0), .d(d0), .C_out(C_out0)
    );
    
    PE_2_00_5 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) pe2 (
        .a(a1), .b(b1),
        .fast_clk(fast_clk), .clk(clk), .rst(rst),
        .counter_for_exact_mult_usage(counter_for_exact_mult_usage),
        .c(c1), .d(d1), .C_out(C_out1)
    );
    
    
    // Clock generation - synchronized clocks
    initial begin
        clk = 1;
        fast_clk = 1;
        fork
            // Main clock
            forever #(CLK_PERIOD/2) clk = ~clk;
            // Fast clock - 3x faster, synchronized with main clock
            forever #(FAST_CLK_PERIOD/2) fast_clk = ~fast_clk;
        join
    end
    
    // Counter generation - cycles every 3 fast_clk cycles
    always @(posedge fast_clk or posedge rst) begin
        if (rst) begin
            counter_for_exact_mult_usage <= 2'b00;
        end else begin
            if (counter_for_exact_mult_usage == 2'b11) begin
                counter_for_exact_mult_usage <= 2'b01;
            end else begin
                counter_for_exact_mult_usage <= counter_for_exact_mult_usage + 1;
            end
        end
    end
    
    // Test procedure
    initial begin
        $display("Starting Multi-PE Systolic Array Testbench");
        $display("Clock period: %0d ns, Fast clock period: %0d ns", CLK_PERIOD, FAST_CLK_PERIOD);
        $display("================================================================================");
        
        // Initialize
        initialize();
        
        // Test cases with larger values to ensure aH and bH are non-zero
        run_test_case(8'd85, 8'd73, 8'd91, 8'd67, 8'd105, 8'd83, "Large positive values");
        run_test_case(8'd127, 8'd100, 8'd110, 8'd95, 8'd120, 8'd88, "Near-max positive values");
        run_test_case(-8'd85, 8'd73, 8'd91, -8'd67, -8'd105, 8'd83, "Mixed signs test 1");
        run_test_case(8'd85, -8'd73, -8'd91, 8'd67, 8'd105, -8'd83, "Mixed signs test 2");
        run_test_case(-8'd85, -8'd73, -8'd91, -8'd67, -8'd105, -8'd83, "All negative values");
        run_test_case(8'd200, 8'd150, 8'd180, 8'd160, 8'd220, 8'd140, "Large values test");
        
        // Print summary
        $display("================================================================================");
        $display("Test Summary:");
        $display("PASSED: %0d", pass_count);
        $display("FAILED: %0d", fail_count);
        $display("TOTAL:  %0d", pass_count + fail_count);
        
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end

       $finish;
    end
    
    // Initialize task
    task initialize;
        begin
            rst = 1;
            a0 = 0; b0 = 0;
            a1 = 0; b1 = 0;
            a2 = 0; b2 = 0;
            
            // Hold reset for several clock cycles to ensure proper initialization
            repeat(2) @(posedge clk);
            
            // Release reset at the positive edge of clk (which should align with fast_clk)
            rst = 0;
            
            $display("Initialization complete");
            $display("Counter should start from 0 at next fast_clk edge");
        end
    endtask
    

    // Run test case task
    task run_test_case;
        input signed [DATA_WIDTH-1:0] test_a0, test_b0;
        input signed [DATA_WIDTH-1:0] test_a1, test_b1; 
        input signed [DATA_WIDTH-1:0] test_a2, test_b2;
        input [80*8:1] description;
        begin
            test_case = test_case + 1;
            
            $display("\nTest Case %0d: %s", test_case, description);
            $display("PE0 Inputs: a=%0d (0x%02h), b=%0d (0x%02h)", test_a0, test_a0, test_b0, test_b0);
            $display("PE1 Inputs: a=%0d (0x%02h), b=%0d (0x%02h)", test_a1, test_a1, test_b1, test_b1);
            $display("PE2 Inputs: a=%0d (0x%02h), b=%0d (0x%02h)", test_a2, test_a2, test_b2, test_b2);
            
            // Calculate expected results
            expected_result0 = test_a0 * test_b0;
            expected_result1 = test_a1 * test_b1;
            expected_result2 = test_a2 * test_b2;
            
            $display("Expected Results: PE0=%0d, PE1=%0d, PE2=%0d", 
                    expected_result0, expected_result1, expected_result2);
            
            // Apply inputs at clk edge (which should be when counter=0 )
            a0 = test_a0; b0 = test_b0;
            a1 = test_a1; b1 = test_b1;
            a2 = test_a2; b2 = test_b2;
            
            $display("Inputs applied at time %0t", $time);
            $display("Counter value: %0d", counter_for_exact_mult_usage);
            
            repeat(3) @(posedge fast_clk);
            
            // Check results
            $display("\nResults at time %0t:", $time);
            $display("PE0: Actual=%0d (0x%04h), Expected=%0d", C_out0, C_out0, expected_result0);
            $display("PE1: Actual=%0d (0x%04h), Expected=%0d", C_out1, C_out1, expected_result1);
            $display("PE2: Actual=%0d (0x%04h), Expected=%0d", C_out2, C_out2, expected_result2);
            
            // Check PE0
            if (C_out0 === expected_result0) begin
                $display("✓ PE0 PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ PE0 FAIL - Expected: %0d, Got: %0d, Error: %0d", 
                         expected_result0, C_out0, C_out0 - expected_result0);
                fail_count = fail_count + 1;
            end
            
            // Check PE1
            if (C_out1 === expected_result1) begin
                $display("✓ PE1 PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ PE1 FAIL - Expected: %0d, Got: %0d, Error: %0d", 
                        expected_result1, C_out1, C_out1 - expected_result1);
                fail_count = fail_count + 1;
            end
            
            // Check PE2
            if (C_out2 === expected_result2) begin
                $display("✓ PE2 PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ PE2 FAIL - Expected: %0d, Got: %0d, Error: %0d", 
                        expected_result2, C_out2, C_out2 - expected_result2);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Monitor critical signals
    initial begin
        $monitor("Time=%0t | Counter=%0d | PE0: a=%0d b=%0d C_out=%0d cyc=%0d | PE1: a=%0d b=%0d C_out=%0d cyc=%0d | PE2: a=%0d b=%0d C_out=%0d cyc=%0d", 
                    $time, counter_for_exact_mult_usage,
                    a0, b0, C_out0, counter_for_exact_mult_usage,
                    a1, b1, C_out1, counter_for_exact_mult_usage,
                    a2, b2, C_out2, counter_for_exact_mult_usage);
    end
    
    // Debug exact multiplier usage
    always @(posedge fast_clk) begin
        if (!rst) begin
            if (counter_for_exact_mult_usage == 2'b01) begin
                $display("DEBUG: PE0 can use exact multiplier - aH=%0d, bH=%0d, result=%0d", 
                        pe0.aH, pe0.bH, pe0.exact_mult_result);
            end
            if (counter_for_exact_mult_usage == 2'b10) begin
                $display("DEBUG: PE1 can use exact multiplier - aH=%0d, bH=%0d, result=%0d", 
                        pe1.aH, pe1.bH, pe1.exact_mult_result);
            end
            if (counter_for_exact_mult_usage == 2'b00) begin
                $display("DEBUG: PE2 can use exact multiplier - aH=%0d, bH=%0d, result=%0d", 
                        pe2.aH, pe2.bH, pe2.exact_mult_result);
            end
        end
    end
endmodule