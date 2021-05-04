module FIFO_simple_DP_RAM
#(
  parameter   FIFO_DEPTH        = 256,
              FIFO_DATA_WIDTH   = 8,
              ALMOST_FULL_DEPTH  = 2,
              ALMOST_EMPTY_DEPTH = 2,
              LATENCY            = 1  // min value 1
)
(
  input                            clk,
  input                            reset,

  input                            write,
  input                            read,

  input      [FIFO_DATA_WIDTH-1:0] write_data,
  output     [FIFO_DATA_WIDTH-1:0] read_data,

  output                           empty,
  output                           full,
  output                           almost_empty,
  output                           almost_full
);

  localparam FIFO_PTR_WIDTH   = $clog2(FIFO_DEPTH) + 1;
  localparam ALMOST_FULL_VALUE = FIFO_DEPTH - ALMOST_FULL_DEPTH;
  
  reg    [FIFO_PTR_WIDTH-1:0]  rd_ptr;
  reg    [FIFO_PTR_WIDTH-1:0]  wr_ptr;
  reg    [FIFO_PTR_WIDTH-1:0]  operation_count;

  reg                          write_enable;
  reg  [FIFO_DATA_WIDTH - 1:0] read_data_int [LATENCY - 1:0];
  wire   [FIFO_DATA_WIDTH-1:0] read_data_wire;

  integer i;
  
  simple_dual_port_RAM 
  # (.DATA_WIDTH  ( FIFO_DATA_WIDTH                  ),
     .ADDR_WIDTH  ( FIFO_PTR_WIDTH                   )
  )
  fifo_array
  (
    .write_enable ( write_enable                     ),
    .clk          ( clk                              ),
    .read_addr    ( rd_ptr                           ),
    .data_in      ( write_data                       ),
    .write_addr   ( wr_ptr                           ),
    .data_out     ( read_data_wire                   )
  );

  //------------------------------------------------
  // Write Pointer Logic
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      begin
        wr_ptr          <= {FIFO_PTR_WIDTH{1'b0}};
        write_enable    <= 1'b0;
      end
    else if (write & !full)
        begin
          wr_ptr        <= wr_ptr + 1'b1;
          write_enable  <= 1'b1;      
        end
      else
        write_enable    <= 1'b0;
    end

  //------------------------------------------------
  // Read Pointer Logic
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      rd_ptr   <= {FIFO_PTR_WIDTH{1'b0}};
    else if ((write & read & empty) | (read & !empty))
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
    else if (write & read & empty)
      operation_count <= operation_count;
      else if (write & !full)
        operation_count <= operation_count + 1'b1;
        else if (read & !empty) 
          operation_count <= operation_count - 1'b1;
  end

  //------------------------------------------------
  // Almost Full and Almost Empty flags
  //------------------------------------------------
  assign almost_full  = (operation_count < (FIFO_DEPTH - ALMOST_FULL_DEPTH)) 
                          ? 1'b0 : 1'b1;
  assign almost_empty = (operation_count < ALMOST_EMPTY_DEPTH) ? 1'b1 : 1'b0;

  //------------------------------------------------
  // Latency for output
  // Number of clock cycles = LATENCY
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      for (i = 0; i < LATENCY; i = i + 1)
        read_data_int [i] <= {FIFO_DATA_WIDTH{1'b0}};
    else 
      begin
        read_data_int [0] <= read_data_wire;
        for (i = 1; i < LATENCY; i = i + 1)
          read_data_int [i] <= read_data_int [i - 1];
      end
  end

  assign read_data = read_data_int [LATENCY - 1];

endmodule