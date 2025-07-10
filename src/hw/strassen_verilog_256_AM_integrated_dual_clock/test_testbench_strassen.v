`timescale 1ns / 1ps

module tb_strassen_matrix_mult_top;
    // Parameters
    parameter MAT_SIZE = 256;
    parameter ELEM_BITWIDTH = 8;
    parameter ROW_WIDTH = MAT_SIZE * ELEM_BITWIDTH;  // 2048 bits

    // DUT inputs and outputs
    reg clk;
    reg fast_clk;
    reg rst;
    reg [0:ROW_WIDTH-1] A;
    reg [0:ROW_WIDTH-1] B;
    wire [(256*256*23)-1:0] C;  // packed output matrix
    wire done_final;

    // DUT instantiation
    strassen_matrix_mult_top #(
        .MAT_A_SIZE(MAT_SIZE),
        .MAT_B_SIZE(MAT_SIZE),
        .ELEM_BITWIDTH(ELEM_BITWIDTH)
    ) dut (
        .fast_clk(fast_clk),
        .rst(rst),
        .A(A),
        .B(B),
        .C_packed(C),
        .done_C_oneclk(done_final)
    );

    // Fast clock generation
    initial begin
        fast_clk = 0;
        forever #2 fast_clk = ~fast_clk; // 4ns period
    end

    // Clock divider logic to generate `clk` from `fast_clk`
    reg [1:0] clk_counter;
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

    // Memory for matrices
    reg [ROW_WIDTH-1:0] matrix_A_mem [0:MAT_SIZE-1];
    reg [ROW_WIDTH-1:0] matrix_B_mem [0:MAT_SIZE-1];

    // Indexing variables
    integer group = 0;
    integer offset = 0;
    integer row_index;

    // Reset and initialization
    initial begin
        // Load memory contents
        $readmemb("/home/kanish/nishith/verilog_src_256/strassen_verilog_256/matrix_A.txt", matrix_A_mem);
        $readmemb("/home/kanish/nishith/verilog_src_256/strassen_verilog_256/matrix_B.txt", matrix_B_mem);

        A = 0;
        B = 0;
        rst = 1;
        #24 rst = 0;
    end

    // Drive A and B inputs
    always @(posedge clk) begin
        if (!rst && group < 64) begin
            row_index = group + offset * 64;
            A <= matrix_A_mem[row_index];
            B <= matrix_B_mem[row_index];
            offset = offset + 1;
            if (offset == 4) begin
                offset = 0;
                group = group + 1;
            end
        end
    end

    // Unpacked C matrix
    reg signed [22:0] C_unpacked [0:255][0:255];
    integer i, j;
    integer outfile;
    reg done_prev;

    initial done_prev = 0;

    // Unpack and write once done_final goes high
    always @(posedge clk) begin
        if (!done_prev && done_final) begin
            // Unpack C_packed
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    C_unpacked[i][j] = C[(((i * 256 + j) + 1) * 23) - 1 -: 23];
                end
            end

            // Write to file
            outfile = $fopen("/home/kanish/nishith/verilog_src_256/strassen_verilog_256/output_C_matrix.txt", "w");
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    $fwrite(outfile, "%0d ", C_unpacked[i][j]);
                end
                $fwrite(outfile, "\n");
            end
            $fclose(outfile);

            $display("✅ Matrix C unpacked and written to output_C_matrix.txt");
//            $finish;
        end

        done_prev <= done_final;
    end
endmodule