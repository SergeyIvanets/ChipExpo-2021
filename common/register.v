module register
# (
  parameter WIDTH          = 4
)
(
  input                  clk,
  input                  clk_enable,
  input                  reset,
  input                  write,
  input  [WIDTH - 1 : 0] data,
    
  output [WIDTH - 1 : 0] q
);

  always @ (posedge clk)
  begin
    if (reset)
      q <= {WIDTH{1'b0}};
      else if (clk_enable)
        if (write)
          q <= data;
  end
endmodule