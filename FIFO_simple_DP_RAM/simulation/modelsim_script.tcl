
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog ../testbench.v ../../*.v 

# open the testbench module for simulation
vsim -novopt work.testbench

# add all testbench signals to time diagram
#add wave sim:/testbench/*

add wave -radix bin sim:/testbench/clk
add wave -radix bin sim:/testbench/reset
add wave -radix bin sim:/testbench/write
add wave -radix hex sim:/testbench/i_fifo/wr_ptr
add wave -radix hex sim:/testbench/write_data
add wave -radix bin sim:/testbench/read
add wave -radix hex sim:/testbench/i_fifo/rd_ptr
add wave -radix hex sim:/testbench/i_fifo/read_data_wire
add wave -radix hex sim:/testbench/i_fifo/fifo_array/data_in
add wave -radix hex sim:/testbench/i_fifo/fifo_array/write_addr
add wave -radix hex sim:/testbench/read_data
add wave -radix bin sim:/testbench/empty
add wave -radix bin sim:/testbench/full
add wave -radix bin sim:/testbench/almost_empty
add wave -radix bin sim:/testbench/almost_full
add wave -radix hex sim:/testbench/i_fifo/operation_count
# run the simulation
run -all

# expand the signals time diagram
wave zoom full
