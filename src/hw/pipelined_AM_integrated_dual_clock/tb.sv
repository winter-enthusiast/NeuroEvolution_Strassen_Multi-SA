`timescale 1ns / 1ps

module bram_pipeline_tb();
    // Testbench signals
    logic clk = 0;
    logic rst;
    
    // Clock generation - 10ns period (100MHz)
    always #5 clk = ~clk;
    
    // Instantiate the Unit Under Test (UUT)
    bram_pipeline uut (
        .clk(clk),
        .rst(rst)
    );
    
    // For monitoring internal signals in testbench
    logic [1:0] tb_addr_a;
    logic [1:0] tb_addr_b;
    logic [511:0] tb_douta_a;
    logic [511:0] tb_douta_b;
    logic [511:0] tb_din_a_d1;
    logic [511:0] tb_din_a_d2;
    logic [511:0] tb_dout_a_d3;
    logic [511:0] tb_din_b_d1;
    logic [511:0] tb_din_b_d2;
    logic [511:0] tb_dout_b_d3;
    
    // Connect internal signals for monitoring
    assign tb_addr_a = uut.addr_a;
    assign tb_addr_b = uut.addr_b;
    assign tb_douta_a = uut.douta_a;
    assign tb_douta_b = uut.douta_b;
    assign tb_din_a_d1 = uut.din_a_d1;
    assign tb_din_a_d2 = uut.din_a_d2;
    assign tb_dout_a_d3 = uut.dout_a_d3;
    assign tb_din_b_d1 = uut.din_b_d1;
    assign tb_din_b_d2 = uut.din_b_d2;
    assign tb_dout_b_d3 = uut.dout_b_d3;
    
    // Test stimulus
    initial begin
        // Initialize
        rst = 1;
        
        // Apply reset for 20ns
        #20;
        rst = 0;
        
        // Run for several clock cycles to observe pipeline behavior
        // We need at least 3 cycles for pipeline to fill up, plus a few more
        // to observe all the stages
        #100;
        
        // Test write operation
        // No explicit writes in this test, but could be added here
        
        // Continue running for additional cycles
        #80;
        
        // End simulation
        $display("Simulation completed");
        $finish;
    end
    
  
    

endmodule