module mul2a (
    input wire [1:0]a, b,
    output wire [2:0]Y
);

    assign Y[2] = a[1] & b[1];
    assign Y[1] = (a[0] & b[1]) | (a[1] & b[0]);
    assign Y[0] = a[1] & b[0];

endmodule

module approx_5 (
    input wire [3:0] x,  
    input wire [3:0] y,  
    output wire [7:0] Y
);

    wire [2:0] product1, product2, product3, product4;

    mul2a mul1(.a(x[1:0]), .b(y[1:0]), .Y(product1)); 
    mul2a mul2(.a(x[1:0]), .b(y[3:2]), .Y(product2)); 
    mul2a mul3(.a(x[3:2]), .b(y[1:0]), .Y(product3)); 
    mul2a mul4(.a(x[3:2]), .b(y[3:2]), .Y(product4)); 

    assign Y = product1 + (product2 << 2) + (product3 << 2) + (product4 << 4);

endmodule