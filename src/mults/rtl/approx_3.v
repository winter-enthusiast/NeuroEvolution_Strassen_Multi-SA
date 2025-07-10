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