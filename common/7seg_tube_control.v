module 7seg_tube_control
# (
  parameter WIDTH          = 32, //All digit width
            BITS_PER_DIGIT = 4,
            N_DIGITS       = w / bits_per_digit
)
(
  input        clk,
  input        reset,
    
  output [7:0] abcdefgh, // abcdefg - digit, h - point
  output [3:0] digit
);

