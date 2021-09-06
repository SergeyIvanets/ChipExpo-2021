`include "simple_dual_port_RAM.sv"
`timescale 1 ns / 1 ns
`default_nettype none 

module fifo_simple_DP_RAM
#(
  parameter   FIFO_DEPTH         = 256,
              FIFO_DATA_WIDTH    = 8,
              ALMOST_FULL_DEPTH  = 2,
              ALMOST_EMPTY_DEPTH = 2,
              LATENCY            = 3 // min value 2
)
(
  input wire                           clk,
  input wire                           reset,

  input wire                           write,
  input wire                           read,

  input wire     [FIFO_DATA_WIDTH-1:0] write_data,
  output wire    [FIFO_DATA_WIDTH-1:0] read_data,

  output wire                          empty,
  output wire                          full
);

  localparam FIFO_PTR_WIDTH   = $clog2(FIFO_DEPTH) + 1;
  
  logic    [FIFO_PTR_WIDTH-1:0]  rd_ptr;
  logic    [FIFO_PTR_WIDTH-1:0]  wr_ptr;

  logic                         write_enable;
  logic   [FIFO_DATA_WIDTH-1:0] read_data_wire;

  simple_dual_port_RAM 
  # (.DATA_WIDTH  ( FIFO_DATA_WIDTH                  ),
     .ADDR_WIDTH  ( FIFO_PTR_WIDTH                   ),
     .LATENCY     ( LATENCY                          )
  )
  fifo_array
  (
    .clk          ( clk                              ),
    .write_enable ( write                            ),
    .write_addr   ( wr_ptr                           ),
    .data_in      ( write_data                       ),
    .read_enable  ( read                             ),
    .read_addr    ( rd_ptr                           ),
    .data_out     ( read_data_wire                   )
  );

  //------------------------------------------------
  // Write Pointer Logic
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
        wr_ptr <= #1 {FIFO_PTR_WIDTH{1'b0}};
    else if (write & !full)
        wr_ptr <= #1 wr_ptr + 1'b1;
  end

  //------------------------------------------------
  // Read Pointer Logic
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      rd_ptr   <= #1 {FIFO_PTR_WIDTH{1'b0}};
    else if (read & !empty)
        rd_ptr <= #1 rd_ptr + 1'b1;
  end

  //------------------------------------------------
  // Full and Empty flags
  //------------------------------------------------
  assign full  = 
         (wr_ptr[FIFO_PTR_WIDTH-1] ^ rd_ptr[FIFO_PTR_WIDTH-1]) 
       & (wr_ptr[FIFO_PTR_WIDTH-2:0] == rd_ptr[FIFO_PTR_WIDTH-2:0]);
  assign empty = (wr_ptr == rd_ptr);

  assign read_data = read_data_wire;


endmodule