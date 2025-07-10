import os
import numpy as np

modules = { 
0 : """
module approx_0 (
    input [3:0] x, 
    input [3:0] y, 
    output [7:0] Y
);
assign Y = x * y ;
endmodule
""",

1 : """
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
""",

2 : """
module Reh2 (
    input [1:0]x,y,
    output [3:0]Y
);
    assign Y[0] = (x[0] & y[1]) & (x[1] & y[0]) ;        
    assign Y[1] = (x[0] & y[1]) ^ (x[1] & y[0]) ;         
    assign Y[2] =  ((x[0] & y[1]) & (x[1] & y[0]))  ^ (x[1] & y[1]); 
    assign Y[3] =  (x[0] & y[1]) & (x[1] & y[0]) ;
endmodule


module approx_2 (
    input [3:0] x, 
    input [3:0] y, 
    output [7:0] Y
);

    wire [3:0] AL_BL, AH_BL, AL_BH, AH_BH;

    Reh2 m0 (.x(x[1:0]), .y(y[1:0]), .Y(AL_BL));
    Reh2 m1 (.x(x[3:2]), .y(y[1:0]), .Y(AH_BL));
    Reh2 m2 (.x(x[1:0]), .y(y[3:2]), .Y(AL_BH));
    Reh2 m3 (.x(x[3:2]), .y(y[3:2]), .Y(AH_BH));

 
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
""",

3 : """
module approx_3(
    input[3:0] x,y, 
    output [7:0] Y
);

    assign Y[0] = x[0] & y[0];
    assign Y[1] = ( x[1] & y[0] ) | ( x[0] & y[1] );
    assign Y[2] = ( x[2] & y[0] ) | ( x[1] & y[1] ) | ( x[0] & y[2] );
    assign Y[3] = ( x[3] & y[0] ) | ( x[2] & y[1] )| ( x[1] & y[2] ) | ( x[0] & y[3] ) ;
    assign Y[4] = ( x[3] & y[1] ) | ( x[2] & y[2] ) | ( x[1] & y[3]) ;
    assign Y[5] = ( x[3] & y[2] ) | ( x[2] & y[3] ) ;
    assign Y[6] = ( x[3] & y[3] ) & ( ~( x[2] & y[2] ) ) ;
    assign Y[7] = ( x[3] & y[3] ) & ( x[2] & y[2] ) ;

endmodule
""",

4 : """
module approx_4(
    input[3:0] x,y, 
    output [7:0] Y
);


    assign Y[0] = x[0] & y[0];
    assign Y[1] = ( x[1] & y[0] ) | ( x[0] & y[1] );
    assign Y[2] = ( x[2] & y[0] ) | ( x[1] & y[1] ) | ( x[0] & y[2] );
    assign Y[3] = ( x[3] & y[0] ) | ( x[2] & y[1] )| ( x[1] & y[2] ) | ( x[0] & y[3] ) ;

    // partial product declaration for ease
    wire a3b1 = x[3] & y[1] ; 
    wire a2b2 = x[2] & y[2] ; 
    wire a1b3 = x[1] & y[3] ; 
    wire a3b2 = x[3] & y[2] ; 
    wire a2b3 = x[2] & y[3] ; 
    wire a3b3 = x[3] & y[3] ;

    wire C_45_1_approx = a2b2 & ( a1b3 | a3b1 ) ;
    wire C_56_2_approx = a2b2 & ( a3b3 | a3b1 | a1b3) ;

    assign Y[4] = a3b1 | a2b2 | a1b3 ;
    assign Y[5] = a3b2 ^ (a2b3) ^ (C_45_1_approx) ; // this is supposed to x single XOR gate with 3 inputs 
    assign Y[6] = a3b3 & (~a2b2) | (~a3b3) & (a2b2) & (a3b1 | a1b3) ;
    assign Y[7] = a2b2 & a3b3 ;

endmodule
""",

5 : """
module mul2a (
    input wire [1:0]x, y,
    output wire [2:0]Y
);

    assign Y[2] = x[1] & y[1];
    assign Y[1] = (x[0] & y[1]) | (x[1] & y[0]);
    assign Y[0] = x[1] & y[0];

endmodule

module approx_5 (
    input wire [3:0] x,  
    input wire [3:0] y,  
    output wire [7:0] Y
);

    wire [2:0] product1, product2, product3, product4;

    mul2a mul1(.x(x[1:0]), .y(y[1:0]), .Y(product1)); 
    mul2a mul2(.x(x[1:0]), .y(y[3:2]), .Y(product2)); 
    mul2a mul3(.x(x[3:2]), .y(y[1:0]), .Y(product3)); 
    mul2a mul4(.x(x[3:2]), .y(y[3:2]), .Y(product4)); 

    assign Y = product1 + (product2 << 2) + (product3 << 2) + (product4 << 4);

endmodule
""",

6 : """
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
""",

7 : """
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
""",

8 : """
module ha_adder(
	input A,
	input B,
	output S,
	output C
);
assign S = A ^ B;
assign C = A & B;
endmodule


module Compressor_4_2_Table_4_approx_8(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x3;
assign carry = x2 | x4;
endmodule

module Compressor_4_2_Table_6_approx_8(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x3 | x4;
assign carry = (x1 & x2) | (x3 & x4);
endmodule

module Compressor_4_2_Table_6_approx_8(
    input x1, x2, x3, x4,
    output sum, carry
);
assign sum = x1 | x2 | x3;
assign carry = x2 | (x3 & x4);
endmodule

module approx_8(
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
    ha_adder HA1 (.A(pp01), .B(pp10), .S(S_1), .C(C_1));
    assign Y[1] = S_1;

    wire S_2, C_2;
    wire P20 = pp20 | pp02;
    wire G20 = pp20 & pp02;
    Compressor_4_2_Table_4_approx_8 C1 (.x1(P20), .x2(G20), .x3(pp11), .x4(C_1), .sum(S_2), .carry(C_2));
    assign Y[2] = S_2;

    wire S_3, C_3;
    wire G30 = pp30 & pp03;
    wire G21 = pp21 & pp12;
    wire P21 = pp21 | pp12;
    wire P30 = pp30 | pp03;
    Compressor_4_2_Table_6_approx_8 C2 (.x1(C_2), .x2(G30 | G21), .x3(P21), .x4(P30), .sum(S_3), .carry(C_3));
    assign Y[3] = S_3;

    wire S_4, C_4;
    wire P31 = pp31 | pp13;
    wire G31 = pp31 & pp13;
    wire P22 = pp22 | pp22;
    Compressor_4_2_Table_6_approx_8 C3 (.x1(P31), .x2(G31), .x3(pp22), .x4(C_3), .sum(S_4), .carry(C_4));
    assign Y[4] = S_4;

    wire S_5, C_5;
    ha_adder HA2 (.A(pp32), .B(pp23), .S(S_5), .C(C_5));
    assign Y[5] = S_5;

    wire S_6, C_6;
    ha_adder HA3 (.A(pp33), .B(C_5), .S(S_6), .C(C_6));
    assign Y[6] = S_6;

    assign Y[7] = C_6;

endmodule
""",

9 :  """
module approx_9(
    input[3:0] x,y, 
    output [7:0] Y
);

    assign Y[0] = x[0] & y[0];
    assign Y[1] = ( x[1] & y[0] ) | ( x[0] & y[1] );
    assign Y[2] = ( x[2] & y[0] ) | ( x[1] & y[1] ) | ( x[0] & y[2] );
    assign Y[3] = ( x[3] & y[0] ) | ( x[2] & y[1] )| ( x[1] & y[2] ) | ( x[0] & y[3] ) ;
    assign Y[4] = ( x[3] & y[1] ) | ( x[2] & y[2] ) | ( x[1] & y[3]) ;
    assign Y[5] = ( x[3] & y[2] ) | ( x[2] & y[3] );
    assign Y[6] = x[3] & y[3];

    // Either is fine, 1 is better if inputs are greater than 1000 ; 0 is better if lesser
    assign Y[7] = 1 ;
    // assign Y[7] = 0 ;

endmodule
"""
}

# Construct the complete code by including only present modules
# based on array_4096 we'll append the above code
arr = np.loadtxt('array_config_1.dat', dtype=np.int8)

# Find which values (0-9) are present in the array
unique_values = np.unique(arr)
is_present = [i in unique_values for i in range(10)]
display_is_present = {i:v for i,v in enumerate(is_present)}

# Construct the complete code by including only present modules
complete_code = "".join(modules[i] for i in range(10) if is_present[i])

print(f"IS_PRESENT ARRAY FOR THIS CONFIG :\n {display_is_present}")

output_file = 'rtl/approx_mults.v'
with open(output_file, 'w') as f:
    f.write("\n\n// Auto-generated module instantiations\n")
    f.write(complete_code)
