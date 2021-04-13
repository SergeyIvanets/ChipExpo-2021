module 7seg_decoder
(
  input        code,
  output [7:0] abcdefgh
);

  always @*                     
    case (code)
      'h0: abcdefg = 'b0000001;  // a b c d e f g
      'h1: abcdefg = 'b1111001;
      'h2: abcdefg = 'b0100100;  //   --a--
      'h3: abcdefg = 'b0110000;  //  |     |
      'h4: abcdefg = 'b0011001;  //  f     b
      'h5: abcdefg = 'b0010010;  //  |     |
      'h6: abcdefg = 'b0000010;  //   --g--
      'h7: abcdefg = 'b1111000;  //  |     |
      'h8: abcdefg = 'b0000000;  //  e     c
      'h9: abcdefg = 'b0011000;  //  |     |
      'ha: abcdefg = 'b0001000;  //   --d-- 
      'hb: abcdefg = 'b0000011;
      'hc: abcdefg = 'b1000110;
      'hd: abcdefg = 'b0100001;
      'he: abcdefg = 'b0000110;
      'hf: abcdefg = 'b0001110;
  endcase
endmodule