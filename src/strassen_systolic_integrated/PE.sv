// PE module in SystemVerilog
module PE #(parameter DATA_WIDTH = 10)(
    input logic signed [DATA_WIDTH-1:0] a, b, 
    input logic clk, rst,
    output logic signed [DATA_WIDTH-1:0] c, d,
    output logic signed [2*DATA_WIDTH-1:0] C_out
);
    logic signed [2*DATA_WIDTH-1:0] multi;
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            C_out <= 0;
            c <= 0;
            d <= 0;
        end
        else begin
            C_out <= C_out + multi;
            c <= a;
            d <= b;
        end
    end
    
    assign multi = a * b;
endmodule
