module half_adder(
	input A,
	input B,
	output S,
	output C
);

assign S = A ^ B;
assign C = A & B;

endmodule


module full_adder(
	input A,
	input B,
	input Cin,
	output S,
	output Cout
);

assign S = A ^ B ^ Cin;
assign Cout = (A & B) | (Cin & (A^B));

endmodule


module Compressor_4_2_Table_4(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x3;
assign carry = x2 | x4;
endmodule



module Compressor_4_2_Table_5(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x3 | x4;
assign carry = (x1 & x2) | (x3 & x4);
endmodule

module Compressor_4_2_Table_6(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x2 | x3;
assign carry = x2 | (x3 & x4);
endmodule



module approx_7(
    input [3:0] x,
    input [3:0] y,
    output [7:0] Y
);

    wire pp00 = x[0] & y[0];
    wire pp01 = x[0] & y[1];
    wire pp10 = x[1] & y[0];
    wire pp11 = x[1] & y[1];
    wire pp02 = x[0] & y[2];
    wire pp20 = x[2] & y[0];
    wire pp21 = x[2] & y[1];
    wire pp12 = x[1] & y[2];
    wire pp30 = x[3] & y[0];
    wire pp03 = x[0] & y[3];
    wire pp31 = x[3] & y[1];
    wire pp13 = x[1] & y[3];
    wire pp22 = x[2] & y[2];
    wire pp23 = x[2] & y[3];
    wire pp32 = x[3] & y[2];
    wire pp33 = x[3] & y[3];

    assign Y[0] = pp00;

    wire S_1, C_1;
    half_adder HA1 (.A(pp01), .B(pp10), .S(S_1), .C(C_1));
    assign Y[1] = S_1;

    wire S_2, C_2;
    wire P20 = pp20 | pp02;
    wire G20 = pp20 & pp02;
    // wire G10 = pp10 & pp01;
    Compressor_4_2_Table_4 C1 (.x1(P20), .x2(G20), .x3(pp11), .x4(C_1), .sum(S_2), .carry(C_2));
    assign Y[2] = S_2;

    wire S_3, C_3;
    wire G30 = pp30 & pp03;
    wire G21 = pp21 & pp12;
    wire P21 = pp21 | pp12;
    wire P30 = pp30 | pp03;
    Compressor_4_2_Table_5 C2 (.x1(C_2), .x2(G30 | G21), .x3(P21), .x4(P30), .sum(S_3), .carry(C_3));
    assign Y[3] = S_3;

    wire S_4, C_4;
    wire P31 = pp31 | pp13;
    wire G31 = pp31 & pp13;
    wire P22 = pp22 | pp22;
    Compressor_4_2_Table_6 C3 (.x1(P31), .x2(G31), .x3(pp22), .x4(C_3), .sum(S_4), .carry(C_4));
    assign Y[4] = S_4;

    wire S_5, C_5;
    full_adder FA1 (.A(pp32), .B(pp23), .Cin(C_4), .S(S_5), .Cout(C_5));
    assign Y[5] = S_5;

    wire S_6, C_6;
    half_adder HA2 (.A(pp33), .B(C_5), .S(S_6), .C(C_6));
    assign Y[6] = S_6;

    assign Y[7] = C_6;

endmodule