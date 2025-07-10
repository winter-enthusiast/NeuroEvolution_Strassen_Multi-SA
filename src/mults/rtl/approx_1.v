module Kul2(
    input [1:0]x,y,
    output [3:0]Y
);
    assign Y[0] = x[0] & y[0];
    assign Y[1] = (x[1] & y[0]) | (x[0] & y[1]);
    assign Y[2] = x[1] & y[1];
    assign Y[3] = 0;
endmodule

module approx_1 (
    input [3:0] x, 
    input [3:0] y, 
    output [7:0] Y
);

    wire [3:0] AL_BL, AH_BL, AL_BH, AH_BH;

    Kul2 m0 (.x(x[1:0]), .y(y[1:0]), .Y(AL_BL));
    Kul2 m1 (.x(x[3:2]), .y(y[1:0]), .Y(AH_BL));
    Kul2 m2 (.x(x[1:0]), .y(y[3:2]), .Y(AL_BH));
    Kul2 m3 (.x(x[3:2]), .y(y[3:2]), .Y(AH_BH));

 
    wire [7:0] padded_AL_BL;
    wire [7:0] padded_AH_BL;
    wire [7:0] padded_AL_BH;
    wire [7:0] padded_AH_BH;

    assign padded_AL_BL = {4'b0, AL_BL};       
    assign padded_AH_BL = {2'b0, AH_BL, 2'b0}; 
    assign padded_AL_BH = {2'b0, AL_BH, 2'b0}; 
    assign padded_AH_BH = {AH_BH, 4'b0};       

    assign Y = padded_AL_BL + padded_AH_BL + padded_AL_BH + padded_AH_BH;

endmodule