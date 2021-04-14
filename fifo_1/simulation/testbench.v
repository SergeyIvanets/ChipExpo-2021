// Write to FIFO
//{signal: [
//  {name: "clk", wave: "n.........."},
//  ['in',
//    {name: "rst",        wave: "01........."},
//    {name: "write",      wave: "0.101010101"},
//    {name: "read",       wave: "0.........."},
//    {name: "write_data", wave: "3.4.5.6.7.", data: ["00", "11", "22", "33", "44"]},
//    {name: "read_data",  wave: "3.........", data: ["00"]}
//  ],
//    {},
//  ['out',
//   {name: "empty",      wave: '1..0.......', phase: 0.5},
//   {name: "full",       wave: '0.........'}
//  ]
//],
// config: {hscale: 1}
//}


`timescale 1ns/1ps

module testbench;

  parameter FIFO_PTR_WIDTH   = 3;
  parameter FIFO_DATA_WIDTH  = 8;

  // simulation options
  parameter clock_period      = 20;
  
  reg                        clk;
  wire                       clk_enable;
  reg                        reset;

  reg                        write;
  reg                        read;

  reg  [FIFO_DATA_WIDTH-1:0] write_data;
  wire [FIFO_DATA_WIDTH-1:0] read_data;

  wire                       empty;
  wire                       full;
  
  integer i;

fifo_simple i_fifo_simple 
(
  .clk          ( clk          ), 
  .clk_enable   ( clk_enable   ), 
  .reset        ( reset        ), 
  .write        ( write        ), 
  .read         ( read         ), 
  .write_data   ( write_data   ), 
  .read_data    ( read_data    ), 
  .empty        ( empty        ), 
  .full         ( full         )
);

initial
  begin
    clk = 1'b0;
    forever # (clock_period / 2) clk = ~ clk;
  end 

assign clk_enable = 1'b1;

task reset_task ();
  begin
    clk        = 1'b0;
    reset      = 1'b1;
    write      = 1'b0;
    read       = 1'b0;
    write_data = 0;
    repeat (2)  @ (posedge clk);    
    reset = 1'b0;
  end
endtask

task read_fifo ();
  begin
    read = 1'b1;
    # clock_period;
    read = 1'b0;
  end
endtask
   
task write_fifo ([7:0] data);
  begin
    write = 1'b1;
    write_data = data;
    # clock_period write = 1'b0;
  end
endtask


initial
  begin
    reset_task ();
    # (clock_period * 1.5);

    // Write to FIFO

    for (i = 0; i <8; i = i + 1)
    begin
      write_fifo (i);
      # clock_period;
    end 

    // Read from FIFO
    
    repeat (6)
      begin
        read_fifo ();
        # clock_period;
      end
    # clock_period;
    $finish;
 end

endmodule