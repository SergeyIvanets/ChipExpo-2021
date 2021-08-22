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
  localparam FIFO_PTR_WIDTH   = $clog2(FIFO_DEPTH) + 1;
  
  reg   [FIFO_DATA_WIDTH - 1:0] tmp_data [LATENCY - 1:0];


FIFO_simple_DP_RAM  
# (.FIFO_DEPTH         ( FIFO_DEPTH                ),
   .FIFO_DATA_WIDTH    ( FIFO_DATA_WIDTH           ),
   .ALMOST_FULL_DEPTH  ( ALMOST_FULL_DEPTH         ),
   .ALMOST_EMPTY_DEPTH ( ALMOST_EMPTY_DEPTH        ),
   .LATENCY            ( LATENCY                   )
)

i_fifo
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

//-----------------------------------------------------//
// ------------- Clock, reset, tasks ------------------//
  
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
    repeat (2)  @ (posedge clk);    
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
   
task write_fifo ([FIFO_DATA_WIDTH-1:0] data);
  begin
    write = 1'b1;
    write_data = data;
//    $display ("Write data=%h", data);
    # clock_period 
    write = 1'b0;
  end
endtask

task none_fifo ();
  begin
    read = 1'b0;
    write = 1'b0;
    # clock_period;
  end
endtask

// read during write 
task read_write_fifo ([FIFO_DATA_WIDTH-1:0] data);
  begin
    write = 1'b1;
    write_data = data;
    read = 1'b1;
//    $display ("Write data=%h", data);
    # clock_period 
    write = 1'b0;
    read = 1'b0;
  end
endtask

//-----------------------------------------------------//
// ----------------- Simulation -----------------------//

initial
begin
/*
  $dumpfile("test.vcd");
  $dumpvars(0, testbench);

  $monitor ("T = %4d, write = %h, read = %h, write_data = %h, read_data = %h, queue_FIFO [0] = %h, empty = %h, full = %h, almost_empty = %h, almost_full = %h, i_fifo.rd_ptr = %h, i_fifo.wr_ptr = %h", 
            $stime, write, read, write_data, read_data, queue_FIFO [0], empty, full, almost_empty, almost_full, i_fifo.rd_ptr, i_fifo.wr_ptr);
*/

//-----------------------------------------------------//
// ------------- Full amd empty test ------------------//

    reset_task ();
  # (1.5 * clock_period);
    
  // write FIFO until full and read until empty
  // MSF = 0
  for (i = 0; i < (FIFO_DEPTH + 1); i = i + 1)
  begin
    write_fifo (i);
    # clock_period;
  end 

  repeat (FIFO_DEPTH + 1)
  begin
    read_fifo ();
    # clock_period;
  end
 
  # clock_period;
  
  // write FIFO until full and read until empty
  // MSF = 1
  for (i = 0; i < (FIFO_DEPTH + 1); i = i + 1)
  begin
    write_fifo (i + FIFO_DEPTH);
    # clock_period;
  end 

  // Read from FIFO
  
  repeat (FIFO_DEPTH + 1)
  begin
    read_fifo ();
    # clock_period;
  end
 
  # clock_period;
  
  // read and write
  // read pointer != write pointer
  for (i = 0; i < ALMOST_EMPTY_DEPTH * 2; i = i + 1)
  begin
    write_fifo (i + FIFO_DEPTH * 2 );
    # clock_period;
  end 
    
  repeat (ALMOST_EMPTY_DEPTH * 2)
  begin
    read_fifo ();
    # clock_period;
  end

// ------------ End Full amd empty test ---------------//  

//-----------------------------------------------------//
// ------------- Speed read/write test ----------------//   

  $display ("\n    ------------- Speed read/write test ----------------\n");
  reset_task ();
  # (clock_period * 1.5);
    
  
  // Write to FIFO
  
  write = 1'b1;
  # clock_period;
  for (i = 0; i < (FIFO_DEPTH-1); i = i + 1)
  begin
    write_data = i;
//    $display ("Write data=%h", write_data);
    # clock_period;
  end 
  write = 1'b0;
  
  // Read from FIFO
  
  read = 1'b1;
  # clock_period ;
  repeat (FIFO_DEPTH)
    # clock_period;
  read = 1'b0;    
// ----------- End Speed read/write test --------------//     


$finish;
end

endmodule