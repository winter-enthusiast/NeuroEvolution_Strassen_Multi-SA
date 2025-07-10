`timescale 1ns/1ps

module exact_mult_1 (
    input [3:0] a, 
    input [3:0] b, 
    output [7:0] p
);
    assign p = a*b; 
endmodule


module approx_3 (
    input [3:0] x, 
    input [3:0] y,
    output [7:0] Y
);
    assign Y = x*y ;
endmodule

module approx_4 (
    input [3:0] x, 
    input [3:0] y,
    output [7:0] Y
);
    assign Y = x*y ;
endmodule

module approx_5 (
    input [3:0] x, 
    input [3:0] y,
    output [7:0] Y
);
    assign Y = x*y ;
endmodule


module PE_1_00_5 #(
    parameter DATA_WIDTH = 8
)(
    input signed [DATA_WIDTH-1:0] a, b,
    input fast_clk,    // 4ns time period
    input clk,       // 12ns time period
    input rst,
    input [1:0] counter_for_exact_mult_usage,
    output reg signed [DATA_WIDTH-1:0] c, d,
    output reg signed [2*DATA_WIDTH-1:0] C_out
);

    // Unsigned absolute values and sign handling
    reg [DATA_WIDTH-1:0] a_abs, b_abs;
    reg a_sign, b_sign, result_sign;
    
    // Split into high and low parts (unsigned)
    wire [3:0] aL, bL;
    wire [3:0] aH, bH;
    wire [7:0] exact_mult_result;

    // Convert signed inputs to unsigned absolute values
    always @(*) begin
        a_sign = a[DATA_WIDTH-1];  // Extract sign bit
        b_sign = b[DATA_WIDTH-1];  // Extract sign bit
        result_sign = a_sign ^ b_sign;  // XOR for final sign
        
        // Get absolute values
        if (a_sign) begin
            a_abs = ~a + 1'b1;  // Two's complement negation
        end else begin
            a_abs = a;
        end
        
        if (b_sign) begin
            b_abs = ~b + 1'b1;  // Two's complement negation
        end else begin
            b_abs = b;
        end
    end

    // Split absolute values into high and low parts
    assign aL = a_abs[3:0];
    assign aH = a_abs[7:4];
    assign bL = b_abs[3:0];
    assign bH = b_abs[7:4];

    reg [2*DATA_WIDTH-1:0] partial_sum;
    reg [3:0] input_to_a, input_to_b;
    
    // Exact multiplier instance
    exact_mult_1 m1(
        .a(input_to_a),
        .b(input_to_b),
        .p(exact_mult_result)
    );
    
    // Combinational logic for exact multiplier inputs
    always @(*) begin
        if (counter_for_exact_mult_usage == 2'b01) begin
            input_to_a = aH;
            input_to_b = bH;
        end 
    end

    wire [7:0] approx_out;
    reg [3:0] input_to_a_approx, input_to_b_approx;

    // PE_3_{3*x+2}__{y}_{exact_mult_index}
    approx_5 approx_LL_1(.x(input_to_a_approx), .y(input_to_b_approx), .Y(approx_out));
    

    // Combinational logic for approx_5 inputs
    always @(*) begin
        case(counter_for_exact_mult_usage)
            2'd1: begin
                input_to_a_approx = aL;
                input_to_b_approx = bL;
            end
            2'd2: begin
                input_to_a_approx = aL;
                input_to_b_approx = bH;
            end
            2'd3: begin
                input_to_a_approx = aH;
                input_to_b_approx = bL;
            end
        endcase
    end

    
    // Sequential logic for partial product accumulation
    always @(posedge fast_clk or posedge rst) begin
        if (rst) begin
            partial_sum <= 0;
            C_out <= 0;
        end else 
        begin
            case(counter_for_exact_mult_usage)
                2'd1: begin
                    partial_sum <= approx_out + (exact_mult_result << 8);  // L*L + H*H
                end
                2'd2: begin
                    partial_sum <= partial_sum + (approx_out << 4);  // + H*L 
                end
                2'd3: begin // 3rd clock we will COMMIT our output 
                    partial_sum <= partial_sum + (approx_out << 4);  // + L*H
                    
                    // Apply sign to final result
                    if (result_sign) begin
                        C_out <= ~(partial_sum + (approx_out << 4)) + 1'b1;  // Two's complement negation
                    end else begin
                        C_out <= partial_sum + (approx_out << 4);
                    end
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c <= 0;
            d <= 0;
        end else begin
            c <= a;
            d <= b;
        end
    end
endmodule

module PE_2_00_5 #(
    parameter DATA_WIDTH = 8
)(
    input signed [DATA_WIDTH-1:0] a, b,
    input fast_clk,    // 4ns time period
    input clk,       // 12ns time period
    input rst,
    input [1:0] counter_for_exact_mult_usage,
    output reg signed [DATA_WIDTH-1:0] c, d,
    output reg signed [2*DATA_WIDTH-1:0] C_out
);

    // Unsigned absolute values and sign handling
    reg [DATA_WIDTH-1:0] a_abs, b_abs;
    reg a_sign, b_sign, result_sign;
    
    // Split into high and low parts (unsigned)
    wire [3:0] aL, bL;
    wire [3:0] aH, bH;
    wire [7:0] exact_mult_result;

    // Convert signed inputs to unsigned absolute values
    always @(*) begin
        a_sign = a[DATA_WIDTH-1];  // Extract sign bit
        b_sign = b[DATA_WIDTH-1];  // Extract sign bit
        result_sign = a_sign ^ b_sign;  // XOR for final sign
        
        // Get absolute values
        if (a_sign) begin
            a_abs = ~a + 1'b1;  // Two's complement negation
        end else begin
            a_abs = a;
        end
        
        if (b_sign) begin
            b_abs = ~b + 1'b1;  // Two's complement negation
        end else begin
            b_abs = b;
        end
    end

    // Split absolute values into high and low parts
    assign aL = a_abs[3:0];
    assign aH = a_abs[7:4];
    assign bL = b_abs[3:0];
    assign bH = b_abs[7:4];

    reg [2*DATA_WIDTH-1:0] partial_sum;
    reg [3:0] input_to_a, input_to_b;
    
    // Exact multiplier instance
    exact_mult_1 m1(
        .a(input_to_a),
        .b(input_to_b),
        .p(exact_mult_result)
    );
    
    // Combinational logic for exact multiplier inputs
    always @(*) begin
        if (counter_for_exact_mult_usage == 2'b10) begin
            input_to_a = aH;
            input_to_b = bH;
        end 
    end

    wire [7:0] approx_out;
    reg [3:0] input_to_a_approx, input_to_b_approx;

    approx_5 approx_LL_2(.x(input_to_a_approx), .y(input_to_b_approx), .Y(approx_out));

    always @(*) begin
            case(counter_for_exact_mult_usage)
                2'd1: begin
                        input_to_a_approx = aL;
                        input_to_b_approx = bL;
                end
                2'd2: begin
                        input_to_a_approx = aL;
                        input_to_b_approx = bH;
                end
                2'd3: begin
                        input_to_a_approx = aH;
                        input_to_b_approx = bL;
                end
        endcase
    end
    
    // Sequential logic for partial product accumulation
    always @(posedge fast_clk or posedge rst) begin
        if (rst) begin
            partial_sum <= 0;
            C_out <= 0;
        end else
        begin
            case(counter_for_exact_mult_usage)
                2'd1: begin
                    partial_sum <= approx_out;  // L*L 
                end
                2'd2: begin
                    partial_sum <= partial_sum + (approx_out << 4) + (exact_mult_result << 8);  // + H*L
                end
                2'd3: begin // 3rd clock we will COMMIT our output 
                    partial_sum <= partial_sum + (approx_out << 4);  // + L*H + H*H
                    
                    // Apply sign to final result
                    if (result_sign) begin
                        C_out <= ~(partial_sum + (approx_out << 4)) + 1'b1;  // Two's complement negation
                    end else begin
                        C_out <= partial_sum + (approx_out << 4);
                    end
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c <= 0;
            d <= 0;
        end else begin
            c <= a;
            d <= b;
        end
    end
endmodule

module PE_3_00_5 #(
    parameter DATA_WIDTH = 8
)(
    input signed [DATA_WIDTH-1:0] a, b,
    input fast_clk,    // 2ns time period
    input clk,       // 12ns time period
    input rst,
    input [1:0] counter_for_exact_mult_usage,
    output reg signed [DATA_WIDTH-1:0] c, d,
    output reg signed [2*DATA_WIDTH-1:0] C_out
);

    // Unsigned absolute values and sign handling
    reg [DATA_WIDTH-1:0] a_abs, b_abs;
    reg a_sign, b_sign, result_sign;
    
    // Split into high and low parts (unsigned)
    wire [3:0] aL, bL;
    wire [3:0] aH, bH;
    wire [7:0] exact_mult_result;

    // Convert signed inputs to unsigned absolute values
    always @(*) begin
        a_sign = a[DATA_WIDTH-1];  // Extract sign bit
        b_sign = b[DATA_WIDTH-1];  // Extract sign bit
        result_sign = a_sign ^ b_sign;  // XOR for final sign
        
        // Get absolute values
        if (a_sign) begin
            a_abs = ~a + 1'b1;  // Two's complement negation
        end else begin
            a_abs = a;
        end
        
        if (b_sign) begin
            b_abs = ~b + 1'b1;  // Two's complement negation
        end else begin
            b_abs = b;
        end
    end

    // Split absolute values into high and low parts
    assign aL = a_abs[3:0];
    assign aH = a_abs[7:4];
    assign bL = b_abs[3:0];
    assign bH = b_abs[7:4];

    reg [2*DATA_WIDTH-1:0] partial_sum;
    reg [3:0] input_to_a, input_to_b;
    
    // Exact multiplier instance
    exact_mult_1 m1(
        .a(input_to_a),
        .b(input_to_b),
        .p(exact_mult_result)
    );
    
    // Combinational logic for exact multiplier inputs
    always @(*) begin
        if (counter_for_exact_mult_usage == 2'b11) begin
            input_to_a = aH;
            input_to_b = bH;
        end 
    end

    wire [7:0] approx_out;
    reg [3:0] input_to_a_approx, input_to_b_approx;
    
    approx_5 approx_LL_3(.x(input_to_a_approx), .y(input_to_b_approx), .Y(approx_out));

    always @(*) begin
            case(counter_for_exact_mult_usage)
                2'd1: begin
                        input_to_a_approx = aL;
                        input_to_b_approx = bL;
                end
                2'd2: begin
                        input_to_a_approx = aL;
                        input_to_b_approx = bH;
                end
                2'd3: begin
                        input_to_a_approx = aH;
                        input_to_b_approx = bL;
                end
        endcase
    end
    
    // Sequential logic for partial product accumulation
    always @(posedge fast_clk or posedge rst) begin
        if (rst) begin
            partial_sum <= 0;
            C_out <= 0;
        end else begin
            case(counter_for_exact_mult_usage)
                2'd1: begin
                    partial_sum <= approx_out;  // L*L + H*H
                end
                2'd2: begin
                    partial_sum <= partial_sum + (approx_out << 4);  // + H*L
                end
                2'd3: begin // 3rd clock we will COMMIT our output 
                    partial_sum <= partial_sum + (approx_out << 4) + (exact_mult_result << 8);  // + L*H
                    
                    // Apply sign to final result
                    if (result_sign) begin
                        C_out <= ~(partial_sum + (approx_out << 4) + (exact_mult_result << 8)) + 1'b1;  // Two's complement negation
                    end else begin
                        C_out <= partial_sum + (approx_out << 4) + (exact_mult_result << 8);
                    end
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c <= 0;
            d <= 0;
        end else begin
            c <= a;
            d <= b;
        end
    end
endmodule