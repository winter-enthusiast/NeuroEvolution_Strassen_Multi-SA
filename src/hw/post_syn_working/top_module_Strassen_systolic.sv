module top (
    input logic clk,
    input logic rst,
    input logic start,
    output logic [4095:0] C,  // 16*16*16 = 4096 bits (256 elements * 16 bits each)
    output logic done
);
    // Internal 2D array for the matrix multiplication result
    logic signed [15:0] C_2D [0:15][0:15];
    
    // Instantiate the Strassen matrix multiplication module
    strassen_matrix_mult strassen_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .C(C_2D),
        .done(done)
    );
    
    // Pack the 2D array into a wide vector
    for (genvar i = 0; i < 16; i++) begin : row_gen
        for (genvar j = 0; j < 16; j++) begin : col_gen
            assign C[(i*16+j)*16 +: 16] = C_2D[i][j];
        end
    end

endmodule