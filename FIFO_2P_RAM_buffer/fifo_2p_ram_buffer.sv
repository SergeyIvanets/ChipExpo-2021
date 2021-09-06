`include "fifo_simple_DP_RAM.sv"
`include "fsm_fifo.sv"
`include "fifo_reg_file.sv"

`timescale 1 ns / 1 ns
`default_nettype none 

module fifo_2p_ram_buffer
#(
  parameter   FIFO_RAM_DEPTH     = 256, // depth for RAM FIFO
              FIFO_DATA_WIDTH    = 8,
              ALMOST_FULL_DEPTH  = 2,
              ALMOST_EMPTY_DEPTH = 2,
              LATENCY            = 3, // min value 2
              BUFFER_DEPTH       = 8  // min LATENCY + 3 
)

(
  input wire                           clk,
  input wire                           reset,

  input wire                           write,
  input wire                           read,

  input wire     [FIFO_DATA_WIDTH-1:0] write_data,
  output wire    [FIFO_DATA_WIDTH-1:0] read_data,

  output wire                          empty,
  output wire                          full,
  output wire                          almost_empty,
  output wire                          almost_full
);

  localparam FIFO_PTR_WIDTH    = $clog2(FIFO_RAM_DEPTH) + 1;
  localparam BUF_CREDIT_COUNT  = $clog2(BUFFER_DEPTH); 
  logic [FIFO_PTR_WIDTH-1:0]       credit_count_module;
  logic [BUF_CREDIT_COUNT-1:0]     credit_count_buffer;

  //------------------------------------------------
  // Modules
  //------------------------------------------------
  
  // RAM FIFO 
  logic                         write_ram;
  logic                         read_ram;
  logic   [FIFO_DATA_WIDTH-1:0] read_data_ram;
  logic                         empty_ram;
  logic                         full_ram;

  fifo_simple_DP_RAM 
  # (.FIFO_DEPTH              (FIFO_RAM_DEPTH             ),
     .FIFO_DATA_WIDTH         (FIFO_DATA_WIDTH            ),
     .ALMOST_FULL_DEPTH       (ALMOST_FULL_DEPTH          ),
     .ALMOST_EMPTY_DEPTH      (ALMOST_EMPTY_DEPTH         ),
     .LATENCY                 (LATENCY                    )
  )
  fifo_ram
  (
    .clk                      (clk                        ),
    .reset                    (reset                      ),
    .write                    (write_ram                  ),
    .read                     (read_ram                   ),
    .write_data               (write_data                 ),
    .read_data                (read_data_ram              ),
    .empty                    (empty_ram                  ),
    .full                     (full_ram                   )
  );


  // Buffer FIFO
  logic                         write_buf;
  logic                         read_buf;
  logic   [FIFO_DATA_WIDTH-1:0] write_data_buf;
  logic   [FIFO_DATA_WIDTH-1:0] read_data_buf;
  logic                         empty_buf;
  logic                         full_buf;
  logic                         full_buf_credit;

  fifo_reg_file 
  # (.FIFO_DEPTH              (BUFFER_DEPTH               ),
     .FIFO_DATA_WIDTH         (FIFO_DATA_WIDTH            )
  )
  fifo_buf
  (
    .clk                      (clk                        ),
    .reset                    (reset                      ),
    .write                    (write_buf                  ),
    .read                     (read_buf                   ),
    .write_data               (write_data_buf             ),
    .read_data                (read_data_buf              ),
    .empty                    (empty_buf                  ),
    .full                     (full_buf                   )
  );

  // FSM FIFO
  logic                         fsm_write_buf;
  logic                         fsm_read_buf;
  logic                         fsm_write_ram;
  logic                         fsm_read_ram;
  logic                         storage_sel;

  fsm_fifo 
  # (.FIFO_PTR_WIDTH           (FIFO_PTR_WIDTH             ),
     .BUF_CREDIT_COUNT         (BUF_CREDIT_COUNT           ),
     .LATENCY                  (LATENCY                    )
  )

  fsm_fifo_i
  (
    .clk                       (clk                         ),
    .reset                     (reset                       ),
    .empty_buf                 (empty_buf                   ),
    .full_buf                  (full_buf_credit             ),
    .empty_ram                 (empty_ram                   ),
    .full_ram                  (full_ram                    ),
    .write                     (write                       ),
    .read                      (read                        ),
    .credit_count              (credit_count_module         ),
    .fsm_write_buf             (fsm_write_buf               ),
    .fsm_read_buf              (fsm_read_buf                ),
    .fsm_write_ram             (fsm_write_ram               ),
    .fsm_read_ram              (fsm_read_ram                ),
    .storage_sel               (storage_sel                 )
  );

  //------------------------------------------------
  // Read and write logic
  //------------------------------------------------
  logic write_buf_lat [LATENCY - 1:0];
  int i;

  always @ (posedge clk)
  begin
    write_buf_lat [0] <= #1 read_ram & fsm_write_buf;
    for (i = 1; i < LATENCY - 1; i = i + 1)
      write_buf_lat [i] <= #1 write_buf_lat [i - 1];
  end

  assign write_buf = storage_sel ?  write_buf_lat [LATENCY - 2]: write & fsm_write_buf;
  assign read_buf  = read & fsm_read_buf;
  assign write_ram = write & fsm_write_ram;
  assign read_ram  = fsm_read_ram & (credit_count_buffer < {BUF_CREDIT_COUNT{1'b1}});

  //------------------------------------------------
  // Data mux
  //------------------------------------------------
  assign write_data_buf = storage_sel ? read_data_ram : write_data;
  
  //------------------------------------------------
  // Full and Empty flags
  //------------------------------------------------
  assign full  = /*full_buf_credit & */full_ram;
  assign empty = empty_buf & empty_ram;
  
  //------------------------------------------------
  // Credit Counter for module
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      credit_count_module <= #1 {FIFO_PTR_WIDTH{1'b0}};
    else
      casex ({read, write, full, empty})
        4'b10x0: credit_count_module <= #1 credit_count_module - 1'b1; 
        4'b010x: credit_count_module <= #1 credit_count_module + 1'b1;
        4'b1101: credit_count_module <= #1 credit_count_module + 1'b1;
        4'b1110: credit_count_module <= #1 credit_count_module - 1'b1;
        4'b1100: credit_count_module <= #1 credit_count_module;
        4'b00xx: credit_count_module <= #1 credit_count_module;
        default: credit_count_module <= #1 credit_count_module;
      endcase  
  end

  //------------------------------------------------
  // Credit Counter for buffer
  //------------------------------------------------
  always @ (posedge clk)
  begin
    if (reset)
      credit_count_buffer <= #1 {BUF_CREDIT_COUNT{1'b0}};
    else 

  // buffer empty  
    if (credit_count_buffer == 0) begin
      case ({read, (write | fsm_read_ram)})
        2'b00  : credit_count_buffer <= #1 credit_count_buffer;
        2'b01  : credit_count_buffer <= #1 credit_count_buffer + 1'b1;  // write
        2'b10  : credit_count_buffer <= #1 credit_count_buffer;
        2'b11  : credit_count_buffer <= #1 credit_count_buffer + 1'b1;  //only write, not read
        default: credit_count_buffer <= #1 credit_count_buffer;
      endcase
      full_buf_credit <= #1 1'b0;
    end

  // full buffer
    else if (credit_count_buffer == {BUF_CREDIT_COUNT{1'b1}}) 
      case ({read, (write | fsm_read_ram)})
        2'b00  : begin
                  credit_count_buffer <= #1 credit_count_buffer;        // still full
                  full_buf_credit     <= #1 1'b1;
        end
        2'b01  : begin
                  credit_count_buffer <= #1 credit_count_buffer;        // full, not write
                  full_buf_credit     <= #1 1'b1;
        end

        2'b10  : begin
                  credit_count_buffer <= #1 credit_count_buffer - 1'b1;  // read
                  full_buf_credit     <= #1 1'b0;                        // not full
        end

        2'b11  : begin
                  credit_count_buffer <= #1 credit_count_buffer - 1'b1;  // read buffer and  write memory
                  full_buf_credit     <= #1 1'b0;                        // not full
        end

        default: begin
                  credit_count_buffer <= #1 credit_count_buffer;
                  full_buf_credit     <= #1 1'b0;                        // not full
        end
      endcase

    // buffer not full not empty
    else begin  
      case ({read, (write & ~storage_sel) | fsm_read_ram})
        2'b00: begin  
                credit_count_buffer <= #1 credit_count_buffer; 
                full_buf_credit     <= #1 1'b0;
        end

        2'b01: begin
                credit_count_buffer <= #1 credit_count_buffer + 1'b1;
                if (credit_count_buffer + 1 == {BUF_CREDIT_COUNT{1'b1}})
                  full_buf_credit     <= #1 1'b1;
                else
                  full_buf_credit     <= #1 1'b0; 
        end  

        2'b10: begin
                credit_count_buffer <= #1 credit_count_buffer - 1'b1;
                full_buf_credit     <= #1 1'b0;
        end

        2'b11: begin  
                credit_count_buffer <= #1 credit_count_buffer;
                full_buf_credit     <= #1 1'b0;
        end

        default: begin
                  credit_count_buffer <= #1 credit_count_buffer;
                  full_buf_credit     <= #1 1'b0;
        end

      endcase  
    end    
  end

  //------------------------------------------------
  // Almost Full and Almost Empty flags
  //------------------------------------------------
  assign almost_full  = (credit_count_module < (FIFO_RAM_DEPTH + BUFFER_DEPTH - ALMOST_FULL_DEPTH)) 
                          ? 1'b0 : 1'b1;
  assign almost_empty = (credit_count_module < ALMOST_EMPTY_DEPTH) ? 1'b1 : 1'b0;

  assign read_data = read_data_buf;  
  
endmodule