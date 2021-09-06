`timescale 1 ns / 1 ns
`default_nettype none 

module simple_dual_port_RAM
#(
  parameter DATA_WIDTH = 8, 
            ADDR_WIDTH = 4,
            LATENCY    = 3 // min value 2
)
(
  input wire                      clk,
  // Write port:
  input  wire                      write_enable, 
  input  wire  [(ADDR_WIDTH-1):0]  write_addr,
  input  wire  [(DATA_WIDTH-1):0]  data_in,
  // Read port:
  input  wire                      read_enable, 
  input  wire [(ADDR_WIDTH-1):0]   read_addr, 
  output wire [(DATA_WIDTH-1):0]   data_out
);

  // Declare the array variable
  logic [DATA_WIDTH-1:0] dp_ram [0:2**ADDR_WIDTH-1];

  // Number of clock cycles = LATENCY
  logic  [DATA_WIDTH - 1:0] write_data_int   [LATENCY - 1:0];
  logic  [ADDR_WIDTH - 1:0] write_addr_int   [LATENCY - 1:0];
  logic                     write_enable_int [LATENCY - 1:0];
  logic  [DATA_WIDTH - 1:0] read_data_int    [LATENCY - 2:0];
  
  int i;

  // Write port
  always @ (posedge clk)
  begin
    write_data_int [0] <= #1 data_in;
    for (i = 1; i < LATENCY; i = i + 1)
      write_data_int [i] <= #1 write_data_int [i - 1];
  end

  always @ (posedge clk)
  begin
    write_addr_int [0] <= #1 write_addr;
    for (i = 1; i < LATENCY; i = i + 1)
      write_addr_int [i] <= #1 write_addr_int [i - 1];
  end

  always @ (posedge clk)
  begin
    write_enable_int [0] <= #1 write_enable;
    for (i = 1; i < LATENCY; i = i + 1)
      write_enable_int [i] <= #1 write_enable_int [i - 1];
  end

  // Write
  always @ (posedge clk)
  begin
    if (write_enable_int[LATENCY - 1])
      dp_ram [write_addr_int[LATENCY - 1] ] <= #1 write_data_int [LATENCY - 1];
  end

  // Read
  always @ (posedge clk)
  begin
    read_data_int [0] <= #1 dp_ram [read_addr];
    for (i = 1; i < LATENCY - 1; i = i + 1)
      read_data_int [i] <= #1 read_data_int [i - 1];
  end
 
  assign data_out = read_data_int [LATENCY - 2];

endmodule