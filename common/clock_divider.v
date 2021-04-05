  // Clock divider 
  // 
  module clock_divider
# (
  parameter CLK_INPUT   = 25,
            CLK_OUTPUT  = 3
  )
(
  input        clk,
  input        reset,
    
  output reg   clk_div
);

  localparam CLK_DIV_KOEFF = CLK_INPUT / CLK_OUTPUT;
  localparam COUNT_WIDTH   = $clog2(CLK_DIV_KOEFF);

    reg [COUNT_WIDTH - 1:0] count;

//    always @ (posedge(clk))
//    begin
//      if (reset)
//        count <= {COUNT_WIDTH{1'b0}};
//      else if (count == CLK_DIV_KOEFF - 1)
//        count <= {COUNT_WIDTH{1'b0}};
//      else
//        count <= count + 1;
//    end
//
//    always @ (posedge(clk))
//    begin
//        if (reset)
//            clk_div <= 1'b0;
//        else if (count == CLK_DIV_KOEFF - 1)
//            clk_div <= 1'b1;
//        else
//            clk_div <= 1'b0;
//    end  

    
    always @ (posedge(clk))
    begin
      if (reset)
        count <= {COUNT_WIDTH{1'b0}};
      else if (count == {COUNT_WIDTH{1'b0}})
        count <= CLK_DIV_KOEFF-1;
      else
        count <= count - 1;
    end

    always @ (posedge(clk))
    begin
        if (reset)
            clk_div <= 1'b0;
        else if (count == {COUNT_WIDTH{1'b0}})
            clk_div <= 1'b1;
        else
            clk_div <= 1'b0;
    end  
endmodule