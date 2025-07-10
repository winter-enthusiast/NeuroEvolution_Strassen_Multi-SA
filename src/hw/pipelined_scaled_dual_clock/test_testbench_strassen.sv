`timescale 1ns / 1ps

module tb_strassen_matrix_mult_top;

    // Parameters
    parameter MAT_A_SIZE = 256;
    parameter MAT_B_SIZE = 256;
    parameter ELEM_BITWIDTH = 8;

    // Signals
    logic clk;
    logic rst;
    logic done_final;

    // Instantiate the DUT
    strassen_matrix_mult_top #(
        .MAT_A_SIZE(MAT_A_SIZE),
        .MAT_B_SIZE(MAT_B_SIZE),
        .ELEM_BITWIDTH(ELEM_BITWIDTH)
    ) dut (
        .fast_clk(clk),
        .rst(rst),
        .done_final(done_final)
    );

    // Clock generation: 4ns period
    initial clk = 0;
    always #2 clk = ~clk;

    // Reset sequence
    initial begin
        rst = 1;
        #24;
        rst = 0;
        
        #200;
    end

    

endmodule
