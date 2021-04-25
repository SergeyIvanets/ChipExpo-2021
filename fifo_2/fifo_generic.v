// Using http://rtlery.com/components/generic-fifo
// FIFO module description
module fifo_generic
#(
  parameter   FIFO_DEPTH        = 8,
              FIFO_DATA_WIDTH   = 8,
              ALMOSTFULL_DEPTH  = 2,
              ALMOSTEMPTY_DEPTH = 2
)
(
  input                            clk,
  input                            reset,

  input                            write,
  input                            read,

  input      [FIFO_DATA_WIDTH-1:0] write_data,
  output reg [FIFO_DATA_WIDTH-1:0] read_data,

  output                           empty,
  output                           full,
  output                           almost_empty,
  output                           almost_full
);

  localparam FIFO_PTR_WIDTH   = $clog2(FIFO_DEPTH) + 1;
  localparam ALMOSTFULL_VALUE = FIFO_DEPTH - ALMOSTFULL_DEPTH;
  
  reg [FIFO_DATA_WIDTH-1:0] fifo_array [FIFO_DEPTH-1:0];

  reg [FIFO_PTR_WIDTH-1:0]  rd_ptr;
  reg [FIFO_PTR_WIDTH-1:0]  wr_ptr;
  reg [FIFO_PTR_WIDTH-1:0]  operation_count;

  //------------------------------------------------
  // Write Pointer Logic
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      wr_ptr          <= {FIFO_PTR_WIDTH{1'b0}};
    else if (write & !full)
      wr_ptr          <= wr_ptr + 1'b1;
  end

  //------------------------------------------------
  // Read Pointer Logic
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      rd_ptr <= {FIFO_PTR_WIDTH{1'b0}};
    else if (read & !empty)
      rd_ptr <= rd_ptr + 1'b1;
  end

  //------------------------------------------------
  // Full and Empty flags
  //------------------------------------------------
  assign full  = 
         (wr_ptr[FIFO_PTR_WIDTH-1] ^ rd_ptr[FIFO_PTR_WIDTH-1]) 
       & (wr_ptr[FIFO_PTR_WIDTH-2:0] == rd_ptr[FIFO_PTR_WIDTH-2:0]);
  assign empty = (wr_ptr == rd_ptr);

  //------------------------------------------------
  // Operation Counter
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      operation_count <= {FIFO_PTR_WIDTH{1'b0}};
    else if (write & !full)
        operation_count <= operation_count + 1'b1;
      else if (read & !empty) 
        operation_count <= operation_count - 1'b1;
  end

  //------------------------------------------------
  // Almost Full and Almost Empty flags
  //------------------------------------------------
  assign almost_full  = 
         (operation_count < (FIFO_DEPTH - ALMOSTFULL_DEPTH)) 
       ? 1'b0 : 1'b1;
  assign almost_empty = 
         (operation_count < ALMOSTEMPTY_DEPTH) ? 1'b1 : 1'b0;

  //-----------------------------------------------
  // FIFO Write
  //-----------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      fifo_array[wr_ptr] <= {FIFO_DATA_WIDTH{1'b0}};
    else if (write & !full)
      fifo_array[wr_ptr[FIFO_PTR_WIDTH-2:0]] <= write_data;
  end

  //-----------------------------------------------
  // FIFO Read
  //-----------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      read_data <= {FIFO_DATA_WIDTH{1'b0}};
    else if (read & !empty)
      read_data <= fifo_array[rd_ptr[FIFO_PTR_WIDTH-2:0]];
  end

endmodule