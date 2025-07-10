module satop #(parameter BITWIDTH = 32)
(input CLK, reset, input [ BITWIDTH - 1 : 0 ] A10,A11,A12,A20,A21,A22,A30,A31,A32,B100,B101,B102,B110,B111,B112,B120,B121,B122,B200,B201,B202,B210,B211,B212,B220,B221,B222,B300,B301,B302,B310,B311,B312,B320,B321,B322, output [BITWIDTH-1 : 0] OUT11,OUT12,OUT13,OUT21,OUT22,OUT23,OUT31,OUT32,OUT33);

sa_1 SA1(.CLK(CLK),.reset(reset),.A0(A10),.A1(A11),.A2(A12),.B00(B100),.B01(B101),.B02(B102),.B10(B110),.B11(B111),.B12(B112),.B20(B120),.B21(B121),.B22(B122),.OUT1(OUT11),.OUT2(OUT12),.OUT3(OUT13));
sa_2 SA2(.CLK(CLK),.reset(reset),.A0(A20),.A1(A21),.A2(A22),.B00(B200),.B01(B201),.B02(B202),.B10(B210),.B11(B211),.B12(B212),.B20(B220),.B21(B221),.B22(B222),.OUT1(OUT21),.OUT2(OUT22),.OUT3(OUT23));
sa_3 SA3(.CLK(CLK),.reset(reset),.A0(A30),.A1(A31),.A2(A32),.B00(B300),.B01(B301),.B02(B302),.B10(B310),.B11(B311),.B12(B312),.B20(B320),.B21(B321),.B22(B322),.OUT1(OUT31),.OUT2(OUT32),.OUT3(OUT33));

endmodule

module sa_1 #(parameter BITWIDTH = 32)
(input CLK, reset, input [ BITWIDTH - 1 : 0 ] A0,A1,A2,B00,B01,B02,B10,B11,B12,B20,B21,B22, output [BITWIDTH-1 : 0] OUT1,OUT2,OUT3);

wire [ BITWIDTH - 1 : 0 ] next_a00,next_a01,next_a02,next_a10,next_a11,next_a12,next_a20,next_a21,next_a22;
wire [BITWIDTH-1 : 0] mac_op00,mac_op01,mac_op02,mac_op10,mac_op11,mac_op12;

PE_fp32 PE00(.CLK(CLK),.reset(reset),.A(A0)      ,.B(B00),.prev_op(0),.Next_A(next_a00),.PE_res(mac_op00));
PE_fp32 PE01(.CLK(CLK),.reset(reset),.A(next_a00),.B(B01),.prev_op(0),.Next_A(next_a01),.PE_res(mac_op01));
PE_fp32 PE02(.CLK(CLK),.reset(reset),.A(next_a01),.B(B02),.prev_op(0),.Next_A(next_a02),.PE_res(mac_op02));

PE_fp32 PE10(.CLK(CLK),.reset(reset),.A(A1),      .B(B10),.prev_op(mac_op00),.Next_A(next_a10),.PE_res(mac_op10));
PE_fp32 PE11(.CLK(CLK),.reset(reset),.A(next_a10),.B(B11),.prev_op(mac_op01),.Next_A(next_a11),.PE_res(mac_op11));
PE_fp32 PE12(.CLK(CLK),.reset(reset),.A(next_a11),.B(B12),.prev_op(mac_op02),.Next_A(next_a12),.PE_res(mac_op12));

PE_fp32 PE20(.CLK(CLK),.reset(reset),.A(A2),      .B(B20),.prev_op(mac_op10),.Next_A(next_a20),.PE_res(OUT1));
PE_fp32 PE21(.CLK(CLK),.reset(reset),.A(next_a20),.B(B21),.prev_op(mac_op11),.Next_A(next_a21),.PE_res(OUT2));
PE_fp32 PE22(.CLK(CLK),.reset(reset),.A(next_a21),.B(B22),.prev_op(mac_op12),.Next_A(next_a22),.PE_res(OUT3));

endmodule

module sa_2 #(parameter BITWIDTH = 32)
(input CLK, reset, input [ BITWIDTH - 1 : 0 ] A0,A1,A2,B00,B01,B02,B10,B11,B12,B20,B21,B22, output [BITWIDTH-1 : 0] OUT1,OUT2,OUT3);

wire [ BITWIDTH - 1 : 0 ] next_a00,next_a01,next_a02,next_a10,next_a11,next_a12,next_a20,next_a21,next_a22;
wire [BITWIDTH-1 : 0] mac_op00,mac_op01,mac_op02,mac_op10,mac_op11,mac_op12;

PE_fp32 PE00(.CLK(CLK),.reset(reset),.A(A0)      ,.B(B00),.prev_op(0),.Next_A(next_a00),.PE_res(mac_op00));
PE_fp32 PE01(.CLK(CLK),.reset(reset),.A(next_a00),.B(B01),.prev_op(0),.Next_A(next_a01),.PE_res(mac_op01));
PE_fp32 PE02(.CLK(CLK),.reset(reset),.A(next_a01),.B(B02),.prev_op(0),.Next_A(next_a02),.PE_res(mac_op02));

PE_fp32 PE10(.CLK(CLK),.reset(reset),.A(A1),      .B(B10),.prev_op(mac_op00),.Next_A(next_a10),.PE_res(mac_op10));
PE_fp32 PE11(.CLK(CLK),.reset(reset),.A(next_a10),.B(B11),.prev_op(mac_op01),.Next_A(next_a11),.PE_res(mac_op11));
PE_fp32 PE12(.CLK(CLK),.reset(reset),.A(next_a11),.B(B12),.prev_op(mac_op02),.Next_A(next_a12),.PE_res(mac_op12));

PE_fp32 PE20(.CLK(CLK),.reset(reset),.A(A2),      .B(B20),.prev_op(mac_op10),.Next_A(next_a20),.PE_res(OUT1));
PE_fp32 PE21(.CLK(CLK),.reset(reset),.A(next_a20),.B(B21),.prev_op(mac_op11),.Next_A(next_a21),.PE_res(OUT2));
PE_fp32 PE22(.CLK(CLK),.reset(reset),.A(next_a21),.B(B22),.prev_op(mac_op12),.Next_A(next_a22),.PE_res(OUT3));

endmodule

module sa_3 #(parameter BITWIDTH = 32)
(input CLK, reset, input [ BITWIDTH - 1 : 0 ] A0,A1,A2,B00,B01,B02,B10,B11,B12,B20,B21,B22, output [BITWIDTH-1 : 0] OUT1,OUT2,OUT3);

wire [ BITWIDTH - 1 : 0 ] next_a00,next_a01,next_a02,next_a10,next_a11,next_a12,next_a20,next_a21,next_a22;
wire [BITWIDTH-1 : 0] mac_op00,mac_op01,mac_op02,mac_op10,mac_op11,mac_op12;

PE_fp32 PE00(.CLK(CLK),.reset(reset),.A(A0)      ,.B(B00),.prev_op(0),.Next_A(next_a00),.PE_res(mac_op00));
PE_fp32 PE01(.CLK(CLK),.reset(reset),.A(next_a00),.B(B01),.prev_op(0),.Next_A(next_a01),.PE_res(mac_op01));
PE_fp32 PE02(.CLK(CLK),.reset(reset),.A(next_a01),.B(B02),.prev_op(0),.Next_A(next_a02),.PE_res(mac_op02));

PE_fp32 PE10(.CLK(CLK),.reset(reset),.A(A1),      .B(B10),.prev_op(mac_op00),.Next_A(next_a10),.PE_res(mac_op10));
PE_fp32 PE11(.CLK(CLK),.reset(reset),.A(next_a10),.B(B11),.prev_op(mac_op01),.Next_A(next_a11),.PE_res(mac_op11));
PE_fp32 PE12(.CLK(CLK),.reset(reset),.A(next_a11),.B(B12),.prev_op(mac_op02),.Next_A(next_a12),.PE_res(mac_op12));

PE_fp32 PE20(.CLK(CLK),.reset(reset),.A(A2),      .B(B20),.prev_op(mac_op10),.Next_A(next_a20),.PE_res(OUT1));
PE_fp32 PE21(.CLK(CLK),.reset(reset),.A(next_a20),.B(B21),.prev_op(mac_op11),.Next_A(next_a21),.PE_res(OUT2));
PE_fp32 PE22(.CLK(CLK),.reset(reset),.A(next_a21),.B(B22),.prev_op(mac_op12),.Next_A(next_a22),.PE_res(OUT3));

endmodule




//************************************ Float32 PE ************************************//
module PE_fp32(input CLK, reset, input [31 : 0] A,B,prev_op, 
                    output [31 : 0] Next_A, PE_res);

reg  [31:0] Next_A_reg;
reg  [31:0] fb_accum;
wire [31:0] mac_op;

fp32_mac multadd(.A(A),.B(B),.FB_accum(prev_op),.mac_op(mac_op));
    
always @ ( posedge CLK or negedge reset )
begin
	if (!reset)
	begin
		Next_A_reg <= 0;
		fb_accum <= 0;
	end
	
	else 
	begin
		Next_A_reg <= A;
        fb_accum <= mac_op;
	end
end


assign PE_res = fb_accum;
assign Next_A = Next_A_reg;

endmodule
//************************************ Float32 MAC ************************************//
module fp32_mac(
    input  [31 : 0] A,
	  input  [31 : 0] B,
	  input  [31 : 0] FB_accum,
	  output [31 : 0] mac_op
  );
 
wire  [31 : 0] mulres;

fp32_mul mul(.a_operand(A),.b_operand(B),.result(mulres));
fp32_add add(.X(mulres),.Y(FB_accum),.res(mac_op));

endmodule

//************************************ Float32 Adder ************************************//
module fp32_add(X, Y, res);

input [31:0] X, Y;   // IEEE 754 format inputs
output [31:0] res;   // IEEE 754 format output

// Internal signals
reg [7:0] X_exp, Y_exp, res_exp;
reg [23:0] X_mant, Y_mant;   // Mantissa with implicit 1
reg [24:0] res_mant;         // Result mantissa can be 25 bits to accommodate carry
reg X_sign, Y_sign, res_sign;
reg [8:0] expsub;
reg [7:0] abs_diff;  // 9-bit to handle signed difference
reg [24:0] mant_diff;        // Temporary mantissa result

// Special case flags
wire X_is_zero, Y_is_zero;
wire X_is_inf, Y_is_inf;
wire X_is_nan, Y_is_nan;

// IEEE754 representations
parameter FP32_ZERO      = 32'h00000000;
parameter FP32_INF_POS   = 32'h7F800000;
parameter FP32_INF_NEG   = 32'hFF800000;
parameter FP32_NAN       = 32'h7FC00000;

// Output assignment
assign res = {res_sign, res_exp, res_mant[22:0]};

// Special case checks
assign X_is_zero = (X[30:0] == 31'b0);
assign Y_is_zero = (Y[30:0] == 31'b0);
assign X_is_inf  = (X[30:23] == 8'hFF && X[22:0] == 23'b0);
assign Y_is_inf  = (Y[30:23] == 8'hFF && Y[22:0] == 23'b0);
assign X_is_nan  = (X[30:23] == 8'hFF && X[22:0] != 23'b0);
assign Y_is_nan  = (Y[30:23] == 8'hFF && Y[22:0] != 23'b0);

always @(*) begin
    // Step 1: Check for NaN inputs
    if (X_is_nan || Y_is_nan) begin
        res_sign = 1'b0;        // NaN is unsigned
        res_exp  = 8'hFF;       // NaN exponent
        res_mant = 23'h400000;  // Quiet NaN (QNaN) with leading 1 in the mantissa
    end
    // Step 2: Handle infinities
    else if (X_is_inf || Y_is_inf) begin
        if (X_is_inf && Y_is_inf && (X_sign != Y_sign)) begin
            // Positive and negative infinity, return NaN
            res_sign = 1'b0;
            res_exp  = 8'hFF;
            res_mant = 23'h400000;  // NaN
        end else if (X_is_inf) begin
            res_sign = X_sign;
            res_exp  = 8'hFF;
            res_mant = 23'b0;       // Infinity
        end else begin
            res_sign = Y_sign;
            res_exp  = 8'hFF;
            res_mant = 23'b0;       // Infinity
        end
    end
    // Step 3: Handle zero cases
    else if (X_is_zero && Y_is_zero) begin
        // Both are zero, return positive zero
        res_sign = 1'b0;
        res_exp  = 8'b0;
        res_mant = 23'b0;
    end else if (X_is_zero) begin
        // Return Y if X is zero
        res_sign = Y_sign;
        res_exp  = Y_exp;
        res_mant = Y_mant[22:0];
    end else if (Y_is_zero) begin
        // Return X if Y is zero
        res_sign = X_sign;
        res_exp  = X_exp;
        res_mant = X_mant[22:0];
    end
    // Step 4: Handle normal numbers (non-special cases)
    else begin
            // Extract sign, exponent, and mantissa
            X_sign = X[31];
            Y_sign = Y[31];
            X_exp = X[30:23];
            Y_exp = Y[30:23];
            X_mant = {1'b1, X[22:0]};  // Implicit 1 added
            Y_mant = {1'b1, Y[22:0]};  // Implicit 1 added

            // Align exponents
            expsub = X_exp - Y_exp;
            abs_diff = expsub[8] ? ~expsub[7:0] + 1'b1 : expsub[7:0]; // Absolute difference
            if (expsub[8]) begin
                X_mant = X_mant >> abs_diff;  // Shift X mantissa if X_exp < Y_exp
                res_exp = Y_exp;              // Use Y's exponent
            end else begin
                Y_mant = Y_mant >> abs_diff;  // Shift Y mantissa if Y_exp < X_exp
                res_exp = X_exp;              // Use X's exponent
            end

            // Add or subtract mantissas based on signs
            if (X_sign == Y_sign) begin
                res_mant = X_mant + Y_mant;  // Same sign -> add mantissas
                res_sign = X_sign;           // Result sign is the same as input sign
            end else begin
                mant_diff = (X_mant > Y_mant) ? X_mant - Y_mant : Y_mant - X_mant;
                res_sign = (X_mant > Y_mant) ? X_sign : Y_sign;  // Result takes the sign of the larger magnitude
                res_mant = mant_diff;
            end

            // Normalize result (make bit 23 = 1)
            if (res_mant[24]) begin  // Check if carry generated
                res_mant = res_mant >> 1;    // Shift right
                res_exp = res_exp + 1'b1;    // Increment exponent
//                if (res_mant[0]!=0) begin
//                    res_mant=res_mant+1'b1;
//                end
            end else begin 
                if (!res_mant[23]) begin
                    if (res_mant[22]) begin
                        res_mant = res_mant << 1;
                        res_exp  = res_exp - 1'b1;
                    end else if (res_mant[21]) begin
                        res_mant = res_mant << 2;
                        res_exp  = res_exp - 2'b10;
                    end else if (res_mant[20]) begin
                        res_mant = res_mant << 3;
                        res_exp  = res_exp - 3'b011;
                    end else if (res_mant[19]) begin
                        res_mant = res_mant << 4;
                        res_exp  = res_exp - 3'b100;
                    end else if (res_mant[18]) begin
                        res_mant = res_mant << 5;
                        res_exp  = res_exp - 3'b101;
                    end else if (res_mant[17]) begin
                        res_mant = res_mant << 6;
                        res_exp  = res_exp - 3'b110;
                    end else if (res_mant[16]) begin
                        res_mant = res_mant << 7;
                        res_exp  = res_exp - 3'b111;
                    end else if (res_mant[15]) begin
                        res_mant = res_mant << 8;
                        res_exp  = res_exp - 4'b1000;
                    end else if (res_mant[14]) begin
                        res_mant = res_mant << 9;
                        res_exp  = res_exp - 4'b1001;
                    end else if (res_mant[13]) begin
                        res_mant = res_mant << 10;
                        res_exp  = res_exp - 4'b1010;
                    end else if (res_mant[12]) begin
                        res_mant = res_mant << 11;
                        res_exp  = res_exp - 4'b1011;
                    end else if (res_mant[11]) begin
                        res_mant = res_mant << 12;
                        res_exp  = res_exp - 4'b1100;
                    end else if (res_mant[10]) begin
                        res_mant = res_mant << 13;
                        res_exp  = res_exp - 4'b1101;
                    end else if (res_mant[9]) begin
                        res_mant = res_mant << 14;
                        res_exp  = res_exp - 4'b1110;
                    end else if (res_mant[8]) begin
                        res_mant = res_mant << 15;
                        res_exp  = res_exp - 4'b1111;
                    end else if (res_mant[7]) begin
                        res_mant = res_mant << 16;
                        res_exp  = res_exp - 5'b10000;
                    end else if (res_mant[6]) begin
                        res_mant = res_mant << 17;
                        res_exp  = res_exp - 5'b10001;
                    end else if (res_mant[5]) begin
                        res_mant = res_mant << 18;
                        res_exp  = res_exp - 5'b10010;
                    end else if (res_mant[4]) begin
                        res_mant = res_mant << 19;
                        res_exp  = res_exp - 5'b10011;
                    end else if (res_mant[3]) begin
                        res_mant = res_mant << 20;
                        res_exp  = res_exp - 5'b10100;
                    end else if (res_mant[2]) begin
                        res_mant = res_mant << 21;
                        res_exp  = res_exp - 5'b10101;
                    end else if (res_mant[1]) begin
                        res_mant = res_mant << 22;
                        res_exp  = res_exp - 5'b10110;
                    end else if (res_mant[0]) begin
                        res_mant = res_mant << 23;
                        res_exp  = res_exp - 5'b10111;
                    end
                    else begin
                        res_mant = 0;
                        res_exp  = res_exp - 5'b11000;
                    end
                end
            end
        end
    end

endmodule

//************************************ Float32 Multiplier ************************************//

module fp32_mul(
        input [31:0] a_operand,
        input [31:0] b_operand,
        output [31:0] result
        );

wire sign,product_round,normalised,zero,Exception,Overflow,Underflow;
wire [8:0] exponent,sum_exponent;
wire [22:0] product_mantissa;
wire [23:0] operand_a,operand_b;
wire [47:0] product,product_normalised; //48 Bits


assign sign = a_operand[31] ^ b_operand[31];

//Exception flag sets 1 if either one of the exponent is 255.
assign Exception = (&a_operand[30:23]) | (&b_operand[30:23]);

//Assigining significand values according to Hidden Bit.
//If exponent is equal to zero then hidden bit will be 0 for that respective significand else it will be 1

assign operand_a = (|a_operand[30:23]) ? {1'b1,a_operand[22:0]} : {1'b0,a_operand[22:0]};

assign operand_b = (|b_operand[30:23]) ? {1'b1,b_operand[22:0]} : {1'b0,b_operand[22:0]};

//assign product = operand_a * operand_b;			//Calculating Product

mul_24bit mul24(.a(operand_a),.b(operand_b),.res(product));

//assign product_round = |product_normalised[22:0];  //Ending 22 bits are OR'ed for rounding operation.
assign product_round = |product[22:0];  //Ending 22 bits are OR'ed for rounding operation.

assign normalised = product[47] ? 1'b1 : 1'b0;	

assign product_normalised = normalised ? product : product << 1;	//Assigning Normalised value based on 48th bit

//Final Manitssa.
assign product_mantissa = product_normalised[46:24] + (product_normalised[23] & product_round); 

assign zero = Exception ? 1'b0 : (product_mantissa == 23'd0) ? 1'b1 : 1'b0;

assign sum_exponent = a_operand[30:23] + b_operand[30:23];

assign exponent = sum_exponent - 8'd127 + normalised;

assign Overflow = ((exponent[8] & !exponent[7]) & !zero) ; //If overall exponent is greater than 255 then Overflow condition.
//Exception Case when exponent reaches its maximu value that is 384.

//If sum of both exponents is less than 127 then Underflow condition.
assign Underflow = ((exponent[8] & exponent[7]) & !zero) ? 1'b1 : 1'b0; 

assign result = Exception ? 32'd0 : Overflow ? {sign,8'hFF,23'd0} : Underflow ? {sign,31'd0} : {sign,exponent[7:0],product_mantissa};


endmodule


/************************* 24 bit multiplier ****************************/

module mul_24bit#(parameter bitwidth=24,approx=0)(
    input [bitwidth-1:0]a,b,
    output [2*bitwidth-1:0]res
    ); 
    
 /************** Partial Product Generation **************/
    genvar i,j,k; 
    wire pp1[bitwidth-1:0][bitwidth-1:0]; 
    wire [bitwidth-1:0]tmp[bitwidth-1:0]; 
    
    generate
    if (approx>=bitwidth-1) begin
        for (i=bitwidth-1;i>=0;i=i-1) begin
            if (approx-i<=bitwidth-1)begin
                assign tmp[i]={a[bitwidth-1:approx-i],{(approx-i){1'b0}}}; 
                for (j=bitwidth-1;j>=approx-i;j=j-1) begin
                    assign pp1[i][j]=tmp[i][j]&b[i];          
                end
            end
        end
    end
    else begin
        for(i=bitwidth-1;i>=0;i=i-1) begin
            if (i>=approx) begin 
                assign tmp[i]=a[bitwidth-1:0]; 
            end
            else begin
                assign tmp[i]={a[bitwidth-1:approx-i],{(approx-i){1'b0}}}; 
            end
            if (i>=approx) begin
                for (j=bitwidth-1;j>=0;j=j-1) begin
                    assign pp1[i][j]=tmp[i][j]&b[i];          
                end
            end
            else begin
                for (j=bitwidth-1;j>=approx-i;j=j-1) begin
                    assign pp1[i][j]=tmp[i][j]&b[i];          
                end
            end
            end
        end
        
    endgenerate
    


/******************** Reduction Stage 1 ********************/
wire pp2[11:0][46:0];
wire cin1[71:0];

//Column 0
assign pp2[0][0]=pp1[0][0];

//Column 1
assign pp2[0][1]=pp1[0][1];
assign pp2[1][1]=pp1[1][0];

//Column 2
assign pp2[0][2]=pp1[0][2];
assign pp2[1][2]=pp1[1][1];
assign pp2[2][2]=pp1[2][0];

//Column 3
assign pp2[0][3]=pp1[0][3];
assign pp2[1][3]=pp1[1][2];
assign pp2[2][3]=pp1[2][1];
assign pp2[3][3]=pp1[3][0];

//Column 4
assign pp2[0][4]=pp1[0][4];
assign pp2[1][4]=pp1[1][3];
assign pp2[2][4]=pp1[2][2];
assign pp2[3][4]=pp1[3][1];
assign pp2[4][4]=pp1[4][0];

//Column 5
assign pp2[0][5]=pp1[0][5];
assign pp2[1][5]=pp1[1][4];
assign pp2[2][5]=pp1[2][3];
assign pp2[3][5]=pp1[3][2];
assign pp2[4][5]=pp1[4][1];
assign pp2[5][5]=pp1[5][0];

//Column 6
assign pp2[0][6]=pp1[0][6];
assign pp2[1][6]=pp1[1][5];
assign pp2[2][6]=pp1[2][4];
assign pp2[3][6]=pp1[3][3];
assign pp2[4][6]=pp1[4][2];
assign pp2[5][6]=pp1[5][1];
assign pp2[6][6]=pp1[6][0];

//Column 7
assign pp2[0][7]=pp1[0][7];
assign pp2[1][7]=pp1[1][6];
assign pp2[2][7]=pp1[2][5];
assign pp2[3][7]=pp1[3][4];
assign pp2[4][7]=pp1[4][3];
assign pp2[5][7]=pp1[5][2];
assign pp2[6][7]=pp1[6][1];
assign pp2[7][7]=pp1[7][0];

//Column 8
assign pp2[0][8]=pp1[0][8];
assign pp2[1][8]=pp1[1][7];
assign pp2[2][8]=pp1[2][6];
assign pp2[3][8]=pp1[3][5];
assign pp2[4][8]=pp1[4][4];
assign pp2[5][8]=pp1[5][3];
assign pp2[6][8]=pp1[6][2];
assign pp2[7][8]=pp1[7][1];
assign pp2[8][8]=pp1[8][0];

//Column 9
assign pp2[0][9]=pp1[0][9];
assign pp2[1][9]=pp1[1][8];
assign pp2[2][9]=pp1[2][7];
assign pp2[3][9]=pp1[3][6];
assign pp2[4][9]=pp1[4][5];
assign pp2[5][9]=pp1[5][4];
assign pp2[6][9]=pp1[6][3];
assign pp2[7][9]=pp1[7][2];
assign pp2[8][9]=pp1[8][1];
assign pp2[9][9]=pp1[9][0];

//Column 10
assign pp2[0][10]=pp1[0][10];
assign pp2[1][10]=pp1[1][9];
assign pp2[2][10]=pp1[2][8];
assign pp2[3][10]=pp1[3][7];
assign pp2[4][10]=pp1[4][6];
assign pp2[5][10]=pp1[5][5];
assign pp2[6][10]=pp1[6][4];
assign pp2[7][10]=pp1[7][3];
assign pp2[8][10]=pp1[8][2];
assign pp2[9][10]=pp1[9][1];
assign pp2[10][10]=pp1[10][0];

//Column 11
assign pp2[0][11]=pp1[0][11];
assign pp2[1][11]=pp1[1][10];
assign pp2[2][11]=pp1[2][9];
assign pp2[3][11]=pp1[3][8];
assign pp2[4][11]=pp1[4][7];
assign pp2[5][11]=pp1[5][6];
assign pp2[6][11]=pp1[6][5];
assign pp2[7][11]=pp1[7][4];
assign pp2[8][11]=pp1[8][3];
assign pp2[9][11]=pp1[9][2];
assign pp2[10][11]=pp1[10][1];
assign pp2[11][11]=pp1[11][0];

//Column 12
exact_22 s1_12(.a(pp1[0][12]),.b(pp1[1][11]),.sum(pp2[0][12]),.carry(pp2[0][13]));
assign pp2[1][12]=pp1[2][10];
assign pp2[2][12]=pp1[3][9];
assign pp2[3][12]=pp1[4][8];
assign pp2[4][12]=pp1[5][7];
assign pp2[5][12]=pp1[6][6];
assign pp2[6][12]=pp1[7][5];
assign pp2[7][12]=pp1[8][4];
assign pp2[8][12]=pp1[9][3];
assign pp2[9][12]=pp1[10][2];
assign pp2[10][12]=pp1[11][1];
assign pp2[11][12]=pp1[12][0];

//Column 13
exact_42 s1_13(.a(pp1[0][13]),.b(pp1[1][12]),.c(pp1[2][11]),.d(pp1[3][10]),.cin(1'b0),.sum(pp2[1][13]),.carry(pp2[0][14]),.cout(cin1[0]));
assign pp2[2][13]=pp1[4][9];
assign pp2[3][13]=pp1[5][8];
assign pp2[4][13]=pp1[6][7];
assign pp2[5][13]=pp1[7][6];
assign pp2[6][13]=pp1[8][5];
assign pp2[7][13]=pp1[9][4];
assign pp2[8][13]=pp1[10][3];
assign pp2[9][13]=pp1[11][2];
assign pp2[10][13]=pp1[12][1];
assign pp2[11][13]=pp1[13][0];

//Column 14
exact_42 s1_141(.a(pp1[0][14]),.b(pp1[1][13]),.c(pp1[2][12]),.d(pp1[3][11]),.cin(cin1[0]),.sum(pp2[1][14]),.carry(pp2[0][15]),.cout(cin1[1]));
exact_22 s1_142(.a(pp1[4][10]),.b(pp1[5][9]),.sum(pp2[2][14]),.carry(pp2[1][15]));
assign pp2[3][14]=pp1[6][8];
assign pp2[4][14]=pp1[7][7];
assign pp2[5][14]=pp1[8][6];
assign pp2[6][14]=pp1[9][5];
assign pp2[7][14]=pp1[10][4];
assign pp2[8][14]=pp1[11][3];
assign pp2[9][14]=pp1[12][2];
assign pp2[10][14]=pp1[13][1];
assign pp2[11][14]=pp1[14][0];

//Column 15
exact_42 s1_151(.a(pp1[0][15]),.b(pp1[1][14]),.c(pp1[2][13]),.d(pp1[3][12]),.cin(cin1[1]),.sum(pp2[2][15]),.carry(pp2[0][16]),.cout(cin1[2]));
exact_42 s1_152(.a(pp1[4][11]),.b(pp1[5][10]),.c(pp1[6][9]),.d(pp1[7][8]),.cin(1'b0),.sum(pp2[3][15]),.carry(pp2[1][16]),.cout(cin1[3]));
assign pp2[4][15]=pp1[8][7];
assign pp2[5][15]=pp1[9][6];
assign pp2[6][15]=pp1[10][5];
assign pp2[7][15]=pp1[11][4];
assign pp2[8][15]=pp1[12][3];
assign pp2[9][15]=pp1[13][2];
assign pp2[10][15]=pp1[14][1];
assign pp2[11][15]=pp1[15][0];

//Column 16
exact_42 s1_161(.a(pp1[0][16]),.b(pp1[1][15]),.c(pp1[2][14]),.d(pp1[3][13]),.cin(cin1[2]),.sum(pp2[2][16]),.carry(pp2[0][17]),.cout(cin1[4]));
exact_42 s1_162(.a(pp1[4][12]),.b(pp1[5][11]),.c(pp1[6][10]),.d(pp1[7][9]),.cin(cin1[3]),.sum(pp2[3][16]),.carry(pp2[1][17]),.cout(cin1[5]));
exact_22 s1_163(.a(pp1[8][8]),.b(pp1[9][7]),.sum(pp2[4][16]),.carry(pp2[2][17]));
assign pp2[5][16]=pp1[10][6];
assign pp2[6][16]=pp1[11][5];
assign pp2[7][16]=pp1[12][4];
assign pp2[8][16]=pp1[13][3];
assign pp2[9][16]=pp1[14][2];
assign pp2[10][16]=pp1[15][1];
assign pp2[11][16]=pp1[16][0];

//Column 17
exact_42 s1_171(.a(pp1[0][17]),.b(pp1[1][16]),.c(pp1[2][15]),.d(pp1[3][14]),.cin(cin1[4]),.sum(pp2[3][17]),.carry(pp2[0][18]),.cout(cin1[6]));
exact_42 s1_172(.a(pp1[4][13]),.b(pp1[5][12]),.c(pp1[6][11]),.d(pp1[7][10]),.cin(cin1[5]),.sum(pp2[4][17]),.carry(pp2[1][18]),.cout(cin1[7]));
exact_42 s1_173(.a(pp1[8][9]),.b(pp1[9][8]),.c(pp1[10][7]),.d(pp1[11][6]),.cin(1'b0),.sum(pp2[5][17]),.carry(pp2[2][18]),.cout(cin1[8]));
assign pp2[6][17]=pp1[12][5];
assign pp2[7][17]=pp1[13][4];
assign pp2[8][17]=pp1[14][3];
assign pp2[9][17]=pp1[15][2];
assign pp2[10][17]=pp1[16][1];
assign pp2[11][17]=pp1[17][0];

//Column 18
exact_42 s1_181(.a(pp1[0][18]),.b(pp1[1][17]),.c(pp1[2][16]),.d(pp1[3][15]),.cin(cin1[6]),.sum(pp2[3][18]),.carry(pp2[0][19]),.cout(cin1[9]));
exact_42 s1_182(.a(pp1[4][14]),.b(pp1[5][13]),.c(pp1[6][12]),.d(pp1[7][11]),.cin(cin1[7]),.sum(pp2[4][18]),.carry(pp2[1][19]),.cout(cin1[10]));
exact_42 s1_183(.a(pp1[8][10]),.b(pp1[9][9]),.c(pp1[10][8]),.d(pp1[11][7]),.cin(cin1[8]),.sum(pp2[5][18]),.carry(pp2[2][19]),.cout(cin1[11]));
exact_22 s1_184(.a(pp1[12][6]),.b(pp1[13][5]),.sum(pp2[6][18]),.carry(pp2[3][19]));
assign pp2[7][18]=pp1[14][4];
assign pp2[8][18]=pp1[15][3];
assign pp2[9][18]=pp1[16][2];
assign pp2[10][18]=pp1[17][1];
assign pp2[11][18]=pp1[18][0];

//Column 19
exact_42 s1_191(.a(pp1[0][19]),.b(pp1[1][18]),.c(pp1[2][17]),.d(pp1[3][16]),.cin(cin1[9]),.sum(pp2[4][19]),.carry(pp2[0][20]),.cout(cin1[12]));
exact_42 s1_192(.a(pp1[4][15]),.b(pp1[5][14]),.c(pp1[6][13]),.d(pp1[7][12]),.cin(cin1[10]),.sum(pp2[5][19]),.carry(pp2[1][20]),.cout(cin1[13]));
exact_42 s1_193(.a(pp1[8][11]),.b(pp1[9][10]),.c(pp1[10][9]),.d(pp1[11][8]),.cin(cin1[11]),.sum(pp2[6][19]),.carry(pp2[2][20]),.cout(cin1[14]));
exact_42 s1_194(.a(pp1[12][7]),.b(pp1[13][6]),.c(pp1[14][5]),.d(pp1[15][4]),.cin(1'b0),.sum(pp2[7][19]),.carry(pp2[3][20]),.cout(cin1[15]));
assign pp2[8][19]=pp1[16][3];
assign pp2[9][19]=pp1[17][2];
assign pp2[10][19]=pp1[18][1];
assign pp2[11][19]=pp1[19][0];

//Column 20
exact_42 s1_201(.a(pp1[0][20]),.b(pp1[1][19]),.c(pp1[2][18]),.d(pp1[3][17]),.cin(cin1[12]),.sum(pp2[4][20]),.carry(pp2[0][21]),.cout(cin1[16]));
exact_42 s1_202(.a(pp1[4][16]),.b(pp1[5][15]),.c(pp1[6][14]),.d(pp1[7][13]),.cin(cin1[13]),.sum(pp2[5][20]),.carry(pp2[1][21]),.cout(cin1[17]));
exact_42 s1_203(.a(pp1[8][12]),.b(pp1[9][11]),.c(pp1[10][10]),.d(pp1[11][9]),.cin(cin1[14]),.sum(pp2[6][20]),.carry(pp2[2][21]),.cout(cin1[18]));
exact_42 s1_204(.a(pp1[12][8]),.b(pp1[13][7]),.c(pp1[14][6]),.d(pp1[15][5]),.cin(cin1[15]),.sum(pp2[7][20]),.carry(pp2[3][21]),.cout(cin1[19]));
exact_22 s1_205(.a(pp1[16][4]),.b(pp1[17][3]),.sum(pp2[8][20]),.carry(pp2[4][21]));
assign pp2[9][20]=pp1[18][2];
assign pp2[10][20]=pp1[19][1];
assign pp2[11][20]=pp1[20][0];

//Column 21
exact_42 s1_211(.a(pp1[0][21]),.b(pp1[1][20]),.c(pp1[2][19]),.d(pp1[3][18]),.cin(cin1[16]),.sum(pp2[5][21]),.carry(pp2[0][22]),.cout(cin1[20]));
exact_42 s1_212(.a(pp1[4][17]),.b(pp1[5][16]),.c(pp1[6][15]),.d(pp1[7][14]),.cin(cin1[17]),.sum(pp2[6][21]),.carry(pp2[1][22]),.cout(cin1[21]));
exact_42 s1_213(.a(pp1[8][13]),.b(pp1[9][12]),.c(pp1[10][11]),.d(pp1[11][10]),.cin(cin1[18]),.sum(pp2[7][21]),.carry(pp2[2][22]),.cout(cin1[22]));
exact_42 s1_214(.a(pp1[12][9]),.b(pp1[13][8]),.c(pp1[14][7]),.d(pp1[15][6]),.cin(cin1[19]),.sum(pp2[8][21]),.carry(pp2[3][22]),.cout(cin1[23]));
exact_42 s1_215(.a(pp1[16][5]),.b(pp1[17][4]),.c(pp1[18][3]),.d(pp1[19][2]),.cin(1'b0),.sum(pp2[9][21]),.carry(pp2[4][22]),.cout(cin1[24]));
assign pp2[10][21]=pp1[20][1];
assign pp2[11][21]=pp1[21][0];

//Column 22
exact_42 s1_221(.a(pp1[0][22]),.b(pp1[1][21]),.c(pp1[2][20]),.d(pp1[3][19]),.cin(cin1[20]),.sum(pp2[5][22]),.carry(pp2[0][23]),.cout(cin1[25]));
exact_42 s1_222(.a(pp1[4][18]),.b(pp1[5][17]),.c(pp1[6][16]),.d(pp1[7][15]),.cin(cin1[21]),.sum(pp2[6][22]),.carry(pp2[1][23]),.cout(cin1[26]));
exact_42 s1_223(.a(pp1[8][14]),.b(pp1[9][13]),.c(pp1[10][12]),.d(pp1[11][11]),.cin(cin1[22]),.sum(pp2[7][22]),.carry(pp2[2][23]),.cout(cin1[27]));
exact_42 s1_224(.a(pp1[12][10]),.b(pp1[13][9]),.c(pp1[14][8]),.d(pp1[15][7]),.cin(cin1[23]),.sum(pp2[8][22]),.carry(pp2[3][23]),.cout(cin1[28]));
exact_42 s1_225(.a(pp1[16][6]),.b(pp1[17][5]),.c(pp1[18][4]),.d(pp1[19][3]),.cin(cin1[24]),.sum(pp2[9][22]),.carry(pp2[4][23]),.cout(cin1[29]));
exact_22 s1_226(.a(pp1[20][2]),.b(pp1[21][1]),.sum(pp2[10][22]),.carry(pp2[5][23]));
assign pp2[11][22]=pp1[22][0];

//Column 23
exact_42 s1_231(.a(pp1[0][23]),.b(pp1[1][22]),.c(pp1[2][21]),.d(pp1[3][20]),.cin(cin1[25]),.sum(pp2[6][23]),.carry(pp2[0][24]),.cout(cin1[30]));
exact_42 s1_232(.a(pp1[4][19]),.b(pp1[5][18]),.c(pp1[6][17]),.d(pp1[7][16]),.cin(cin1[26]),.sum(pp2[7][23]),.carry(pp2[1][24]),.cout(cin1[31]));
exact_42 s1_233(.a(pp1[8][15]),.b(pp1[9][14]),.c(pp1[10][13]),.d(pp1[11][12]),.cin(cin1[27]),.sum(pp2[8][23]),.carry(pp2[2][24]),.cout(cin1[32]));
exact_42 s1_234(.a(pp1[12][11]),.b(pp1[13][10]),.c(pp1[14][9]),.d(pp1[15][8]),.cin(cin1[28]),.sum(pp2[9][23]),.carry(pp2[3][24]),.cout(cin1[33]));
exact_42 s1_235(.a(pp1[16][7]),.b(pp1[17][6]),.c(pp1[18][5]),.d(pp1[19][4]),.cin(cin1[29]),.sum(pp2[10][23]),.carry(pp2[4][24]),.cout(cin1[34]));
exact_42 s1_236(.a(pp1[20][3]),.b(pp1[21][2]),.c(pp1[22][1]),.d(pp1[23][0]),.cin(1'b0),.sum(pp2[11][23]),.carry(pp2[5][24]),.cout(cin1[35]));

//Column 24
exact_42 s1_241(.a(pp1[1][23]),.b(pp1[2][22]),.c(pp1[3][21]),.d(pp1[4][20]),.cin(cin1[30]),.sum(pp2[6][24]),.carry(pp2[0][25]),.cout(cin1[36]));
exact_42 s1_242(.a(pp1[5][19]),.b(pp1[6][18]),.c(pp1[7][17]),.d(pp1[8][16]),.cin(cin1[31]),.sum(pp2[7][24]),.carry(pp2[1][25]),.cout(cin1[37]));
exact_42 s1_243(.a(pp1[9][15]),.b(pp1[10][14]),.c(pp1[11][13]),.d(pp1[12][12]),.cin(cin1[32]),.sum(pp2[8][24]),.carry(pp2[2][25]),.cout(cin1[38]));
exact_42 s1_244(.a(pp1[13][11]),.b(pp1[14][10]),.c(pp1[15][9]),.d(pp1[16][8]),.cin(cin1[33]),.sum(pp2[9][24]),.carry(pp2[3][25]),.cout(cin1[39]));
exact_42 s1_245(.a(pp1[17][7]),.b(pp1[18][6]),.c(pp1[19][5]),.d(pp1[20][4]),.cin(cin1[34]),.sum(pp2[10][24]),.carry(pp2[4][25]),.cout(cin1[40]));
exact_42 s1_246(.a(pp1[21][3]),.b(pp1[22][2]),.c(pp1[23][1]),.d(cin1[35]),.cin(1'b0),.sum(pp2[11][24]),.carry(pp2[5][25]),.cout(cin1[41]));

//Column 25
exact_42 s1_251(.a(pp1[2][23]),.b(pp1[3][22]),.c(pp1[4][21]),.d(pp1[5][20]),.cin(cin1[36]),.sum(pp2[6][25]),.carry(pp2[0][26]),.cout(cin1[42]));
exact_42 s1_252(.a(pp1[6][19]),.b(pp1[7][18]),.c(pp1[8][17]),.d(pp1[9][16]),.cin(cin1[37]),.sum(pp2[7][25]),.carry(pp2[1][26]),.cout(cin1[43]));
exact_42 s1_253(.a(pp1[10][15]),.b(pp1[11][14]),.c(pp1[12][13]),.d(pp1[13][12]),.cin(cin1[38]),.sum(pp2[8][25]),.carry(pp2[2][26]),.cout(cin1[44]));
exact_42 s1_254(.a(pp1[14][11]),.b(pp1[15][10]),.c(pp1[16][9]),.d(pp1[17][8]),.cin(cin1[39]),.sum(pp2[9][25]),.carry(pp2[3][26]),.cout(cin1[45]));
exact_42 s1_255(.a(pp1[18][7]),.b(pp1[19][6]),.c(pp1[20][5]),.d(pp1[21][4]),.cin(cin1[40]),.sum(pp2[10][25]),.carry(pp2[4][26]),.cout(cin1[46]));
exact_32 s1_256(.a(pp1[22][3]),.b(pp1[23][2]),.c(cin1[41]),.sum(pp2[11][25]),.carry(pp2[5][26]));

//Column 26
exact_42 s1_261(.a(pp1[3][23]),.b(pp1[4][22]),.c(pp1[5][21]),.d(pp1[6][20]),.cin(cin1[42]),.sum(pp2[6][26]),.carry(pp2[0][27]),.cout(cin1[47]));
exact_42 s1_262(.a(pp1[7][19]),.b(pp1[8][18]),.c(pp1[9][17]),.d(pp1[10][16]),.cin(cin1[43]),.sum(pp2[7][26]),.carry(pp2[1][27]),.cout(cin1[48]));
exact_42 s1_263(.a(pp1[11][15]),.b(pp1[12][14]),.c(pp1[13][13]),.d(pp1[14][12]),.cin(cin1[44]),.sum(pp2[8][26]),.carry(pp2[2][27]),.cout(cin1[49]));
exact_42 s1_264(.a(pp1[15][11]),.b(pp1[16][10]),.c(pp1[17][9]),.d(pp1[18][8]),.cin(cin1[45]),.sum(pp2[9][26]),.carry(pp2[3][27]),.cout(cin1[50]));
exact_42 s1_265(.a(pp1[19][7]),.b(pp1[20][6]),.c(pp1[21][5]),.d(pp1[22][4]),.cin(cin1[46]),.sum(pp2[10][26]),.carry(pp2[4][27]),.cout(cin1[51]));
assign pp2[11][26]=pp1[23][3];

//Column 27
exact_42 s1_271(.a(pp1[4][23]),.b(pp1[5][22]),.c(pp1[6][21]),.d(pp1[7][20]),.cin(cin1[47]),.sum(pp2[5][27]),.carry(pp2[0][28]),.cout(cin1[52]));
exact_42 s1_272(.a(pp1[8][19]),.b(pp1[9][18]),.c(pp1[10][17]),.d(pp1[11][16]),.cin(cin1[48]),.sum(pp2[6][27]),.carry(pp2[1][28]),.cout(cin1[53]));
exact_42 s1_273(.a(pp1[12][15]),.b(pp1[13][14]),.c(pp1[14][13]),.d(pp1[15][12]),.cin(cin1[49]),.sum(pp2[7][27]),.carry(pp2[2][28]),.cout(cin1[54]));
exact_42 s1_274(.a(pp1[16][11]),.b(pp1[17][10]),.c(pp1[18][9]),.d(pp1[19][8]),.cin(cin1[50]),.sum(pp2[8][27]),.carry(pp2[3][28]),.cout(cin1[55]));
exact_32 s1_275(.a(pp1[20][7]),.b(pp1[21][6]),.c(cin1[51]),.sum(pp2[9][27]),.carry(pp2[4][28]));
assign pp2[10][27]=pp1[22][5];
assign pp2[11][27]=pp1[23][4];

//Column 28
exact_42 s1_281(.a(pp1[5][23]),.b(pp1[6][22]),.c(pp1[7][21]),.d(pp1[8][20]),.cin(cin1[52]),.sum(pp2[5][28]),.carry(pp2[0][29]),.cout(cin1[56]));
exact_42 s1_282(.a(pp1[9][19]),.b(pp1[10][18]),.c(pp1[11][17]),.d(pp1[12][16]),.cin(cin1[53]),.sum(pp2[6][28]),.carry(pp2[1][29]),.cout(cin1[57]));
exact_42 s1_283(.a(pp1[13][15]),.b(pp1[14][14]),.c(pp1[15][13]),.d(pp1[16][12]),.cin(cin1[54]),.sum(pp2[7][28]),.carry(pp2[2][29]),.cout(cin1[58]));
exact_42 s1_284(.a(pp1[17][11]),.b(pp1[18][10]),.c(pp1[19][9]),.d(pp1[20][8]),.cin(cin1[55]),.sum(pp2[8][28]),.carry(pp2[3][29]),.cout(cin1[59]));
assign pp2[9][28]=pp1[21][7];
assign pp2[10][28]=pp1[22][6];
assign pp2[11][28]=pp1[23][5];

//Column 29
exact_42 s1_291(.a(pp1[6][23]),.b(pp1[7][22]),.c(pp1[8][21]),.d(pp1[9][20]),.cin(cin1[56]),.sum(pp2[4][29]),.carry(pp2[0][30]),.cout(cin1[60]));
exact_42 s1_292(.a(pp1[10][19]),.b(pp1[11][18]),.c(pp1[12][17]),.d(pp1[13][16]),.cin(cin1[57]),.sum(pp2[5][29]),.carry(pp2[1][30]),.cout(cin1[61]));
exact_42 s1_293(.a(pp1[14][15]),.b(pp1[15][14]),.c(pp1[16][13]),.d(pp1[17][12]),.cin(cin1[58]),.sum(pp2[6][29]),.carry(pp2[2][30]),.cout(cin1[62]));
exact_32 s1_294(.a(pp1[18][11]),.b(pp1[19][10]),.c(cin1[59]),.sum(pp2[7][29]),.carry(pp2[3][30]));
assign pp2[8][29]=pp1[20][9];
assign pp2[9][29]=pp1[21][8];
assign pp2[10][29]=pp1[22][7];
assign pp2[11][29]=pp1[23][6];

//Column 30
exact_42 s1_301(.a(pp1[7][23]),.b(pp1[8][22]),.c(pp1[9][21]),.d(pp1[10][20]),.cin(cin1[60]),.sum(pp2[4][30]),.carry(pp2[0][31]),.cout(cin1[63]));
exact_42 s1_302(.a(pp1[11][19]),.b(pp1[12][18]),.c(pp1[13][17]),.d(pp1[14][16]),.cin(cin1[61]),.sum(pp2[5][30]),.carry(pp2[1][31]),.cout(cin1[64]));
exact_42 s1_303(.a(pp1[15][15]),.b(pp1[16][14]),.c(pp1[17][13]),.d(pp1[18][12]),.cin(cin1[62]),.sum(pp2[6][30]),.carry(pp2[2][31]),.cout(cin1[65]));
assign pp2[7][30]=pp1[19][11];
assign pp2[8][30]=pp1[20][10];
assign pp2[9][30]=pp1[21][9];
assign pp2[10][30]=pp1[22][8];
assign pp2[11][30]=pp1[23][7];

//Column 31
exact_42 s1_311(.a(pp1[8][23]),.b(pp1[9][22]),.c(pp1[10][21]),.d(pp1[11][20]),.cin(cin1[63]),.sum(pp2[3][31]),.carry(pp2[0][32]),.cout(cin1[66]));
exact_42 s1_312(.a(pp1[12][19]),.b(pp1[13][18]),.c(pp1[14][17]),.d(pp1[15][16]),.cin(cin1[64]),.sum(pp2[4][31]),.carry(pp2[1][32]),.cout(cin1[67]));
exact_32 s1_313(.a(pp1[16][15]),.b(pp1[17][14]),.c(cin1[65]),.sum(pp2[5][31]),.carry(pp2[2][32]));
assign pp2[6][31]=pp1[18][13];
assign pp2[7][31]=pp1[19][12];
assign pp2[8][31]=pp1[20][11];
assign pp2[9][31]=pp1[21][10];
assign pp2[10][31]=pp1[22][9];
assign pp2[11][31]=pp1[23][8];

//Column 32
exact_42 s1_321(.a(pp1[9][23]),.b(pp1[10][22]),.c(pp1[11][21]),.d(pp1[12][20]),.cin(cin1[66]),.sum(pp2[3][32]),.carry(pp2[0][33]),.cout(cin1[68]));
exact_42 s1_322(.a(pp1[13][19]),.b(pp1[14][18]),.c(pp1[15][17]),.d(pp1[16][16]),.cin(cin1[67]),.sum(pp2[4][32]),.carry(pp2[1][33]),.cout(cin1[69]));
assign pp2[5][32]=pp1[17][15];
assign pp2[6][32]=pp1[18][14];
assign pp2[7][32]=pp1[19][13];
assign pp2[8][32]=pp1[20][12];
assign pp2[9][32]=pp1[21][11];
assign pp2[10][32]=pp1[22][10];
assign pp2[11][32]=pp1[23][9];

//Column 33
exact_42 s1_331(.a(pp1[10][23]),.b(pp1[11][22]),.c(pp1[12][21]),.d(pp1[13][20]),.cin(cin1[68]),.sum(pp2[2][33]),.carry(pp2[0][34]),.cout(cin1[70]));
exact_32 s1_332(.a(pp1[14][19]),.b(pp1[15][18]),.c(cin1[69]),.sum(pp2[3][33]),.carry(pp2[1][34]));
assign pp2[4][33]=pp1[16][17];
assign pp2[5][33]=pp1[17][16];
assign pp2[6][33]=pp1[18][15];
assign pp2[7][33]=pp1[19][14];
assign pp2[8][33]=pp1[20][13];
assign pp2[9][33]=pp1[21][12];
assign pp2[10][33]=pp1[22][11];
assign pp2[11][33]=pp1[23][10];

//Column 34
exact_42 s1_34(.a(pp1[11][23]),.b(pp1[12][22]),.c(pp1[13][21]),.d(pp1[14][20]),.cin(cin1[70]),.sum(pp2[2][34]),.carry(pp2[0][35]),.cout(cin1[71]));
assign pp2[3][34]=pp1[15][19];
assign pp2[4][34]=pp1[16][18];
assign pp2[5][34]=pp1[17][17];
assign pp2[6][34]=pp1[18][16];
assign pp2[7][34]=pp1[19][15];
assign pp2[8][34]=pp1[20][14];
assign pp2[9][34]=pp1[21][13];
assign pp2[10][34]=pp1[22][12];
assign pp2[11][34]=pp1[23][11];

//Column 35
exact_32 s1_35(.a(pp1[12][23]),.b(pp1[13][22]),.c(cin1[71]),.sum(pp2[1][35]),.carry(pp2[0][36]));
assign pp2[2][35]=pp1[14][21];
assign pp2[3][35]=pp1[15][20];
assign pp2[4][35]=pp1[16][19];
assign pp2[5][35]=pp1[17][18];
assign pp2[6][35]=pp1[18][17];
assign pp2[7][35]=pp1[19][16];
assign pp2[8][35]=pp1[20][15];
assign pp2[9][35]=pp1[21][14];
assign pp2[10][35]=pp1[22][13];
assign pp2[11][35]=pp1[23][12];

//Column 36
assign pp2[1][36]=pp1[13][23];
assign pp2[2][36]=pp1[14][22];
assign pp2[3][36]=pp1[15][21];
assign pp2[4][36]=pp1[16][20];
assign pp2[5][36]=pp1[17][19];
assign pp2[6][36]=pp1[18][18];
assign pp2[7][36]=pp1[19][17];
assign pp2[8][36]=pp1[20][16];
assign pp2[9][36]=pp1[21][15];
assign pp2[10][36]=pp1[22][14];
assign pp2[11][36]=pp1[23][13];

//Column 37
assign pp2[0][37]=pp1[14][23];
assign pp2[1][37]=pp1[15][22];
assign pp2[2][37]=pp1[16][21];
assign pp2[3][37]=pp1[17][20];
assign pp2[4][37]=pp1[18][19];
assign pp2[5][37]=pp1[19][18];
assign pp2[6][37]=pp1[20][17];
assign pp2[7][37]=pp1[21][16];
assign pp2[8][37]=pp1[22][15];
assign pp2[9][37]=pp1[23][14];

//Column 38
assign pp2[0][38]=pp1[15][23];
assign pp2[1][38]=pp1[16][22];
assign pp2[2][38]=pp1[17][21];
assign pp2[3][38]=pp1[18][20];
assign pp2[4][38]=pp1[19][19];
assign pp2[5][38]=pp1[20][18];
assign pp2[6][38]=pp1[21][17];
assign pp2[7][38]=pp1[22][16];
assign pp2[8][38]=pp1[23][15];

//Column 39
assign pp2[0][39]=pp1[16][23];
assign pp2[1][39]=pp1[17][22];
assign pp2[2][39]=pp1[18][21];
assign pp2[3][39]=pp1[19][20];
assign pp2[4][39]=pp1[20][19];
assign pp2[5][39]=pp1[21][18];
assign pp2[6][39]=pp1[22][17];
assign pp2[7][39]=pp1[23][16];

//Column 40
assign pp2[0][40]=pp1[17][23];
assign pp2[1][40]=pp1[18][22];
assign pp2[2][40]=pp1[19][21];
assign pp2[3][40]=pp1[20][20];
assign pp2[4][40]=pp1[21][19];
assign pp2[5][40]=pp1[22][18];
assign pp2[6][40]=pp1[23][17];

//Column 41
assign pp2[0][41]=pp1[18][23];
assign pp2[1][41]=pp1[19][22];
assign pp2[2][41]=pp1[20][21];
assign pp2[3][41]=pp1[21][20];
assign pp2[4][41]=pp1[22][19];
assign pp2[5][41]=pp1[23][18];

//Column 42
assign pp2[0][42]=pp1[19][23];
assign pp2[1][42]=pp1[20][22];
assign pp2[2][42]=pp1[21][21];
assign pp2[3][42]=pp1[22][20];
assign pp2[4][42]=pp1[23][19];

//Column 43
assign pp2[0][43]=pp1[20][23];
assign pp2[1][43]=pp1[21][22];
assign pp2[2][43]=pp1[22][21];
assign pp2[3][43]=pp1[23][20];

//Column 44
assign pp2[0][44]=pp1[21][23];
assign pp2[1][44]=pp1[22][22];
assign pp2[2][44]=pp1[23][21];

//Column 45
assign pp2[0][45]=pp1[22][23];
assign pp2[1][45]=pp1[23][22];

//Column 46
assign pp2[0][46]=pp1[23][23];



/******************** Reduction Stage 2 ********************/
wire pp3[5:0][46:0];
wire cin2[89:0];

//Column 0
assign pp3[0][0]=pp2[0][0];

//Column 1
assign pp3[0][1]=pp2[0][1];
assign pp3[1][1]=pp2[1][1];

//Column 2
assign pp3[0][2]=pp2[0][2];
assign pp3[1][2]=pp2[1][2];
assign pp3[2][2]=pp2[2][2];

//Column 3
assign pp3[0][3]=pp2[0][3];
assign pp3[1][3]=pp2[1][3];
assign pp3[2][3]=pp2[2][3];
assign pp3[3][3]=pp2[3][3];

//Column 4
assign pp3[0][4]=pp2[0][4];
assign pp3[1][4]=pp2[1][4];
assign pp3[2][4]=pp2[2][4];
assign pp3[3][4]=pp2[3][4];
assign pp3[4][4]=pp2[4][4];

//Column 5
assign pp3[0][5]=pp2[0][5];
assign pp3[1][5]=pp2[1][5];
assign pp3[2][5]=pp2[2][5];
assign pp3[3][5]=pp2[3][5];
assign pp3[4][5]=pp2[4][5];
assign pp3[5][5]=pp2[5][5];

//Column 6
exact_22 s2_6(.a(pp2[0][6]),.b(pp2[1][6]),.sum(pp3[0][6]),.carry(pp3[0][7]));
assign pp3[1][6]=pp2[2][6];
assign pp3[2][6]=pp2[3][6];
assign pp3[3][6]=pp2[4][6];
assign pp3[4][6]=pp2[5][6];
assign pp3[5][6]=pp2[6][6];

//Column 7
exact_42 s2_7(.a(pp2[0][7]),.b(pp2[1][7]),.c(pp2[2][7]),.d(pp2[3][7]),.cin(1'b0),.sum(pp3[1][7]),.carry(pp3[0][8]),.cout(cin2[0]));
assign pp3[2][7]=pp2[4][7];
assign pp3[3][7]=pp2[5][7];
assign pp3[4][7]=pp2[6][7];
assign pp3[5][7]=pp2[7][7];

//Column 8
exact_42 s2_81(.a(pp2[0][8]),.b(pp2[1][8]),.c(pp2[2][8]),.d(pp2[3][8]),.cin(cin2[0]),.sum(pp3[1][8]),.carry(pp3[0][9]),.cout(cin2[1]));
exact_22 s2_82(.a(pp2[4][8]),.b(pp2[5][8]),.sum(pp3[2][8]),.carry(pp3[1][9]));
assign pp3[3][8]=pp2[6][8];
assign pp3[4][8]=pp2[7][8];
assign pp3[5][8]=pp2[8][8];

//Column 9
exact_42 s2_91(.a(pp2[0][9]),.b(pp2[1][9]),.c(pp2[2][9]),.d(pp2[3][9]),.cin(cin2[1]),.sum(pp3[2][9]),.carry(pp3[0][10]),.cout(cin2[2]));
exact_42 s2_92(.a(pp2[4][9]),.b(pp2[5][9]),.c(pp2[6][9]),.d(pp2[7][9]),.cin(1'b0),.sum(pp3[3][9]),.carry(pp3[1][10]),.cout(cin2[3]));
assign pp3[4][9]=pp2[8][9];
assign pp3[5][9]=pp2[9][9];

//Column 10
exact_42 s2_101(.a(pp2[0][10]),.b(pp2[1][10]),.c(pp2[2][10]),.d(pp2[3][10]),.cin(cin2[2]),.sum(pp3[2][10]),.carry(pp3[0][11]),.cout(cin2[4]));
exact_42 s2_102(.a(pp2[4][10]),.b(pp2[5][10]),.c(pp2[6][10]),.d(pp2[7][10]),.cin(cin2[3]),.sum(pp3[3][10]),.carry(pp3[1][11]),.cout(cin2[5]));
exact_22 s2_103(.a(pp2[8][10]),.b(pp2[9][10]),.sum(pp3[4][10]),.carry(pp3[2][11]));
assign pp3[5][10]=pp2[10][10];

//Column 11
exact_42 s2_111(.a(pp2[0][11]),.b(pp2[1][11]),.c(pp2[2][11]),.d(pp2[3][11]),.cin(cin2[4]),.sum(pp3[3][11]),.carry(pp3[0][12]),.cout(cin2[6]));
exact_42 s2_112(.a(pp2[4][11]),.b(pp2[5][11]),.c(pp2[6][11]),.d(pp2[7][11]),.cin(cin2[5]),.sum(pp3[4][11]),.carry(pp3[1][12]),.cout(cin2[7]));
exact_42 s2_113(.a(pp2[8][11]),.b(pp2[9][11]),.c(pp2[10][11]),.d(pp2[11][11]),.cin(1'b0),.sum(pp3[5][11]),.carry(pp3[2][12]),.cout(cin2[8]));

//Column 12
exact_42 s2_121(.a(pp2[0][12]),.b(pp2[1][12]),.c(pp2[2][12]),.d(pp2[3][12]),.cin(cin2[6]),.sum(pp3[3][12]),.carry(pp3[0][13]),.cout(cin2[9]));
exact_42 s2_122(.a(pp2[4][12]),.b(pp2[5][12]),.c(pp2[6][12]),.d(pp2[7][12]),.cin(cin2[7]),.sum(pp3[4][12]),.carry(pp3[1][13]),.cout(cin2[10]));
exact_42 s2_123(.a(pp2[8][12]),.b(pp2[9][12]),.c(pp2[10][12]),.d(pp2[11][12]),.cin(cin2[8]),.sum(pp3[5][12]),.carry(pp3[2][13]),.cout(cin2[11]));

//Column 13
exact_42 s2_131(.a(pp2[0][13]),.b(pp2[1][13]),.c(pp2[2][13]),.d(pp2[3][13]),.cin(cin2[9]),.sum(pp3[3][13]),.carry(pp3[0][14]),.cout(cin2[12]));
exact_42 s2_132(.a(pp2[4][13]),.b(pp2[5][13]),.c(pp2[6][13]),.d(pp2[7][13]),.cin(cin2[10]),.sum(pp3[4][13]),.carry(pp3[1][14]),.cout(cin2[13]));
exact_42 s2_133(.a(pp2[8][13]),.b(pp2[9][13]),.c(pp2[10][13]),.d(pp2[11][13]),.cin(cin2[11]),.sum(pp3[5][13]),.carry(pp3[2][14]),.cout(cin2[14]));

//Column 14
exact_42 s2_141(.a(pp2[0][14]),.b(pp2[1][14]),.c(pp2[2][14]),.d(pp2[3][14]),.cin(cin2[12]),.sum(pp3[3][14]),.carry(pp3[0][15]),.cout(cin2[15]));
exact_42 s2_142(.a(pp2[4][14]),.b(pp2[5][14]),.c(pp2[6][14]),.d(pp2[7][14]),.cin(cin2[13]),.sum(pp3[4][14]),.carry(pp3[1][15]),.cout(cin2[16]));
exact_42 s2_143(.a(pp2[8][14]),.b(pp2[9][14]),.c(pp2[10][14]),.d(pp2[11][14]),.cin(cin2[14]),.sum(pp3[5][14]),.carry(pp3[2][15]),.cout(cin2[17]));

//Column 15
exact_42 s2_151(.a(pp2[0][15]),.b(pp2[1][15]),.c(pp2[2][15]),.d(pp2[3][15]),.cin(cin2[15]),.sum(pp3[3][15]),.carry(pp3[0][16]),.cout(cin2[18]));
exact_42 s2_152(.a(pp2[4][15]),.b(pp2[5][15]),.c(pp2[6][15]),.d(pp2[7][15]),.cin(cin2[16]),.sum(pp3[4][15]),.carry(pp3[1][16]),.cout(cin2[19]));
exact_42 s2_153(.a(pp2[8][15]),.b(pp2[9][15]),.c(pp2[10][15]),.d(pp2[11][15]),.cin(cin2[17]),.sum(pp3[5][15]),.carry(pp3[2][16]),.cout(cin2[20]));

//Column 16
exact_42 s2_161(.a(pp2[0][16]),.b(pp2[1][16]),.c(pp2[2][16]),.d(pp2[3][16]),.cin(cin2[18]),.sum(pp3[3][16]),.carry(pp3[0][17]),.cout(cin2[21]));
exact_42 s2_162(.a(pp2[4][16]),.b(pp2[5][16]),.c(pp2[6][16]),.d(pp2[7][16]),.cin(cin2[19]),.sum(pp3[4][16]),.carry(pp3[1][17]),.cout(cin2[22]));
exact_42 s2_163(.a(pp2[8][16]),.b(pp2[9][16]),.c(pp2[10][16]),.d(pp2[11][16]),.cin(cin2[20]),.sum(pp3[5][16]),.carry(pp3[2][17]),.cout(cin2[23]));

//Column 17
exact_42 s2_171(.a(pp2[0][17]),.b(pp2[1][17]),.c(pp2[2][17]),.d(pp2[3][17]),.cin(cin2[21]),.sum(pp3[3][17]),.carry(pp3[0][18]),.cout(cin2[24]));
exact_42 s2_172(.a(pp2[4][17]),.b(pp2[5][17]),.c(pp2[6][17]),.d(pp2[7][17]),.cin(cin2[22]),.sum(pp3[4][17]),.carry(pp3[1][18]),.cout(cin2[25]));
exact_42 s2_173(.a(pp2[8][17]),.b(pp2[9][17]),.c(pp2[10][17]),.d(pp2[11][17]),.cin(cin2[23]),.sum(pp3[5][17]),.carry(pp3[2][18]),.cout(cin2[26]));

//Column 18
exact_42 s2_181(.a(pp2[0][18]),.b(pp2[1][18]),.c(pp2[2][18]),.d(pp2[3][18]),.cin(cin2[24]),.sum(pp3[3][18]),.carry(pp3[0][19]),.cout(cin2[27]));
exact_42 s2_182(.a(pp2[4][18]),.b(pp2[5][18]),.c(pp2[6][18]),.d(pp2[7][18]),.cin(cin2[25]),.sum(pp3[4][18]),.carry(pp3[1][19]),.cout(cin2[28]));
exact_42 s2_183(.a(pp2[8][18]),.b(pp2[9][18]),.c(pp2[10][18]),.d(pp2[11][18]),.cin(cin2[26]),.sum(pp3[5][18]),.carry(pp3[2][19]),.cout(cin2[29]));

//Column 19
exact_42 s2_191(.a(pp2[0][19]),.b(pp2[1][19]),.c(pp2[2][19]),.d(pp2[3][19]),.cin(cin2[27]),.sum(pp3[3][19]),.carry(pp3[0][20]),.cout(cin2[30]));
exact_42 s2_192(.a(pp2[4][19]),.b(pp2[5][19]),.c(pp2[6][19]),.d(pp2[7][19]),.cin(cin2[28]),.sum(pp3[4][19]),.carry(pp3[1][20]),.cout(cin2[31]));
exact_42 s2_193(.a(pp2[8][19]),.b(pp2[9][19]),.c(pp2[10][19]),.d(pp2[11][19]),.cin(cin2[29]),.sum(pp3[5][19]),.carry(pp3[2][20]),.cout(cin2[32]));

//Column 20
exact_42 s2_201(.a(pp2[0][20]),.b(pp2[1][20]),.c(pp2[2][20]),.d(pp2[3][20]),.cin(cin2[30]),.sum(pp3[3][20]),.carry(pp3[0][21]),.cout(cin2[33]));
exact_42 s2_202(.a(pp2[4][20]),.b(pp2[5][20]),.c(pp2[6][20]),.d(pp2[7][20]),.cin(cin2[31]),.sum(pp3[4][20]),.carry(pp3[1][21]),.cout(cin2[34]));
exact_42 s2_203(.a(pp2[8][20]),.b(pp2[9][20]),.c(pp2[10][20]),.d(pp2[11][20]),.cin(cin2[32]),.sum(pp3[5][20]),.carry(pp3[2][21]),.cout(cin2[35]));

//Column 21
exact_42 s2_211(.a(pp2[0][21]),.b(pp2[1][21]),.c(pp2[2][21]),.d(pp2[3][21]),.cin(cin2[33]),.sum(pp3[3][21]),.carry(pp3[0][22]),.cout(cin2[36]));
exact_42 s2_212(.a(pp2[4][21]),.b(pp2[5][21]),.c(pp2[6][21]),.d(pp2[7][21]),.cin(cin2[34]),.sum(pp3[4][21]),.carry(pp3[1][22]),.cout(cin2[37]));
exact_42 s2_213(.a(pp2[8][21]),.b(pp2[9][21]),.c(pp2[10][21]),.d(pp2[11][21]),.cin(cin2[35]),.sum(pp3[5][21]),.carry(pp3[2][22]),.cout(cin2[38]));

//Column 22
exact_42 s2_221(.a(pp2[0][22]),.b(pp2[1][22]),.c(pp2[2][22]),.d(pp2[3][22]),.cin(cin2[36]),.sum(pp3[3][22]),.carry(pp3[0][23]),.cout(cin2[39]));
exact_42 s2_222(.a(pp2[4][22]),.b(pp2[5][22]),.c(pp2[6][22]),.d(pp2[7][22]),.cin(cin2[37]),.sum(pp3[4][22]),.carry(pp3[1][23]),.cout(cin2[40]));
exact_42 s2_223(.a(pp2[8][22]),.b(pp2[9][22]),.c(pp2[10][22]),.d(pp2[11][22]),.cin(cin2[38]),.sum(pp3[5][22]),.carry(pp3[2][23]),.cout(cin2[41]));

//Column 23
exact_42 s2_231(.a(pp2[0][23]),.b(pp2[1][23]),.c(pp2[2][23]),.d(pp2[3][23]),.cin(cin2[39]),.sum(pp3[3][23]),.carry(pp3[0][24]),.cout(cin2[42]));
exact_42 s2_232(.a(pp2[4][23]),.b(pp2[5][23]),.c(pp2[6][23]),.d(pp2[7][23]),.cin(cin2[40]),.sum(pp3[4][23]),.carry(pp3[1][24]),.cout(cin2[43]));
exact_42 s2_233(.a(pp2[8][23]),.b(pp2[9][23]),.c(pp2[10][23]),.d(pp2[11][23]),.cin(cin2[41]),.sum(pp3[5][23]),.carry(pp3[2][24]),.cout(cin2[44]));

//Column 24
exact_42 s2_241(.a(pp2[0][24]),.b(pp2[1][24]),.c(pp2[2][24]),.d(pp2[3][24]),.cin(cin2[42]),.sum(pp3[3][24]),.carry(pp3[0][25]),.cout(cin2[45]));
exact_42 s2_242(.a(pp2[4][24]),.b(pp2[5][24]),.c(pp2[6][24]),.d(pp2[7][24]),.cin(cin2[43]),.sum(pp3[4][24]),.carry(pp3[1][25]),.cout(cin2[46]));
exact_42 s2_243(.a(pp2[8][24]),.b(pp2[9][24]),.c(pp2[10][24]),.d(pp2[11][24]),.cin(cin2[44]),.sum(pp3[5][24]),.carry(pp3[2][25]),.cout(cin2[47]));

//Column 25
exact_42 s2_251(.a(pp2[0][25]),.b(pp2[1][25]),.c(pp2[2][25]),.d(pp2[3][25]),.cin(cin2[45]),.sum(pp3[3][25]),.carry(pp3[0][26]),.cout(cin2[48]));
exact_42 s2_252(.a(pp2[4][25]),.b(pp2[5][25]),.c(pp2[6][25]),.d(pp2[7][25]),.cin(cin2[46]),.sum(pp3[4][25]),.carry(pp3[1][26]),.cout(cin2[49]));
exact_42 s2_253(.a(pp2[8][25]),.b(pp2[9][25]),.c(pp2[10][25]),.d(pp2[11][25]),.cin(cin2[47]),.sum(pp3[5][25]),.carry(pp3[2][26]),.cout(cin2[50]));

//Column 26
exact_42 s2_261(.a(pp2[0][26]),.b(pp2[1][26]),.c(pp2[2][26]),.d(pp2[3][26]),.cin(cin2[48]),.sum(pp3[3][26]),.carry(pp3[0][27]),.cout(cin2[51]));
exact_42 s2_262(.a(pp2[4][26]),.b(pp2[5][26]),.c(pp2[6][26]),.d(pp2[7][26]),.cin(cin2[49]),.sum(pp3[4][26]),.carry(pp3[1][27]),.cout(cin2[52]));
exact_42 s2_263(.a(pp2[8][26]),.b(pp2[9][26]),.c(pp2[10][26]),.d(pp2[11][26]),.cin(cin2[50]),.sum(pp3[5][26]),.carry(pp3[2][27]),.cout(cin2[53]));

//Column 27
exact_42 s2_271(.a(pp2[0][27]),.b(pp2[1][27]),.c(pp2[2][27]),.d(pp2[3][27]),.cin(cin2[51]),.sum(pp3[3][27]),.carry(pp3[0][28]),.cout(cin2[54]));
exact_42 s2_272(.a(pp2[4][27]),.b(pp2[5][27]),.c(pp2[6][27]),.d(pp2[7][27]),.cin(cin2[52]),.sum(pp3[4][27]),.carry(pp3[1][28]),.cout(cin2[55]));
exact_42 s2_273(.a(pp2[8][27]),.b(pp2[9][27]),.c(pp2[10][27]),.d(pp2[11][27]),.cin(cin2[53]),.sum(pp3[5][27]),.carry(pp3[2][28]),.cout(cin2[56]));

//Column 28
exact_42 s2_281(.a(pp2[0][28]),.b(pp2[1][28]),.c(pp2[2][28]),.d(pp2[3][28]),.cin(cin2[54]),.sum(pp3[3][28]),.carry(pp3[0][29]),.cout(cin2[57]));
exact_42 s2_282(.a(pp2[4][28]),.b(pp2[5][28]),.c(pp2[6][28]),.d(pp2[7][28]),.cin(cin2[55]),.sum(pp3[4][28]),.carry(pp3[1][29]),.cout(cin2[58]));
exact_42 s2_283(.a(pp2[8][28]),.b(pp2[9][28]),.c(pp2[10][28]),.d(pp2[11][28]),.cin(cin2[56]),.sum(pp3[5][28]),.carry(pp3[2][29]),.cout(cin2[59]));

//Column 29
exact_42 s2_291(.a(pp2[0][29]),.b(pp2[1][29]),.c(pp2[2][29]),.d(pp2[3][29]),.cin(cin2[57]),.sum(pp3[3][29]),.carry(pp3[0][30]),.cout(cin2[60]));
exact_42 s2_292(.a(pp2[4][29]),.b(pp2[5][29]),.c(pp2[6][29]),.d(pp2[7][29]),.cin(cin2[58]),.sum(pp3[4][29]),.carry(pp3[1][30]),.cout(cin2[61]));
exact_42 s2_293(.a(pp2[8][29]),.b(pp2[9][29]),.c(pp2[10][29]),.d(pp2[11][29]),.cin(cin2[59]),.sum(pp3[5][29]),.carry(pp3[2][30]),.cout(cin2[62]));

//Column 30
exact_42 s2_301(.a(pp2[0][30]),.b(pp2[1][30]),.c(pp2[2][30]),.d(pp2[3][30]),.cin(cin2[60]),.sum(pp3[3][30]),.carry(pp3[0][31]),.cout(cin2[63]));
exact_42 s2_302(.a(pp2[4][30]),.b(pp2[5][30]),.c(pp2[6][30]),.d(pp2[7][30]),.cin(cin2[61]),.sum(pp3[4][30]),.carry(pp3[1][31]),.cout(cin2[64]));
exact_42 s2_303(.a(pp2[8][30]),.b(pp2[9][30]),.c(pp2[10][30]),.d(pp2[11][30]),.cin(cin2[62]),.sum(pp3[5][30]),.carry(pp3[2][31]),.cout(cin2[65]));

//Column 31
exact_42 s2_311(.a(pp2[0][31]),.b(pp2[1][31]),.c(pp2[2][31]),.d(pp2[3][31]),.cin(cin2[63]),.sum(pp3[3][31]),.carry(pp3[0][32]),.cout(cin2[66]));
exact_42 s2_312(.a(pp2[4][31]),.b(pp2[5][31]),.c(pp2[6][31]),.d(pp2[7][31]),.cin(cin2[64]),.sum(pp3[4][31]),.carry(pp3[1][32]),.cout(cin2[67]));
exact_42 s2_313(.a(pp2[8][31]),.b(pp2[9][31]),.c(pp2[10][31]),.d(pp2[11][31]),.cin(cin2[65]),.sum(pp3[5][31]),.carry(pp3[2][32]),.cout(cin2[68]));

//Column 32
exact_42 s2_321(.a(pp2[0][32]),.b(pp2[1][32]),.c(pp2[2][32]),.d(pp2[3][32]),.cin(cin2[66]),.sum(pp3[3][32]),.carry(pp3[0][33]),.cout(cin2[69]));
exact_42 s2_322(.a(pp2[4][32]),.b(pp2[5][32]),.c(pp2[6][32]),.d(pp2[7][32]),.cin(cin2[67]),.sum(pp3[4][32]),.carry(pp3[1][33]),.cout(cin2[70]));
exact_42 s2_323(.a(pp2[8][32]),.b(pp2[9][32]),.c(pp2[10][32]),.d(pp2[11][32]),.cin(cin2[68]),.sum(pp3[5][32]),.carry(pp3[2][33]),.cout(cin2[71]));

//Column 33
exact_42 s2_331(.a(pp2[0][33]),.b(pp2[1][33]),.c(pp2[2][33]),.d(pp2[3][33]),.cin(cin2[69]),.sum(pp3[3][33]),.carry(pp3[0][34]),.cout(cin2[72]));
exact_42 s2_332(.a(pp2[4][33]),.b(pp2[5][33]),.c(pp2[6][33]),.d(pp2[7][33]),.cin(cin2[70]),.sum(pp3[4][33]),.carry(pp3[1][34]),.cout(cin2[73]));
exact_42 s2_333(.a(pp2[8][33]),.b(pp2[9][33]),.c(pp2[10][33]),.d(pp2[11][33]),.cin(cin2[71]),.sum(pp3[5][33]),.carry(pp3[2][34]),.cout(cin2[74]));

//Column 34
exact_42 s2_341(.a(pp2[0][34]),.b(pp2[1][34]),.c(pp2[2][34]),.d(pp2[3][34]),.cin(cin2[72]),.sum(pp3[3][34]),.carry(pp3[0][35]),.cout(cin2[75]));
exact_42 s2_342(.a(pp2[4][34]),.b(pp2[5][34]),.c(pp2[6][34]),.d(pp2[7][34]),.cin(cin2[73]),.sum(pp3[4][34]),.carry(pp3[1][35]),.cout(cin2[76]));
exact_42 s2_343(.a(pp2[8][34]),.b(pp2[9][34]),.c(pp2[10][34]),.d(pp2[11][34]),.cin(cin2[74]),.sum(pp3[5][34]),.carry(pp3[2][35]),.cout(cin2[77]));

//Column 35
exact_42 s2_351(.a(pp2[0][35]),.b(pp2[1][35]),.c(pp2[2][35]),.d(pp2[3][35]),.cin(cin2[75]),.sum(pp3[3][35]),.carry(pp3[0][36]),.cout(cin2[78]));
exact_42 s2_352(.a(pp2[4][35]),.b(pp2[5][35]),.c(pp2[6][35]),.d(pp2[7][35]),.cin(cin2[76]),.sum(pp3[4][35]),.carry(pp3[1][36]),.cout(cin2[79]));
exact_42 s2_353(.a(pp2[8][35]),.b(pp2[9][35]),.c(pp2[10][35]),.d(pp2[11][35]),.cin(cin2[77]),.sum(pp3[5][35]),.carry(pp3[2][36]),.cout(cin2[80]));

//Column 36
exact_42 s2_361(.a(pp2[0][36]),.b(pp2[1][36]),.c(pp2[2][36]),.d(pp2[3][36]),.cin(cin2[78]),.sum(pp3[3][36]),.carry(pp3[0][37]),.cout(cin2[81]));
exact_42 s2_362(.a(pp2[4][36]),.b(pp2[5][36]),.c(pp2[6][36]),.d(pp2[7][36]),.cin(cin2[79]),.sum(pp3[4][36]),.carry(pp3[1][37]),.cout(cin2[82]));
exact_42 s2_363(.a(pp2[8][36]),.b(pp2[9][36]),.c(pp2[10][36]),.d(pp2[11][36]),.cin(cin2[80]),.sum(pp3[5][36]),.carry(pp3[2][37]),.cout(cin2[83]));

//Column 37
exact_42 s2_371(.a(pp2[0][37]),.b(pp2[1][37]),.c(pp2[2][37]),.d(pp2[3][37]),.cin(cin2[81]),.sum(pp3[3][37]),.carry(pp3[0][38]),.cout(cin2[84]));
exact_42 s2_372(.a(pp2[4][37]),.b(pp2[5][37]),.c(pp2[6][37]),.d(pp2[7][37]),.cin(cin2[82]),.sum(pp3[4][37]),.carry(pp3[1][38]),.cout(cin2[85]));
exact_32 s2_373(.a(pp2[8][37]),.b(pp2[9][37]),.c(cin2[83]),.sum(pp3[5][37]),.carry(pp3[2][38]));

//Column 38
exact_42 s2_381(.a(pp2[0][38]),.b(pp2[1][38]),.c(pp2[2][38]),.d(pp2[3][38]),.cin(cin2[84]),.sum(pp3[3][38]),.carry(pp3[0][39]),.cout(cin2[86]));
exact_42 s2_382(.a(pp2[4][38]),.b(pp2[5][38]),.c(pp2[6][38]),.d(pp2[7][38]),.cin(cin2[85]),.sum(pp3[4][38]),.carry(pp3[1][39]),.cout(cin2[87]));
assign pp3[5][38]=pp2[8][38];

//Column 39
exact_42 s2_391(.a(pp2[0][39]),.b(pp2[1][39]),.c(pp2[2][39]),.d(pp2[3][39]),.cin(cin2[86]),.sum(pp3[2][39]),.carry(pp3[0][40]),.cout(cin2[88]));
exact_32 s2_392(.a(pp2[4][39]),.b(pp2[5][39]),.c(cin2[87]),.sum(pp3[3][39]),.carry(pp3[1][40]));
assign pp3[4][39]=pp2[6][39];
assign pp3[5][39]=pp2[7][39];

//Column 40
exact_42 s2_40(.a(pp2[0][40]),.b(pp2[1][40]),.c(pp2[2][40]),.d(pp2[3][40]),.cin(cin2[88]),.sum(pp3[2][40]),.carry(pp3[0][41]),.cout(cin2[89]));
assign pp3[3][40]=pp2[4][40];
assign pp3[4][40]=pp2[5][40];
assign pp3[5][40]=pp2[6][40];

//Column 41
exact_32 s2_41(.a(pp2[0][41]),.b(pp2[1][41]),.c(cin2[89]),.sum(pp3[1][41]),.carry(pp3[0][42]));
assign pp3[2][41]=pp2[2][41];
assign pp3[3][41]=pp2[3][41];
assign pp3[4][41]=pp2[4][41];
assign pp3[5][41]=pp2[5][41];

//Column 42
assign pp3[1][42]=pp2[0][42];
assign pp3[2][42]=pp2[1][42];
assign pp3[3][42]=pp2[2][42];
assign pp3[4][42]=pp2[3][42];
assign pp3[5][42]=pp2[4][42];

//Column 43
assign pp3[0][43]=pp2[0][43];
assign pp3[1][43]=pp2[1][43];
assign pp3[2][43]=pp2[2][43];
assign pp3[3][43]=pp2[3][43];

//Column 44
assign pp3[0][44]=pp2[0][44];
assign pp3[1][44]=pp2[1][44];
assign pp3[2][44]=pp2[2][44];

//Column 45
assign pp3[0][45]=pp2[0][45];
assign pp3[1][45]=pp2[1][45];

//Column 46
assign pp3[0][46]=pp2[0][46];



/******************** Reduction Stage 3 ********************/
wire pp4[3:0][46:0];

//Column 0
assign pp4[0][0]=pp3[0][0];

//Column 1
assign pp4[0][1]=pp3[0][1];
assign pp4[1][1]=pp3[1][1];

//Column 2
assign pp4[0][2]=pp3[0][2];
assign pp4[1][2]=pp3[1][2];
assign pp4[2][2]=pp3[2][2];

//Column 3
assign pp4[0][3]=pp3[0][3];
assign pp4[1][3]=pp3[1][3];
assign pp4[2][3]=pp3[2][3];
assign pp4[3][3]=pp3[3][3];

//Column 4
exact_22 s3_42(.a(pp3[0][4]),.b(pp3[1][4]),.sum(pp4[0][4]),.carry(pp4[0][5]));
assign pp4[1][4]=pp3[2][4];
assign pp4[2][4]=pp3[3][4];
assign pp4[3][4]=pp3[4][4];

//Column 5
exact_32 s3_51(.a(pp3[0][5]),.b(pp3[1][5]),.c(pp3[2][5]),.sum(pp4[1][5]),.carry(pp4[0][6]));
exact_22 s3_52(.a(pp3[3][5]),.b(pp3[4][5]),.sum(pp4[2][5]),.carry(pp4[1][6]));
assign pp4[3][5]=pp3[5][5];

//Column 6
exact_32 s3_61(.a(pp3[0][6]),.b(pp3[1][6]),.c(pp3[2][6]),.sum(pp4[2][6]),.carry(pp4[0][7]));
exact_32 s3_62(.a(pp3[3][6]),.b(pp3[4][6]),.c(pp3[5][6]),.sum(pp4[3][6]),.carry(pp4[1][7]));

//Column 7
exact_32 s3_71(.a(pp3[0][7]),.b(pp3[1][7]),.c(pp3[2][7]),.sum(pp4[2][7]),.carry(pp4[0][8]));
exact_32 s3_72(.a(pp3[3][7]),.b(pp3[4][7]),.c(pp3[5][7]),.sum(pp4[3][7]),.carry(pp4[1][8]));

//Column 8
exact_32 s3_81(.a(pp3[0][8]),.b(pp3[1][8]),.c(pp3[2][8]),.sum(pp4[2][8]),.carry(pp4[0][9]));
exact_32 s3_82(.a(pp3[3][8]),.b(pp3[4][8]),.c(pp3[5][8]),.sum(pp4[3][8]),.carry(pp4[1][9]));

//Column 9
exact_32 s3_91(.a(pp3[0][9]),.b(pp3[1][9]),.c(pp3[2][9]),.sum(pp4[2][9]),.carry(pp4[0][10]));
exact_32 s3_92(.a(pp3[3][9]),.b(pp3[4][9]),.c(pp3[5][9]),.sum(pp4[3][9]),.carry(pp4[1][10]));

//Column 10
exact_32 s3_101(.a(pp3[0][10]),.b(pp3[1][10]),.c(pp3[2][10]),.sum(pp4[2][10]),.carry(pp4[0][11]));
exact_32 s3_102(.a(pp3[3][10]),.b(pp3[4][10]),.c(pp3[5][10]),.sum(pp4[3][10]),.carry(pp4[1][11]));

//Column 11
exact_32 s3_111(.a(pp3[0][11]),.b(pp3[1][11]),.c(pp3[2][11]),.sum(pp4[2][11]),.carry(pp4[0][12]));
exact_32 s3_112(.a(pp3[3][11]),.b(pp3[4][11]),.c(pp3[5][11]),.sum(pp4[3][11]),.carry(pp4[1][12]));

//Column 12
exact_32 s3_121(.a(pp3[0][12]),.b(pp3[1][12]),.c(pp3[2][12]),.sum(pp4[2][12]),.carry(pp4[0][13]));
exact_32 s3_122(.a(pp3[3][12]),.b(pp3[4][12]),.c(pp3[5][12]),.sum(pp4[3][12]),.carry(pp4[1][13]));

//Column 13
exact_32 s3_131(.a(pp3[0][13]),.b(pp3[1][13]),.c(pp3[2][13]),.sum(pp4[2][13]),.carry(pp4[0][14]));
exact_32 s3_132(.a(pp3[3][13]),.b(pp3[4][13]),.c(pp3[5][13]),.sum(pp4[3][13]),.carry(pp4[1][14]));

//Column 14
exact_32 s3_141(.a(pp3[0][14]),.b(pp3[1][14]),.c(pp3[2][14]),.sum(pp4[2][14]),.carry(pp4[0][15]));
exact_32 s3_142(.a(pp3[3][14]),.b(pp3[4][14]),.c(pp3[5][14]),.sum(pp4[3][14]),.carry(pp4[1][15]));

//Column 15
exact_32 s3_151(.a(pp3[0][15]),.b(pp3[1][15]),.c(pp3[2][15]),.sum(pp4[2][15]),.carry(pp4[0][16]));
exact_32 s3_152(.a(pp3[3][15]),.b(pp3[4][15]),.c(pp3[5][15]),.sum(pp4[3][15]),.carry(pp4[1][16]));

//Column 16
exact_32 s3_161(.a(pp3[0][16]),.b(pp3[1][16]),.c(pp3[2][16]),.sum(pp4[2][16]),.carry(pp4[0][17]));
exact_32 s3_162(.a(pp3[3][16]),.b(pp3[4][16]),.c(pp3[5][16]),.sum(pp4[3][16]),.carry(pp4[1][17]));

//Column 17
exact_32 s3_171(.a(pp3[0][17]),.b(pp3[1][17]),.c(pp3[2][17]),.sum(pp4[2][17]),.carry(pp4[0][18]));
exact_32 s3_172(.a(pp3[3][17]),.b(pp3[4][17]),.c(pp3[5][17]),.sum(pp4[3][17]),.carry(pp4[1][18]));

//Column 18
exact_32 s3_181(.a(pp3[0][18]),.b(pp3[1][18]),.c(pp3[2][18]),.sum(pp4[2][18]),.carry(pp4[0][19]));
exact_32 s3_182(.a(pp3[3][18]),.b(pp3[4][18]),.c(pp3[5][18]),.sum(pp4[3][18]),.carry(pp4[1][19]));

//Column 19
exact_32 s3_191(.a(pp3[0][19]),.b(pp3[1][19]),.c(pp3[2][19]),.sum(pp4[2][19]),.carry(pp4[0][20]));
exact_32 s3_192(.a(pp3[3][19]),.b(pp3[4][19]),.c(pp3[5][19]),.sum(pp4[3][19]),.carry(pp4[1][20]));

//Column 20
exact_32 s3_201(.a(pp3[0][20]),.b(pp3[1][20]),.c(pp3[2][20]),.sum(pp4[2][20]),.carry(pp4[0][21]));
exact_32 s3_202(.a(pp3[3][20]),.b(pp3[4][20]),.c(pp3[5][20]),.sum(pp4[3][20]),.carry(pp4[1][21]));

//Column 21
exact_32 s3_211(.a(pp3[0][21]),.b(pp3[1][21]),.c(pp3[2][21]),.sum(pp4[2][21]),.carry(pp4[0][22]));
exact_32 s3_212(.a(pp3[3][21]),.b(pp3[4][21]),.c(pp3[5][21]),.sum(pp4[3][21]),.carry(pp4[1][22]));

//Column 22
exact_32 s3_221(.a(pp3[0][22]),.b(pp3[1][22]),.c(pp3[2][22]),.sum(pp4[2][22]),.carry(pp4[0][23]));
exact_32 s3_222(.a(pp3[3][22]),.b(pp3[4][22]),.c(pp3[5][22]),.sum(pp4[3][22]),.carry(pp4[1][23]));

//Column 23
exact_32 s3_231(.a(pp3[0][23]),.b(pp3[1][23]),.c(pp3[2][23]),.sum(pp4[2][23]),.carry(pp4[0][24]));
exact_32 s3_232(.a(pp3[3][23]),.b(pp3[4][23]),.c(pp3[5][23]),.sum(pp4[3][23]),.carry(pp4[1][24]));

//Column 24
exact_32 s3_241(.a(pp3[0][24]),.b(pp3[1][24]),.c(pp3[2][24]),.sum(pp4[2][24]),.carry(pp4[0][25]));
exact_32 s3_242(.a(pp3[3][24]),.b(pp3[4][24]),.c(pp3[5][24]),.sum(pp4[3][24]),.carry(pp4[1][25]));

//Column 25
exact_32 s3_251(.a(pp3[0][25]),.b(pp3[1][25]),.c(pp3[2][25]),.sum(pp4[2][25]),.carry(pp4[0][26]));
exact_32 s3_252(.a(pp3[3][25]),.b(pp3[4][25]),.c(pp3[5][25]),.sum(pp4[3][25]),.carry(pp4[1][26]));

//Column 26
exact_32 s3_261(.a(pp3[0][26]),.b(pp3[1][26]),.c(pp3[2][26]),.sum(pp4[2][26]),.carry(pp4[0][27]));
exact_32 s3_262(.a(pp3[3][26]),.b(pp3[4][26]),.c(pp3[5][26]),.sum(pp4[3][26]),.carry(pp4[1][27]));

//Column 27
exact_32 s3_271(.a(pp3[0][27]),.b(pp3[1][27]),.c(pp3[2][27]),.sum(pp4[2][27]),.carry(pp4[0][28]));
exact_32 s3_272(.a(pp3[3][27]),.b(pp3[4][27]),.c(pp3[5][27]),.sum(pp4[3][27]),.carry(pp4[1][28]));

//Column 28
exact_32 s3_281(.a(pp3[0][28]),.b(pp3[1][28]),.c(pp3[2][28]),.sum(pp4[2][28]),.carry(pp4[0][29]));
exact_32 s3_282(.a(pp3[3][28]),.b(pp3[4][28]),.c(pp3[5][28]),.sum(pp4[3][28]),.carry(pp4[1][29]));

//Column 29
exact_32 s3_291(.a(pp3[0][29]),.b(pp3[1][29]),.c(pp3[2][29]),.sum(pp4[2][29]),.carry(pp4[0][30]));
exact_32 s3_292(.a(pp3[3][29]),.b(pp3[4][29]),.c(pp3[5][29]),.sum(pp4[3][29]),.carry(pp4[1][30]));

//Column 30
exact_32 s3_301(.a(pp3[0][30]),.b(pp3[1][30]),.c(pp3[2][30]),.sum(pp4[2][30]),.carry(pp4[0][31]));
exact_32 s3_302(.a(pp3[3][30]),.b(pp3[4][30]),.c(pp3[5][30]),.sum(pp4[3][30]),.carry(pp4[1][31]));

//Column 31
exact_32 s3_311(.a(pp3[0][31]),.b(pp3[1][31]),.c(pp3[2][31]),.sum(pp4[2][31]),.carry(pp4[0][32]));
exact_32 s3_312(.a(pp3[3][31]),.b(pp3[4][31]),.c(pp3[5][31]),.sum(pp4[3][31]),.carry(pp4[1][32]));

//Column 32
exact_32 s3_321(.a(pp3[0][32]),.b(pp3[1][32]),.c(pp3[2][32]),.sum(pp4[2][32]),.carry(pp4[0][33]));
exact_32 s3_322(.a(pp3[3][32]),.b(pp3[4][32]),.c(pp3[5][32]),.sum(pp4[3][32]),.carry(pp4[1][33]));

//Column 33
exact_32 s3_331(.a(pp3[0][33]),.b(pp3[1][33]),.c(pp3[2][33]),.sum(pp4[2][33]),.carry(pp4[0][34]));
exact_32 s3_332(.a(pp3[3][33]),.b(pp3[4][33]),.c(pp3[5][33]),.sum(pp4[3][33]),.carry(pp4[1][34]));

//Column 34
exact_32 s3_341(.a(pp3[0][34]),.b(pp3[1][34]),.c(pp3[2][34]),.sum(pp4[2][34]),.carry(pp4[0][35]));
exact_32 s3_342(.a(pp3[3][34]),.b(pp3[4][34]),.c(pp3[5][34]),.sum(pp4[3][34]),.carry(pp4[1][35]));

//Column 35
exact_32 s3_351(.a(pp3[0][35]),.b(pp3[1][35]),.c(pp3[2][35]),.sum(pp4[2][35]),.carry(pp4[0][36]));
exact_32 s3_352(.a(pp3[3][35]),.b(pp3[4][35]),.c(pp3[5][35]),.sum(pp4[3][35]),.carry(pp4[1][36]));

//Column 36
exact_32 s3_361(.a(pp3[0][36]),.b(pp3[1][36]),.c(pp3[2][36]),.sum(pp4[2][36]),.carry(pp4[0][37]));
exact_32 s3_362(.a(pp3[3][36]),.b(pp3[4][36]),.c(pp3[5][36]),.sum(pp4[3][36]),.carry(pp4[1][37]));

//Column 37
exact_32 s3_371(.a(pp3[0][37]),.b(pp3[1][37]),.c(pp3[2][37]),.sum(pp4[2][37]),.carry(pp4[0][38]));
exact_32 s3_372(.a(pp3[3][37]),.b(pp3[4][37]),.c(pp3[5][37]),.sum(pp4[3][37]),.carry(pp4[1][38]));

//Column 38
exact_32 s3_381(.a(pp3[0][38]),.b(pp3[1][38]),.c(pp3[2][38]),.sum(pp4[2][38]),.carry(pp4[0][39]));
exact_32 s3_382(.a(pp3[3][38]),.b(pp3[4][38]),.c(pp3[5][38]),.sum(pp4[3][38]),.carry(pp4[1][39]));

//Column 39
exact_32 s3_391(.a(pp3[0][39]),.b(pp3[1][39]),.c(pp3[2][39]),.sum(pp4[2][39]),.carry(pp4[0][40]));
exact_32 s3_392(.a(pp3[3][39]),.b(pp3[4][39]),.c(pp3[5][39]),.sum(pp4[3][39]),.carry(pp4[1][40]));

//Column 40
exact_32 s3_401(.a(pp3[0][40]),.b(pp3[1][40]),.c(pp3[2][40]),.sum(pp4[2][40]),.carry(pp4[0][41]));
exact_32 s3_402(.a(pp3[3][40]),.b(pp3[4][40]),.c(pp3[5][40]),.sum(pp4[3][40]),.carry(pp4[1][41]));

//Column 41
exact_32 s3_411(.a(pp3[0][41]),.b(pp3[1][41]),.c(pp3[2][41]),.sum(pp4[2][41]),.carry(pp4[0][42]));
exact_32 s3_412(.a(pp3[3][41]),.b(pp3[4][41]),.c(pp3[5][41]),.sum(pp4[3][41]),.carry(pp4[1][42]));

//Column 42
exact_32 s3_421(.a(pp3[0][42]),.b(pp3[1][42]),.c(pp3[2][42]),.sum(pp4[2][42]),.carry(pp4[0][43]));
exact_32 s3_422(.a(pp3[3][42]),.b(pp3[4][42]),.c(pp3[5][42]),.sum(pp4[3][42]),.carry(pp4[1][43]));

//Column 43
exact_32 s3_431(.a(pp3[0][43]),.b(pp3[1][43]),.c(pp3[2][43]),.sum(pp4[2][43]),.carry(pp4[0][44]));
assign pp4[3][43]=pp3[3][43];

//Column 44
assign pp4[1][44]=pp3[0][44];
assign pp4[2][44]=pp3[1][44];
assign pp4[3][44]=pp3[2][44];

//Column 45
assign pp4[0][45]=pp3[0][45];
assign pp4[1][45]=pp3[1][45];

//Column 46
assign pp4[0][46]=pp3[0][46];



/******************** Reduction Stage 4 ********************/
wire pp5[1:0][46:0];
wire cin4[41:0];

//Column 0
assign pp5[0][0]=pp4[0][0];

//Column 1
assign pp5[0][1]=pp4[0][1];
assign pp5[1][1]=pp4[1][1];

//Column 2
exact_22 s4_2(.a(pp4[0][2]),.b(pp4[1][2]),.sum(pp5[0][2]),.carry(pp5[0][3]));
assign pp5[1][2]=pp4[2][2];

//Column 3
exact_42 s4_3(.a(pp4[0][3]),.b(pp4[1][3]),.c(pp4[2][3]),.d(pp4[3][3]),.cin(1'b0),.sum(pp5[1][3]),.carry(pp5[0][4]),.cout(cin4[0]));

//Column 4
exact_42 s4_4(.a(pp4[0][4]),.b(pp4[1][4]),.c(pp4[2][4]),.d(pp4[3][4]),.cin(cin4[0]),.sum(pp5[1][4]),.carry(pp5[0][5]),.cout(cin4[1]));

//Column 5
exact_42 s4_5(.a(pp4[0][5]),.b(pp4[1][5]),.c(pp4[2][5]),.d(pp4[3][5]),.cin(cin4[1]),.sum(pp5[1][5]),.carry(pp5[0][6]),.cout(cin4[2]));

//Column 6
exact_42 s4_6(.a(pp4[0][6]),.b(pp4[1][6]),.c(pp4[2][6]),.d(pp4[3][6]),.cin(cin4[2]),.sum(pp5[1][6]),.carry(pp5[0][7]),.cout(cin4[3]));

//Column 7
exact_42 s4_7(.a(pp4[0][7]),.b(pp4[1][7]),.c(pp4[2][7]),.d(pp4[3][7]),.cin(cin4[3]),.sum(pp5[1][7]),.carry(pp5[0][8]),.cout(cin4[4]));

//Column 8
exact_42 s4_8(.a(pp4[0][8]),.b(pp4[1][8]),.c(pp4[2][8]),.d(pp4[3][8]),.cin(cin4[4]),.sum(pp5[1][8]),.carry(pp5[0][9]),.cout(cin4[5]));

//Column 9
exact_42 s4_9(.a(pp4[0][9]),.b(pp4[1][9]),.c(pp4[2][9]),.d(pp4[3][9]),.cin(cin4[5]),.sum(pp5[1][9]),.carry(pp5[0][10]),.cout(cin4[6]));

//Column 10
exact_42 s4_10(.a(pp4[0][10]),.b(pp4[1][10]),.c(pp4[2][10]),.d(pp4[3][10]),.cin(cin4[6]),.sum(pp5[1][10]),.carry(pp5[0][11]),.cout(cin4[7]));

//Column 11
exact_42 s4_11(.a(pp4[0][11]),.b(pp4[1][11]),.c(pp4[2][11]),.d(pp4[3][11]),.cin(cin4[7]),.sum(pp5[1][11]),.carry(pp5[0][12]),.cout(cin4[8]));

//Column 12
exact_42 s4_12(.a(pp4[0][12]),.b(pp4[1][12]),.c(pp4[2][12]),.d(pp4[3][12]),.cin(cin4[8]),.sum(pp5[1][12]),.carry(pp5[0][13]),.cout(cin4[9]));

//Column 13
exact_42 s4_13(.a(pp4[0][13]),.b(pp4[1][13]),.c(pp4[2][13]),.d(pp4[3][13]),.cin(cin4[9]),.sum(pp5[1][13]),.carry(pp5[0][14]),.cout(cin4[10]));

//Column 14
exact_42 s4_14(.a(pp4[0][14]),.b(pp4[1][14]),.c(pp4[2][14]),.d(pp4[3][14]),.cin(cin4[10]),.sum(pp5[1][14]),.carry(pp5[0][15]),.cout(cin4[11]));

//Column 15
exact_42 s4_15(.a(pp4[0][15]),.b(pp4[1][15]),.c(pp4[2][15]),.d(pp4[3][15]),.cin(cin4[11]),.sum(pp5[1][15]),.carry(pp5[0][16]),.cout(cin4[12]));

//Column 16
exact_42 s4_16(.a(pp4[0][16]),.b(pp4[1][16]),.c(pp4[2][16]),.d(pp4[3][16]),.cin(cin4[12]),.sum(pp5[1][16]),.carry(pp5[0][17]),.cout(cin4[13]));

//Column 17
exact_42 s4_17(.a(pp4[0][17]),.b(pp4[1][17]),.c(pp4[2][17]),.d(pp4[3][17]),.cin(cin4[13]),.sum(pp5[1][17]),.carry(pp5[0][18]),.cout(cin4[14]));

//Column 18
exact_42 s4_18(.a(pp4[0][18]),.b(pp4[1][18]),.c(pp4[2][18]),.d(pp4[3][18]),.cin(cin4[14]),.sum(pp5[1][18]),.carry(pp5[0][19]),.cout(cin4[15]));

//Column 19
exact_42 s4_19(.a(pp4[0][19]),.b(pp4[1][19]),.c(pp4[2][19]),.d(pp4[3][19]),.cin(cin4[15]),.sum(pp5[1][19]),.carry(pp5[0][20]),.cout(cin4[16]));

//Column 20
exact_42 s4_20(.a(pp4[0][20]),.b(pp4[1][20]),.c(pp4[2][20]),.d(pp4[3][20]),.cin(cin4[16]),.sum(pp5[1][20]),.carry(pp5[0][21]),.cout(cin4[17]));

//Column 21
exact_42 s4_21(.a(pp4[0][21]),.b(pp4[1][21]),.c(pp4[2][21]),.d(pp4[3][21]),.cin(cin4[17]),.sum(pp5[1][21]),.carry(pp5[0][22]),.cout(cin4[18]));

//Column 22
exact_42 s4_22(.a(pp4[0][22]),.b(pp4[1][22]),.c(pp4[2][22]),.d(pp4[3][22]),.cin(cin4[18]),.sum(pp5[1][22]),.carry(pp5[0][23]),.cout(cin4[19]));

//Column 23
exact_42 s4_23(.a(pp4[0][23]),.b(pp4[1][23]),.c(pp4[2][23]),.d(pp4[3][23]),.cin(cin4[19]),.sum(pp5[1][23]),.carry(pp5[0][24]),.cout(cin4[20]));

//Column 24
exact_42 s4_24(.a(pp4[0][24]),.b(pp4[1][24]),.c(pp4[2][24]),.d(pp4[3][24]),.cin(cin4[20]),.sum(pp5[1][24]),.carry(pp5[0][25]),.cout(cin4[21]));

//Column 25
exact_42 s4_25(.a(pp4[0][25]),.b(pp4[1][25]),.c(pp4[2][25]),.d(pp4[3][25]),.cin(cin4[21]),.sum(pp5[1][25]),.carry(pp5[0][26]),.cout(cin4[22]));

//Column 26
exact_42 s4_26(.a(pp4[0][26]),.b(pp4[1][26]),.c(pp4[2][26]),.d(pp4[3][26]),.cin(cin4[22]),.sum(pp5[1][26]),.carry(pp5[0][27]),.cout(cin4[23]));

//Column 27
exact_42 s4_27(.a(pp4[0][27]),.b(pp4[1][27]),.c(pp4[2][27]),.d(pp4[3][27]),.cin(cin4[23]),.sum(pp5[1][27]),.carry(pp5[0][28]),.cout(cin4[24]));

//Column 28
exact_42 s4_28(.a(pp4[0][28]),.b(pp4[1][28]),.c(pp4[2][28]),.d(pp4[3][28]),.cin(cin4[24]),.sum(pp5[1][28]),.carry(pp5[0][29]),.cout(cin4[25]));

//Column 29
exact_42 s4_29(.a(pp4[0][29]),.b(pp4[1][29]),.c(pp4[2][29]),.d(pp4[3][29]),.cin(cin4[25]),.sum(pp5[1][29]),.carry(pp5[0][30]),.cout(cin4[26]));

//Column 30
exact_42 s4_30(.a(pp4[0][30]),.b(pp4[1][30]),.c(pp4[2][30]),.d(pp4[3][30]),.cin(cin4[26]),.sum(pp5[1][30]),.carry(pp5[0][31]),.cout(cin4[27]));

//Column 31
exact_42 s4_31(.a(pp4[0][31]),.b(pp4[1][31]),.c(pp4[2][31]),.d(pp4[3][31]),.cin(cin4[27]),.sum(pp5[1][31]),.carry(pp5[0][32]),.cout(cin4[28]));

//Column 32
exact_42 s4_32(.a(pp4[0][32]),.b(pp4[1][32]),.c(pp4[2][32]),.d(pp4[3][32]),.cin(cin4[28]),.sum(pp5[1][32]),.carry(pp5[0][33]),.cout(cin4[29]));

//Column 33
exact_42 s4_33(.a(pp4[0][33]),.b(pp4[1][33]),.c(pp4[2][33]),.d(pp4[3][33]),.cin(cin4[29]),.sum(pp5[1][33]),.carry(pp5[0][34]),.cout(cin4[30]));

//Column 34
exact_42 s4_34(.a(pp4[0][34]),.b(pp4[1][34]),.c(pp4[2][34]),.d(pp4[3][34]),.cin(cin4[30]),.sum(pp5[1][34]),.carry(pp5[0][35]),.cout(cin4[31]));

//Column 35
exact_42 s4_35(.a(pp4[0][35]),.b(pp4[1][35]),.c(pp4[2][35]),.d(pp4[3][35]),.cin(cin4[31]),.sum(pp5[1][35]),.carry(pp5[0][36]),.cout(cin4[32]));

//Column 36
exact_42 s4_36(.a(pp4[0][36]),.b(pp4[1][36]),.c(pp4[2][36]),.d(pp4[3][36]),.cin(cin4[32]),.sum(pp5[1][36]),.carry(pp5[0][37]),.cout(cin4[33]));

//Column 37
exact_42 s4_37(.a(pp4[0][37]),.b(pp4[1][37]),.c(pp4[2][37]),.d(pp4[3][37]),.cin(cin4[33]),.sum(pp5[1][37]),.carry(pp5[0][38]),.cout(cin4[34]));

//Column 38
exact_42 s4_38(.a(pp4[0][38]),.b(pp4[1][38]),.c(pp4[2][38]),.d(pp4[3][38]),.cin(cin4[34]),.sum(pp5[1][38]),.carry(pp5[0][39]),.cout(cin4[35]));

//Column 39
exact_42 s4_39(.a(pp4[0][39]),.b(pp4[1][39]),.c(pp4[2][39]),.d(pp4[3][39]),.cin(cin4[35]),.sum(pp5[1][39]),.carry(pp5[0][40]),.cout(cin4[36]));

//Column 40
exact_42 s4_40(.a(pp4[0][40]),.b(pp4[1][40]),.c(pp4[2][40]),.d(pp4[3][40]),.cin(cin4[36]),.sum(pp5[1][40]),.carry(pp5[0][41]),.cout(cin4[37]));

//Column 41
exact_42 s4_41(.a(pp4[0][41]),.b(pp4[1][41]),.c(pp4[2][41]),.d(pp4[3][41]),.cin(cin4[37]),.sum(pp5[1][41]),.carry(pp5[0][42]),.cout(cin4[38]));

//Column 42
exact_42 s4_42(.a(pp4[0][42]),.b(pp4[1][42]),.c(pp4[2][42]),.d(pp4[3][42]),.cin(cin4[38]),.sum(pp5[1][42]),.carry(pp5[0][43]),.cout(cin4[39]));

//Column 43
exact_42 s4_43(.a(pp4[0][43]),.b(pp4[1][43]),.c(pp4[2][43]),.d(pp4[3][43]),.cin(cin4[39]),.sum(pp5[1][43]),.carry(pp5[0][44]),.cout(cin4[40]));

//Column 44
exact_42 s4_44(.a(pp4[0][44]),.b(pp4[1][44]),.c(pp4[2][44]),.d(pp4[3][44]),.cin(cin4[40]),.sum(pp5[1][44]),.carry(pp5[0][45]),.cout(cin4[41]));

//Column 45
exact_32 s4_45(.a(pp4[0][45]),.b(pp4[1][45]),.c(cin4[41]),.sum(pp5[1][45]),.carry(pp5[0][46]));

//Column 46
assign pp5[1][46]=pp4[0][46];



/******************** Reduction Stage 5 ********************/
wire cin5[46:0];

//Column 0
assign res[0]=pp5[0][0];

//Column 1
exact_22 s5_1(.a(pp5[0][1]),.b(pp5[1][1]),.sum(res[1]),.carry(cin5[0]));

//Column 2
exact_32 s5_2(.a(pp5[0][2]),.b(pp5[1][2]),.c(cin5[0]),.sum(res[2]),.carry(cin5[1]));

//Column 3
exact_32 s5_3(.a(pp5[0][3]),.b(pp5[1][3]),.c(cin5[1]),.sum(res[3]),.carry(cin5[2]));

//Column 4
exact_32 s5_4(.a(pp5[0][4]),.b(pp5[1][4]),.c(cin5[2]),.sum(res[4]),.carry(cin5[3]));

//Column 5
exact_32 s5_5(.a(pp5[0][5]),.b(pp5[1][5]),.c(cin5[3]),.sum(res[5]),.carry(cin5[4]));

//Column 6
exact_32 s5_6(.a(pp5[0][6]),.b(pp5[1][6]),.c(cin5[4]),.sum(res[6]),.carry(cin5[5]));

//Column 7
exact_32 s5_7(.a(pp5[0][7]),.b(pp5[1][7]),.c(cin5[5]),.sum(res[7]),.carry(cin5[6]));

//Column 8
exact_32 s5_8(.a(pp5[0][8]),.b(pp5[1][8]),.c(cin5[6]),.sum(res[8]),.carry(cin5[7]));

//Column 9
exact_32 s5_9(.a(pp5[0][9]),.b(pp5[1][9]),.c(cin5[7]),.sum(res[9]),.carry(cin5[8]));

//Column 10
exact_32 s5_10(.a(pp5[0][10]),.b(pp5[1][10]),.c(cin5[8]),.sum(res[10]),.carry(cin5[9]));

//Column 11
exact_32 s5_11(.a(pp5[0][11]),.b(pp5[1][11]),.c(cin5[9]),.sum(res[11]),.carry(cin5[10]));

//Column 12
exact_32 s5_12(.a(pp5[0][12]),.b(pp5[1][12]),.c(cin5[10]),.sum(res[12]),.carry(cin5[11]));

//Column 13
exact_32 s5_13(.a(pp5[0][13]),.b(pp5[1][13]),.c(cin5[11]),.sum(res[13]),.carry(cin5[12]));

//Column 14
exact_32 s5_14(.a(pp5[0][14]),.b(pp5[1][14]),.c(cin5[12]),.sum(res[14]),.carry(cin5[13]));

//Column 15
exact_32 s5_15(.a(pp5[0][15]),.b(pp5[1][15]),.c(cin5[13]),.sum(res[15]),.carry(cin5[14]));

//Column 16
exact_32 s5_16(.a(pp5[0][16]),.b(pp5[1][16]),.c(cin5[14]),.sum(res[16]),.carry(cin5[15]));

//Column 17
exact_32 s5_17(.a(pp5[0][17]),.b(pp5[1][17]),.c(cin5[15]),.sum(res[17]),.carry(cin5[16]));

//Column 18
exact_32 s5_18(.a(pp5[0][18]),.b(pp5[1][18]),.c(cin5[16]),.sum(res[18]),.carry(cin5[17]));

//Column 19
exact_32 s5_19(.a(pp5[0][19]),.b(pp5[1][19]),.c(cin5[17]),.sum(res[19]),.carry(cin5[18]));

//Column 20
exact_32 s5_20(.a(pp5[0][20]),.b(pp5[1][20]),.c(cin5[18]),.sum(res[20]),.carry(cin5[19]));

//Column 21
exact_32 s5_21(.a(pp5[0][21]),.b(pp5[1][21]),.c(cin5[19]),.sum(res[21]),.carry(cin5[20]));

//Column 22
exact_32 s5_22(.a(pp5[0][22]),.b(pp5[1][22]),.c(cin5[20]),.sum(res[22]),.carry(cin5[21]));

//Column 23
exact_32 s5_23(.a(pp5[0][23]),.b(pp5[1][23]),.c(cin5[21]),.sum(res[23]),.carry(cin5[22]));

//Column 24
exact_32 s5_24(.a(pp5[0][24]),.b(pp5[1][24]),.c(cin5[22]),.sum(res[24]),.carry(cin5[23]));

//Column 25
exact_32 s5_25(.a(pp5[0][25]),.b(pp5[1][25]),.c(cin5[23]),.sum(res[25]),.carry(cin5[24]));

//Column 26
exact_32 s5_26(.a(pp5[0][26]),.b(pp5[1][26]),.c(cin5[24]),.sum(res[26]),.carry(cin5[25]));

//Column 27
exact_32 s5_27(.a(pp5[0][27]),.b(pp5[1][27]),.c(cin5[25]),.sum(res[27]),.carry(cin5[26]));

//Column 28
exact_32 s5_28(.a(pp5[0][28]),.b(pp5[1][28]),.c(cin5[26]),.sum(res[28]),.carry(cin5[27]));

//Column 29
exact_32 s5_29(.a(pp5[0][29]),.b(pp5[1][29]),.c(cin5[27]),.sum(res[29]),.carry(cin5[28]));

//Column 30
exact_32 s5_30(.a(pp5[0][30]),.b(pp5[1][30]),.c(cin5[28]),.sum(res[30]),.carry(cin5[29]));

//Column 31
exact_32 s5_31(.a(pp5[0][31]),.b(pp5[1][31]),.c(cin5[29]),.sum(res[31]),.carry(cin5[30]));

//Column 32
exact_32 s5_32(.a(pp5[0][32]),.b(pp5[1][32]),.c(cin5[30]),.sum(res[32]),.carry(cin5[31]));

//Column 33
exact_32 s5_33(.a(pp5[0][33]),.b(pp5[1][33]),.c(cin5[31]),.sum(res[33]),.carry(cin5[32]));

//Column 34
exact_32 s5_34(.a(pp5[0][34]),.b(pp5[1][34]),.c(cin5[32]),.sum(res[34]),.carry(cin5[33]));

//Column 35
exact_32 s5_35(.a(pp5[0][35]),.b(pp5[1][35]),.c(cin5[33]),.sum(res[35]),.carry(cin5[34]));

//Column 36
exact_32 s5_36(.a(pp5[0][36]),.b(pp5[1][36]),.c(cin5[34]),.sum(res[36]),.carry(cin5[35]));

//Column 37
exact_32 s5_37(.a(pp5[0][37]),.b(pp5[1][37]),.c(cin5[35]),.sum(res[37]),.carry(cin5[36]));

//Column 38
exact_32 s5_38(.a(pp5[0][38]),.b(pp5[1][38]),.c(cin5[36]),.sum(res[38]),.carry(cin5[37]));

//Column 39
exact_32 s5_39(.a(pp5[0][39]),.b(pp5[1][39]),.c(cin5[37]),.sum(res[39]),.carry(cin5[38]));

//Column 40
exact_32 s5_40(.a(pp5[0][40]),.b(pp5[1][40]),.c(cin5[38]),.sum(res[40]),.carry(cin5[39]));

//Column 41
exact_32 s5_41(.a(pp5[0][41]),.b(pp5[1][41]),.c(cin5[39]),.sum(res[41]),.carry(cin5[40]));

//Column 42
exact_32 s5_42(.a(pp5[0][42]),.b(pp5[1][42]),.c(cin5[40]),.sum(res[42]),.carry(cin5[41]));

//Column 43
exact_32 s5_43(.a(pp5[0][43]),.b(pp5[1][43]),.c(cin5[41]),.sum(res[43]),.carry(cin5[42]));

//Column 44
exact_32 s5_44(.a(pp5[0][44]),.b(pp5[1][44]),.c(cin5[42]),.sum(res[44]),.carry(cin5[43]));

//Column 45
exact_32 s5_45(.a(pp5[0][45]),.b(pp5[1][45]),.c(cin5[43]),.sum(res[45]),.carry(cin5[44]));

//Column 46
exact_32 s5_46(.a(pp5[0][46]),.b(pp5[1][46]),.c(cin5[44]),.sum(res[46]),.carry(res[47]));


endmodule



//Exact Half Adders
module exact_22(input a,b, output sum,carry);
    xor sumg(sum,a,b);
    and carryg(carry,a,b);

endmodule


//Pos Half Adder
module approx_22_2(
    input a,b,
    output sum,carry);
    
    or  g1(sum,a,b);
    and g2(carry,a,b);


endmodule


//Neg Half Adder
module approx_22_3(
    input a,b,
    output sum,carry);
    
    or  g1(sum,a,b);
    assign carry=0;


endmodule


//Full Adders
module exact_32(input a,b,c, output sum,carry   );
   xor sumg(sum, a,b,c);
   wire ab,bc,ca;
   and a1(ab,a,b);
   and a2(bc,b,c);
   and a3(ca,c,a);
   or carryg(carry, ab,bc,ca);

endmodule


//Pos Full Adder
module approx_32_2(
    input a,b,c,
    output sum,carry);

    and g1(w1,b,c);
    or g2(carry,a,w1);
    or g3(sum,b,c);


endmodule  


//Neg Full Adder
module approx_32_3(
    input a,b,c,
    output sum,carry);
    
    and g2(carry,a,b,c);
    or  g4(sum,a,b,c);


endmodule    


//4:2 Compressor
module exact_42(
    input a,b,c,d,
    input cin,
    output sum, 
    output carry,
    output cout);
    wire w1;
    
    exact_32 fa1 (.a(a),.b(b),.c(c),.carry(cout),.sum(w1));
    exact_32 fa2 (.a(d),.b(w1),.c(cin),.carry(carry),.sum(sum));

endmodule


//Pos 4:2 Compressor
module approx_42_2(
    input a,b,c,d,
    output sum,carry
    );
    
    wire w1,w2;
    
    or g1(sum,c,d);
    and g3(w2,c,d);
    or g4(carry,a,b,w2);
    

endmodule


//Neg 4:2 Compressor
module approx_42_3(
    input a,b,c,d,
    output sum,carry
    );

    wire w1,w2,abar;
    
    or g2(w2,c,d,b); // B+C+D
    not g4(abar,a); // ~A
    and g5(sum,w2,abar); // ~A(B+C+D)
    and g6(carry,w2,a); // A(B+C+D)
    

endmodule
