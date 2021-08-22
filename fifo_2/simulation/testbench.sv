`timescale 1ns/100ps

module testbench;

  parameter FIFO_DEPTH        = 16;
  parameter FIFO_DATA_WIDTH   = 8;
  parameter ALMOST_FULL_DEPTH  = 3;
  parameter ALMOST_EMPTY_DEPTH = 3;

  // simulation options
  parameter clock_period      = 20;

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
  localparam FIFO_PTR_WIDTH   = $clog2(FIFO_DEPTH) + 1;
  
 // logic [FIFO_PTR_WIDTH : 0] v;
  //assign v = {1'b1, {FIFO_PTR_WIDTH{1'b0}}};

  // covergroup
  // mode - FIFO mode
  // mode = {read, write}
  logic [1:0] mode;

  covergroup cg_rw @(posedge clk);
    option.at_least = FIFO_DEPTH * 2;
    coverpoint mode {
      bins mode_none   = {2'b00};
      bins mode_wr     = {2'b01};
      bins mode_rd     = {2'b10};
      bins mode_wr_rd  = {2'b11};
    }
  endgroup

  cg_rw cg = new;


  // Queue for storage FIFO data
  logic [FIFO_DATA_WIDTH-1:0] queue_FIFO [$];
  logic [FIFO_DATA_WIDTH-1:0] expected_o_data;


fifo_generic 
  #(FIFO_DEPTH, 
    FIFO_DATA_WIDTH,
    ALMOST_FULL_DEPTH,
    ALMOST_EMPTY_DEPTH
  )  
i_fifo
(
  .clk          ( clk          ), 
  .reset        ( reset        ), 
  .write        ( write        ), 
  .read         ( read         ), 
  .write_data   ( write_data   ), 
  .read_data    ( read_data    ), 
  .empty        ( empty        ), 
  .full         ( full         ),
  .almost_empty ( almost_empty ), 
  .almost_full  ( almost_full  )
);

//-----------------------------------------------------//
// ------------- Clock, reset, tasks ------------------//
  
initial
  begin
    clk = 1'b0;
    forever # (clock_period / 2) clk = ~ clk;
  end 

task reset_task ();
  begin
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

  $dumpfile("test.vcd");
  $dumpvars(0, testbench);
  /*
  $monitor ("T = %4d, write = %h, read = %h, write_data = %h, read_data = %h, queue_FIFO [0] = %h, empty = %h, full = %h, almost_empty = %h, almost_full = %h, i_fifo.rd_ptr = %h, i_fifo.wr_ptr = %h", 
            $stime, write, read, write_data, read_data, queue_FIFO [0], empty, full, almost_empty, almost_full, i_fifo.rd_ptr, i_fifo.wr_ptr);
*/
//-----------------------------------------------------//
// ------------- Full amd empty test ------------------//

$display ("\n    ------------- Full amd empty test ----------------\n");
  reset_task ();
  # (clock_period * 1.5);
    
  
  // Write to FIFO
  for (i = 0; i < (FIFO_DEPTH + 1); i = i + 1)
  begin
    write_fifo ($urandom_range (FIFO_DATA_WIDTH-1, 0));
    # clock_period;
  end 

  // Read from FIFO
  
  repeat (FIFO_DEPTH + 1)
  begin
    read_fifo ();
    # clock_period;
  end
    
  // Write to FIFO

  for (i = 0; i < (FIFO_DEPTH + 1); i = i + 1)
  begin
    write_fifo ($urandom_range (FIFO_DATA_WIDTH-1, 0));
    # clock_period;
  end 

  // Read from FIFO
  
  repeat (FIFO_DEPTH + 1)
  begin
    read_fifo ();
    # clock_period;
  end
 
  # clock_period;
  
  // Write to FIFO

  for (i = 0; i < ALMOST_EMPTY_DEPTH * 2; i = i + 1)
  begin
    write_fifo ($urandom_range (FIFO_DATA_WIDTH-1, 0));
    # clock_period;
  end 

  // Read from FIFO
    
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
    write_data = $urandom_range (FIFO_DATA_WIDTH-1, 0);
//    $display ("Write data=%h", write_data);
    # clock_period;
  end 
  write = 1'b0;
  
  // Read from FIFO
  
  read = 1'b1;
  # clock_period;
  repeat (FIFO_DEPTH)
    # clock_period;
  read = 1'b0;    
// ----------- End Speed read/write test --------------//     

//-----------------------------------------------------//
// ----------------- Coverage test --------------------//   

  $display ("\n    ----------------- Coverage test --------------------\n");
  reset_task ();
  # (clock_period * 1.5);  

  while (cg.get_coverage () < 100.0) 
  begin
    mode = $urandom_range (3, 0);
    casex (mode)
      2'b00  : none_fifo ();
      2'b01  : begin
                write_fifo ($urandom_range (FIFO_DATA_WIDTH-1, 0));
                # clock_period;
              end
      2'b10  : begin
                read_fifo ();
                # clock_period;
              end
      2'b11  : begin
                read_write_fifo ($urandom_range (FIFO_DATA_WIDTH-1, 0));
                # clock_period;
              end  
      default: none_fifo ();
    endcase
  end;
  $display("Coverage = %0.2f %%", cg.get_inst_coverage ());

// --------------- End Coverage test ------------------//    
  # clock_period;
  $finish;
 end
  
  
//-----------------------------------------------------//
// -------------------- Queues ------------------------//  
  
always @ (posedge clk)
begin
  if (write & !full)
 
    queue_FIFO.push_back (write_data);
end

always @ (negedge clk)
begin
  if (read & !empty)
  begin
    expected_o_data = repeat(1) @(negedge clk) queue_FIFO [0];
    if (i_fifo.read_data != expected_o_data)
      $error ("Data mismatch: read_data %h != expected_o_data %h",
        i_fifo.read_data, expected_o_data);
  end
end

always @ (posedge clk)
begin
  if (read & !empty)
    void' (queue_FIFO.pop_front ());
end
  

//-----------------------------------------------------//
// --------------Design assertions --------------------//

// Read pointer check without overflow
property p_rd_ptr_normal;
  @(posedge clk) disable iff (reset)
  read && !empty && ($countones (i_fifo.rd_ptr[FIFO_PTR_WIDTH-2:0] ) != (FIFO_PTR_WIDTH - 1))
    |=> (i_fifo.rd_ptr == $past(i_fifo.rd_ptr) + 1);
endproperty: p_rd_ptr_normal
  
  a_p_rd_ptr_normal: assert property (p_rd_ptr_normal)
  else $error("Read failed: ", $time);
   
// Read pointer check with overflow
property p_rd_ptr_overflow;
  @(posedge clk) disable iff (reset)
  read && !empty && ($countones (i_fifo.rd_ptr[FIFO_PTR_WIDTH-2:0]) == (FIFO_PTR_WIDTH - 1))
    |=> (!i_fifo.rd_ptr);
endproperty: p_rd_ptr_overflow
  
a_p_rd_ptr_overflow: assert property (p_rd_ptr_overflow)
  $info ("Read pointer overflow to %b: at ", i_fifo.rd_ptr, $time);
  else $error("Read pointer overflow from %b to %b with failed: at", $past(i_fifo.rd_ptr), i_fifo.rd_ptr, $time);
  
// Read pointer empty check
property p_rd_stable;
  @(posedge clk) disable iff(reset)
  read && empty |=> (i_fifo.rd_ptr == $past(i_fifo.rd_ptr));
endproperty:p_rd_stable

a_p_rd_stable: assert property (p_rd_stable)
    $warning("Read when empty: ", $time);
  else $error("Incorrect read when empty : ", $time); 
   
// Write pointer check without overflow
property p_wr_ptr_normal;
  @(posedge clk) disable iff (reset)
  write && !full && ($countones (i_fifo.wr_ptr[FIFO_PTR_WIDTH-2:0] ) != (FIFO_PTR_WIDTH - 1))
    |=> (i_fifo.wr_ptr == ($past(i_fifo.wr_ptr) + 1));
endproperty:p_wr_ptr_normal
  
a_p_wr_ptr_normal: assert property (p_wr_ptr_normal)
  else $error("Write failed: ", $time);

// Write pointer check with overflow
property p_wr_ptr_overflow;
  @(posedge clk) disable iff (reset)
  write && !full && ($countones (i_fifo.wr_ptr[FIFO_PTR_WIDTH-2:0]) == (FIFO_PTR_WIDTH - 1))
  |=> (!i_fifo.wr_ptr);
endproperty:p_wr_ptr_overflow
  
a_p_wr_ptr_overflow: assert property (p_wr_ptr_overflow)
  $info ("Write pointer overflow to %b: at ", i_fifo.wr_ptr, $time);
  else $error("Write pointer overflow from %b to %b with failed: at", $past(i_fifo.wr_ptr), i_fifo.wr_ptr, $time);
  
// Write pointer full check
property p_wr_stable;
  @(posedge clk) disable iff (reset)
    write && full |=> (i_fifo.wr_ptr == $past(i_fifo.wr_ptr));
endproperty:p_wr_stable

a_p_wr_stable: assert property (p_wr_stable)
    $warning ("Write when full: ", $time);
  else $error("Incorrect Write when full: ", $time);
  
// Reset check for pointers
property p_rst_ptr;
  @(posedge clk) reset |=> 
    (!full && empty && (i_fifo.rd_ptr==0) && (i_fifo.wr_ptr==0) );
endproperty:p_rst_ptr
    
a_p_rst_ptr: assert property (p_rst_ptr)
  else $error("Reset pointers failed ", $time);

// Reset for Operation counter 
property p_rst_op_count;
  @(posedge clk) reset |=> (i_fifo.operation_count == 0);
endproperty: p_rst_op_count

a_p_rst_op_count: assert property (p_rst_op_count) 
  else $error("Reset operation counter failed ", $time);
  
// Operation counter change
property p_op_change;
  @(posedge clk) (write & read & !full & !empty) |=> 
  (i_fifo.operation_count == i_fifo.operation_count);
endproperty: p_op_change

a_p_op_change: assert property (p_op_change) 
  else 
  begin
    $error("Operation counter change failed ", $time);  
    $display ("write = %b, read = %b, full = %b, empty = %b",
             write, read, full, empty);
  end
  
// Empty set
property p_empty_set;
  @(posedge clk) read && (!write) && (i_fifo.operation_count == 1) |=> empty;
endproperty: p_empty_set

a_p_empty_set: assert property (p_empty_set) 
  else $error("Empty set failed ", $time);

// Empty reset
property p_empty_reset;
  @(posedge clk) empty && write |=> !empty;
endproperty: p_empty_reset

a_p_empty_reset: assert property (p_empty_reset) 
  else $error("Empty reset failed ", $time);

// Almost Empty set
property p_almost_empty_set;
  @(posedge clk) read && (!write) && (i_fifo.operation_count == ALMOST_EMPTY_DEPTH) 
    |=> almost_empty;
endproperty: p_almost_empty_set

a_p_almost_empty_set: assert property (p_almost_empty_set) 
  else $error("Almost Empty set failed ", $time);

// Almost Empty Reset
property p_almost_empty_reset;
  @(posedge clk) write && (!read) && (i_fifo.operation_count == ALMOST_EMPTY_DEPTH) 
    |=> !almost_empty;
endproperty: p_almost_empty_reset

a_p_almost_empty_reset: assert property (p_almost_empty_reset) 
  else $error("Almost Empty reset failed ", $time);

// Full set
property p_full_set;
  @(posedge clk) write && (!read) && (i_fifo.operation_count == FIFO_DEPTH - 1) |=> full;
endproperty: p_full_set

a_p_full_set: assert property (p_full_set) 
  else   begin
    $error("Full set failed ", $time);
    $display ("write = %b, read = %b, full = %b, i_fifo.operation_count = %h",
             write, read, full, i_fifo.operation_count);
  end
    
// Full reset
property p_full_reset;
  @(posedge clk) full && read |=> !full;
endproperty: p_full_reset

a_p_full_reset: assert property (p_full_reset) 
  else $error("Full reset failed ", $time);

// Almost Full set
property p_almost_full_set;
  @(posedge clk) 
    write && (!read) && (i_fifo.operation_count == FIFO_DEPTH - ALMOST_FULL_DEPTH - 1) 
      |=> almost_full;
endproperty: p_almost_full_set

a_p_almost_full_set: assert property (p_almost_full_set) 
  else $error("Almost Full set failed ", $time);

// Almost Full Reset
property p_almost_full_reset;
  @(posedge clk) 
    read && (!write) && (i_fifo.operation_count == FIFO_DEPTH - ALMOST_FULL_DEPTH) 
      |=> !almost_full;
endproperty: p_almost_full_reset

a_p_almost_full_reset: assert property (p_almost_full_reset) 
  else $error("Almost Full reset failed ", $time);

endmodule