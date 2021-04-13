module simple_counter
# (
  parameter WIDTH          = 2
)
(
  input                  clk,
  input                  clk_enable,
  input                  reset,
    
  output [WIDTH - 1 : 0] q
);
  reg [WIDTH - 1 : 0] count;

  always @ (posedge clk)
  begin
    if (reset)
       count <= {WIDTH{1'b0}};
        else if (clk_enable)
          count <= count + 1;
  end

  assign q = count;
  
endmodule