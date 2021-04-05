module 7seg_tube
# (
  parameter WIDTH          = 32, //All digit width
            BITS_PER_DIGIT = 4,
            N_DIGITS       = w / bits_per_digit
)
(
  input        clk,
  input        reset_n,
    
  input  [3:0] key_sw,
  output [3:0] led,

  output [7:0] abcdefgh,
  output [3:0] digit,

  output       hsync,
  output       vsync,
  output [2:0] rgb
);
