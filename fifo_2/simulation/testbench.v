`timescale 1ns/1ps

module testbench;

  parameter FIFO_DEPTH        = 8;
  parameter FIFO_DATA_WIDTH   = 8;
  parameter ALMOSTFULL_DEPTH  = 3;
  parameter ALMOSTEMPTY_DEPTH = 3;


  reg                        clk;
  wire                       clk_enable;
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

fifo_generic DUT (
    clk, clk_enable, reset, 
    write, read, 
    write_data, read_data, 
    empty, full,
    almost_empty, almost_full
);

initial
  begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end 

assign clk_enable = 1'b1;

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
    reset_task();
    #30;
    for (i = 0; i <10; i = i + 1)
    begin
      write_fifo(i);
      #20;
    end 

    repeat(10)
      begin
        read_fifo();
        #20;
      end
    #10;
    $finish;
 end

endmodule