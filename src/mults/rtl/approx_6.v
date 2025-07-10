module mul2b (
    input wire [1:0]x,y,
    output wire [2:0]Y
);

    assign Y[2] = x[1] & y[1];
    assign Y[1] = x[0] & y[0];
    assign Y[0] = x[0] & y[0];
endmodule


module approx_6 (
    input wire [3:0] x,  
    input wire [3:0] y,  
    output wire [7:0] Y
);

    wire [2:0] product1, product2, product3, product4;

    mul2b mul1(.x(x[1:0]), .y(y[1:0]), .Y(product1)); 
    mul2b mul2(.x(x[1:0]), .y(y[3:2]), .Y(product2)); 
    mul2b mul3(.x(x[3:2]), .y(y[1:0]), .Y(product3)); 
    mul2b mul4(.x(x[3:2]), .y(y[3:2]), .Y(product4)); 

    assign Y = product1 + (product2 << 2) + (product3 << 2) + (product4 << 4);

endmodule