`timescale 1ns/1ps

module testbench;

  parameter FIFO_DEPTH         = 32;
  parameter FIFO_DATA_WIDTH    = 8;
  parameter ALMOST_FULL_DEPTH  = 3;
  parameter ALMOST_EMPTY_DEPTH = 3;
  parameter LATENCY            = 3;

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
  parameter clock_period      = 20;

FIFO_simple_DP_RAM  
# (.FIFO_DEPTH         ( FIFO_DEPTH                ),
   .FIFO_DATA_WIDTH    ( FIFO_DATA_WIDTH           ),
   .ALMOST_FULL_DEPTH  ( ALMOST_FULL_DEPTH         ),
   .ALMOST_EMPTY_DEPTH ( ALMOST_EMPTY_DEPTH        ),
   .LATENCY            ( LATENCY                   )
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
    forever # (clock_period / 2) clk = ~ clk;
  end 

task reset_task();
  begin
    reset      = 1'b1;
    write      = 1'b0;
    read       = 1'b0;
    write_data = 0;
    # (2 * clock_period);
    reset = 1'b0;
  end
endtask

task read_fifo();
  begin
    read = 1'b1;
    # clock_period;
    read = 1'b0;
  end
endtask
   
task write_fifo ([7:0]data);
  begin
    write = 1'b1;
    write_data = data;
    # clock_period;
    write = 1'b0;
  end
endtask

task read_during_write ([7:0]data, delay_L, delay_H);
  begin
    write = 1'b1;
    write_data = data;
    read = 1'b1;
    # delay_H;
    read = 1'b0;
    write = 1'b0;
    # delay_L;
  end
endtask

initial
  begin
  //------------------------------------------------
  // reset FIFO operation counter and pointers
  //------------------------------------------------
    reset_task ();
    # (2 * clock_period);


  //------------------------------------------------
  // write FIFO until full and
  // read until empty
  // MSF = 0
  //------------------------------------------------
    for (i = 0; i <40; i = i + 1)
    begin
      write_fifo (i);
      # clock_period;
    end 

    repeat (40)
      begin
        read_fifo ();
      # clock_period;
      end

    # clock_period;
  //------------------------------------------------
  // write FIFO until full and
  // read until empty
  // MSF = 1
  //------------------------------------------------
    for (i = 0; i <40; i = i + 1)
    begin
      write_fifo (i + 32);
      # clock_period;
    end 

    repeat (40)
      begin
        read_fifo ();
        # clock_period;
      end
    # clock_period;


  //------------------------------------------------
  // read during write
  // read pointer != write pointer
  //------------------------------------------------
    for (i = 0; i <3; i = i + 1)
    begin
      write_fifo (i + 48);
      # clock_period;
    end 

    for (i = 0; i <67; i = i + 1)
    begin
      read_during_write (i + 48 + 3, clock_period, clock_period);
    end 


  //------------------------------------------------
  // read during write
  // read pointer = write pointer
  //------------------------------------------------
    reset_task ();
    # (2 * clock_period);

    for (i = 0; i <70; i = i + 1)
    begin
      read_during_write (i + 128, (clock_period * 2), clock_period);
    end 

    #10;

    $finish;
 end

endmodule