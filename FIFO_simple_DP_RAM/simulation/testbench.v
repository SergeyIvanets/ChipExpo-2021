`timescale 1ns/1ps

module testbench;

  parameter FIFO_DEPTH         = 32;
  parameter FIFO_DATA_WIDTH    = 8;
  parameter ALMOST_FULL_DEPTH  = 3;
  parameter ALMOST_EMPTY_DEPTH = 3;


  reg                        clk;
  reg                        reset;

  reg                        write;
  reg                        read;

  reg  [FIFO_DATA_WIDTH-1:0] write_data;
  wire [FIFO_DATA_WIDTH-1:0] read_data;

  wire                       empty;
  wire                       full;
  wire                       almost_empty;
  wire                       almost_full;

  integer i;

FIFO_simple_DP_RAM  
# (.FIFO_DEPTH         ( FIFO_DEPTH                ),
   .FIFO_DATA_WIDTH    ( FIFO_DATA_WIDTH           ),
   .ALMOST_FULL_DEPTH  ( ALMOST_FULL_DEPTH         ),
   .ALMOST_EMPTY_DEPTH ( ALMOST_EMPTY_DEPTH        )
)
i_FIFO_simple_DP_RAM
(
    .clk               ( clk                       ),
    .reset             ( reset                     ), 
    .write             ( write                     ),
    .read              ( read                      ),
    .write_data        ( write_data                ),
    .read_data         ( read_data                 ),
    .empty             ( empty                     ),
    .full              ( full                      ),
    .almost_empty      ( almost_empty              ),
    .almost_full       ( almost_full               )
);

initial
  begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end 

task reset_task();
  begin
    reset      = 1'b1;
    write      = 1'b0;
    read       = 1'b0;
    write_data = 0;
    #40; reset = 1'b0;
  end
endtask

task read_fifo();
  begin
    read = 1'b1;
    #20;
    read = 1'b0;
  end
endtask
   
task write_fifo([7:0]data);
  begin
    write = 1'b1;
    write_data = data;
    #20 write = 1'b0;
  end
endtask

initial
  begin
    reset_task ();
    #30;
    for (i = 0; i <40; i = i + 1)
    begin
      write_fifo (i);
      #20;
    end 

    repeat (40)
      begin
        read_fifo();
        #20;
      end

    #10;
    for (i = 0; i <40; i = i + 1)
    begin
      write_fifo (i+32);
      #20;
    end 

    repeat (40)
      begin
        read_fifo ();
        #20;
      end
    #10;
    $finish;
 end

endmodule