module SystolicArray #(parameter SIZE = 4, parameter DATA_WIDTH = 10)(
    input logic signed [DATA_WIDTH-1:0] A [0:SIZE-1],
    input logic signed [DATA_WIDTH-1:0] B [0:SIZE-1],
    input logic clk,
    input logic rst,
    output logic done,
    output logic signed [2*DATA_WIDTH-1:0] C [0:SIZE-1][0:SIZE-1]
);
    // Internal wires as 2D arrays
    logic signed [DATA_WIDTH-1:0] c [0:SIZE-1][0:SIZE-1];
    logic signed [DATA_WIDTH-1:0] d [0:SIZE-1][0:SIZE-1];
    logic signed [2*DATA_WIDTH-1:0] C_out [0:SIZE-1][0:SIZE-1];
    logic signed [7:0] count;  // Register for counting cycles

    // Generate the PE array
    genvar i, j;
    generate
        for(i = 0; i < SIZE; i++) begin : rows
            for(j = 0; j < SIZE; j++) begin : cols
                if(i == 0 && j == 0) begin
                    PE #(
                        .DATA_WIDTH(DATA_WIDTH)
                    ) pe_inst (
                        .a(A[0]),
                        .b(B[0]),
                        .clk(clk),
                        .rst(rst),
                        .c(c[0][0]),
                        .d(d[0][0]),
                        .C_out(C_out[0][0])
                    );
                end
                else if(i == 0) begin
                    PE #(
                        .DATA_WIDTH(DATA_WIDTH)
                    ) pe_inst (
                        .a(c[i][j-1]),
                        .b(B[j]),
                        .clk(clk),
                        .rst(rst),
                        .c(c[i][j]),
                        .d(d[i][j]),
                        .C_out(C_out[i][j])
                    );
                end
                else if(j == 0) begin
                    PE #(
                        .DATA_WIDTH(DATA_WIDTH)
                    ) pe_inst (
                        .a(A[i]),
                        .b(d[i-1][j]),
                        .clk(clk),
                        .rst(rst),
                        .c(c[i][j]),
                        .d(d[i][j]),
                        .C_out(C_out[i][j])
                    );
                end
                else begin
                    PE #(
                        .DATA_WIDTH(DATA_WIDTH)
                    ) pe_inst (
                        .a(c[i][j-1]),
                        .b(d[i-1][j]),
                        .clk(clk),
                        .rst(rst),
                        .c(c[i][j]),
                        .d(d[i][j]),
                        .C_out(C_out[i][j])
                    );
                end
            end
        end
    endgenerate

    // Assign output C from C_out
    always_comb begin
        for (int i = 0; i < SIZE; i++) begin
            for (int j = 0; j < SIZE; j++) begin
                C[i][j] = C_out[i][j];
            end
        end
    end

    // Cycle counter for computation completion
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
            count <= 0;
        end else begin
            if (count == (2*SIZE+1)) begin
                done <= 1;
            end else begin
                done <= 0;
                count <= count + 1;
            end
        end
    end
endmodule