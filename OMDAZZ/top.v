module top
# (
  parameter CLK_50MHz       = 50000000,
            FIFO_DEPTH      = 4,
            FIFO_DATA_WIDTH = 8
)
(
  input        clk,
  input        reset_n,
    
  input  [3:0] key_sw,
  output [3:0] led,

  output [7:0] abcdefgh,
  output [3:0] digit,

  output       hsync,
  output       vsync,
  output [2:0] rgb
);

  wire       fifo_read_data; 
  wire       clk_1Hz_enable;
  wire       reset;  
  wire [3:0] 7seg_digit;      // regs for 7 seg digit code
  wire       7seg_enable;     // enable to shift active digit
  reg  [3:0] shift_reg;       // shift reg for 7 seg digit

  sync_and_debounce
  # (
      w     = 4,
      depth = 8
  )
  i_sync_and_debounce
  (
    .clk     ( clk            ), 
    .reset   ( reset          ),
    .sw_in   ( key_sw         ),
    .sw_out  ( key_sync       ) 
  )

  clock_divider
  # (
    .CLK_INPUT  (CLK_50MHz),
    .CLK_OUTPUT (1)
  )
  i_clock_divider_1sec
  (
    .clk     ( clk            ), 
    .reset   ( reset          ),
    .clk_div ( 7seg_enable    )
  );

  clock_divider
  # (
    .CLK_INPUT  (CLK_50MHz),
    .CLK_OUTPUT (50)
  )
  i_clock_divider_50Hz
  (
    .clk     ( clk            ), 
    .reset   ( reset          ),
    .clk_div ( clk_1Hz_enable )
  );

  always @ (posedge clk)
    if (reset)
      shift_reg <= 4'b0001;
    else if (7seg_enable)
      shift_reg <= { shift_reg [0], shift_reg [3:1] };


  fifo_simple
  # (
      .FIFO_DEPTH (FIFO_DEPTH),
      .FIFO_DATA_WIDTH (FIFO_DATA_WIDTH)
  )
  i_fifo_simple
  (
    .clk        ( CLK_50MHz                       ),
    .clk_enable ( clk_1Hz_enable                  ),
    .reset      ( ~ reset_n                       ),

    .write      ( key_sync[3]                     ),
    .read       ( key_sync[2]                     ),

    .write_data (
                 {(FIFO_DATA_WIDTH/2){key_sw[1]},
                  (FIFO_DATA_WIDTH/2){key_sw[0]}                       }
                                                  ),
    .read_data  ( 7seg_digit[1], 7seg_digit[0]    ),
    .empty      ( led[3]                          ),
    .full       ( led[2]                          )
  );

endmodule
