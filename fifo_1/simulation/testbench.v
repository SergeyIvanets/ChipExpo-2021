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

fifo_simple DUT (
    clk, clk_enable, reset, 
    write, read, 
    write_data, read_data, 
    empty, full
);


always #10 clk = ~clk;

assign clk_enable = 1'b1;

task reset_task();
  begin
    clk        = 1'b0;
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
    reset_task();
    #30;
    for (i = 0; i <8; i = i + 1)
    begin
      write_fifo(i);
      #20;
    end 

    repeat(6)
      begin
        read_fifo();
        #20;
      end
    #10;
    $finish;
 end

endmodule