`timescale 1 ns / 1 ns
`default_nettype none 

module fifo_reg_file
#(
  parameter   FIFO_DEPTH        = 4,
              FIFO_DATA_WIDTH   = 8
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
  
  logic [FIFO_DATA_WIDTH-1:0] fifo_array [FIFO_DEPTH-1:0];

  logic [FIFO_PTR_WIDTH-1:0]  rd_ptr;
  logic [FIFO_PTR_WIDTH-1:0]  wr_ptr;
  logic [FIFO_DATA_WIDTH-1:0] read_data_int;

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
      rd_ptr <= #1 {FIFO_PTR_WIDTH{1'b0}};
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

  //-----------------------------------------------
  // FIFO Write
  //-----------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      fifo_array[wr_ptr] <= #1 {FIFO_DATA_WIDTH{1'b0}};
    else if (write & !full)
      fifo_array[wr_ptr[FIFO_PTR_WIDTH-2:0]] <= #1 write_data;
  end

  //-----------------------------------------------
  // FIFO Read
  //-----------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      read_data_int <= #1 {FIFO_DATA_WIDTH{1'b0}};
    else if (read & !empty)
      read_data_int <= #1 fifo_array[rd_ptr[FIFO_PTR_WIDTH-2:0]];
  end

 assign read_data = read_data_int;

endmodule