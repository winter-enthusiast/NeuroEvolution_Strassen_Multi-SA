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
//module PE #(parameter DATA_WIDTH = 10)(
//    input logic signed [DATA_WIDTH-1:0] a, b, 
//    input logic clk, rst,
//    output logic signed [DATA_WIDTH-1:0] c, d,
//    output logic signed [2*DATA_WIDTH-1:0] C_out
//);
//    logic signed [2*DATA_WIDTH-1:0] multi, accum;
    
//    // State definition
//    typedef enum logic {
//        COMPUTE,
//        UPDATE
//    } state_t;
    
//    state_t current_state, next_state;
    
//    // State register
//    always_ff @(posedge clk) begin
//        if (rst)
//            current_state <= COMPUTE;
//        else
//            current_state <= next_state;
//    end
    
//    // Next state logic
//    always_comb begin
//        case (current_state)
//            COMPUTE: next_state = UPDATE;
//            UPDATE:  next_state = COMPUTE;
//            default: next_state = COMPUTE;
//        endcase
//    end
    
//    // Datapath - Computing multi
//    assign multi = a * b;
    
//    // Datapath - Sequential logic for accum and C_out
//    always_ff @(posedge clk) begin
//        if (rst) begin
//            accum <= '0;
//            C_out <= '0;
//            c <= '0;
//            d <= '0;
//        end
//        else begin
//            case (current_state)
//                COMPUTE: begin
//                    accum <= C_out + multi;  // First stage: calculate accumulation
//                    c <= a;
//                    d <= b;
//                end
//                UPDATE: begin
//                    C_out <= accum;          // Second stage: update output
//                end
//                default: begin
//                    // Do nothing
//                end
//            endcase
//        end
//    end
//endmodule