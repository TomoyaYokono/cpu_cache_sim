`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/03 22:23:25
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb;
  logic clk;

  // Processor side signals
  wire prw, pstrb, prdy;
  wire [7:0] paddr;
  wire [15:0] pdata;

  // Memory side signals
  wire mrw, mstrb, mrdy;
  wire [7:0] maddr;
  wire [15:0] mdata;
    
  initial begin
    clk = 1'b0;
  end
  
  always #20 clk = ~clk;

  proc p (.clk(clk), .addr(paddr), .data(pdata), 
          .rw(prw), .strb(pstrb), .rdy(prdy));
  cache c (.clk(clk), .paddr(paddr), .pdata(pdata),
           .prw(prw), .pstrb(pstrb), .prdy(prdy),
           .maddr(maddr), .mdata(mdata),
           .mrw(mrw), .mstrb(mstrb), .mrdy(mrdy));
  memory m (.clk(clk), .addr(maddr), .data(mdata),
            .rw(mrw), .strb(mstrb), .rdy(mrdy));

endmodule

module top_pm;

  logic clk;

  wire rw, strb, rdy;
  wire [7:0] addr;
  wire [15:0] data;

  initial begin
    clk = 1'b0;
  end
  
  always #20 clk = ~clk;

  proc p (.*);
  memory m (.*);

endmodule
