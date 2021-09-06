`timescale 1 ns / 1 ns
`default_nettype none 

module fsm_fifo
#(
  parameter  FIFO_PTR_WIDTH   = 9,
  parameter  BUF_CREDIT_COUNT = 3, 
  parameter  LATENCY          = 3
)

(
  input wire                       clk,
  input wire                       reset,
  input wire                       empty_buf,
  input wire                       full_buf,
  input wire                       empty_ram,
  input wire                       full_ram,
  input wire                       write,
  input wire                       read,
  input wire [FIFO_PTR_WIDTH-1:0]  credit_count,
  output reg                       fsm_write_buf,
  output reg                       fsm_read_buf,
  output reg                       fsm_write_ram,
  output reg                       fsm_read_ram,
  output reg                       storage_sel
);
  

  logic [$clog2(LATENCY) - 1 : 0]  count_latency = 0;

  //States
  localparam [2:0] 
    init     = 3'b000, 
    buffer   = 3'b001, 
    ram      = 3'b010,
    b_r      = 3'b100,
    all_full = 3'b111;
  logic [2:0] state, next_state;

  // State register
  always @ (posedge clk)
  begin
    if (reset)
      state <= #1 init;
    else 
      state <= #1 next_state;
  end

  // latency counter


  // Next state logic
  always @ *
  begin
    case (state)
    init:  // 0
      if (!write)
        next_state = init;
      else
        next_state = buffer;

    buffer:  // 1
      if ((credit_count == 1) & read & ~write)
        next_state = init;
      else if (full_buf)
        next_state = ram;
      else if ((credit_count + 1 == {BUF_CREDIT_COUNT{1'b1}}) & write)
            next_state = ram;
        else      
            next_state = buffer;

    ram:  // 2
      if (count_latency < LATENCY)
        next_state = ram;
      else
        casex ({empty_buf, full_buf, empty_ram, full_ram, read})
          5'bx01xx: next_state = buffer;
          5'bx11xx: next_state = ram; 
          5'bx1010: next_state = all_full;
          5'bx0010: next_state = b_r;
          5'bx1011: next_state = b_r;
          5'bxx011: next_state = b_r;
          5'bx100x: next_state = ram;
          5'b0000x: next_state = b_r;
          default: next_state = init;
        endcase  
  
    b_r:  // 4
	    casex ({empty_buf, full_buf, empty_ram, full_ram})
        4'bx1xx: next_state = ram; 
        4'bx01x: next_state = buffer;
        4'bx00x: next_state = b_r;
        default: next_state = init;
		  endcase
    
    all_full:  // 7
      casex ({empty_buf, full_buf, empty_ram, full_ram, read})
        5'bx0x1x: next_state = b_r; 
        5'bx1x10: next_state = all_full;
        5'bx1x11: next_state = b_r;
        default: next_state = init;
      endcase

    default:
      next_state = init;

    endcase
  end  
  
  // Output logic based on current state
  always @ (state)
  begin
    case (state)
    init: 
    begin
      fsm_write_buf = 1'b1;
      fsm_read_buf  = 1'b0;
      fsm_write_ram = 1'b0;
      fsm_read_ram  = 1'b0;
      storage_sel   = 1'b0;
    end

    buffer:
    begin
      fsm_write_buf = 1'b1;
      fsm_read_buf  = 1'b1;
      fsm_write_ram = 1'b0;
      fsm_read_ram  = 1'b0;
      storage_sel   = 1'b0;
    end

    ram:
    begin
      fsm_write_buf = 1'b0;
      fsm_read_buf  = 1'b1;
      fsm_write_ram = 1'b1;
      fsm_read_ram  = 1'b0;
      storage_sel   = 1'b1;
    end

    b_r: // 4
    begin
      fsm_write_buf = 1'b1;
      fsm_read_buf  = 1'b1;
      fsm_write_ram = 1'b1;
      fsm_read_ram  = 1'b1;
      storage_sel   = 1'b1;
    end

    all_full:
    begin
      fsm_write_buf = 1'b0;
      fsm_read_buf  = 1'b1;
      fsm_write_ram = 1'b0;
      fsm_read_ram  = 1'b0;
      storage_sel   = 1'b1;
    end

    default:
    begin
      fsm_write_buf = 1'b0;
      fsm_read_buf  = 1'b0;
      fsm_write_ram = 1'b0;
      fsm_read_ram  = 1'b0;
      storage_sel   = 1'b0;
    end
      
    endcase
  end 

  // latency counter
  always @ (posedge clk)
  begin
    if (reset)
      count_latency <= #1 {$clog2(LATENCY){1'b0}};
    else 
      if (state == ram)
        if (count_latency < LATENCY)
          count_latency <= # 1 count_latency + 1;
        else
          count_latency <= # 1 count_latency;
      else
        count_latency <= #1 {$clog2(LATENCY){1'b0}};
  end


endmodule