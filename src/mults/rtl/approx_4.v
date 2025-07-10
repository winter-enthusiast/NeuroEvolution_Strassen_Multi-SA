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