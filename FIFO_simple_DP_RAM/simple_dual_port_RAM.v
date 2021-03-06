module simple_dual_port_RAM
#(
  parameter DATA_WIDTH = 8, 
            ADDR_WIDTH = 4
)
(
  input                           clk,
  // Read port:
  input                           read_enable, 
  input       [(ADDR_WIDTH-1):0]  read_addr, 
  input       [(DATA_WIDTH-1):0]  data_in,
  // Write port:
  input                           write_enable, 
  input       [(ADDR_WIDTH-1):0]  write_addr,
  output reg  [(DATA_WIDTH-1):0]  data_out
);
  // Declare the array variable
  reg [DATA_WIDTH-1:0] dp_ram [0:2**ADDR_WIDTH-1];
 
  // Write
  always @ (posedge clk)
  begin
    if (write_enable)
      dp_ram [write_addr] <= data_in;
  end
  
  
  // Read
  always @ (posedge clk)
  begin
  //  if (read_enable)
      data_out = dp_ram [read_addr];
  end

endmodule