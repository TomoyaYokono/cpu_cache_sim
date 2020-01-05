`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/03 22:21:46
// Design Name: 
// Module Name: memory
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


module memory(clk, addr, data, rw, strb, rdy);
    input  clk, addr, rw, strb;
    output rdy;
    inout  data;

    `define addr_size 8
    `define word_size 16

    logic [`word_size-1:0] data_r;
    logic                  rdy_r;

    initial begin
        data_r = 'bz;
        rdy_r = 1;
    end

    wire [`addr_size-1:0] addr;
    wire [`word_size-1:0] #(5) data = data_r;
    wire                 #(5) rdy = rdy_r;
    
    reg [`word_size-1:0] mem[0:(1 << `addr_size) - 1];

    integer i;
    always @(posedge clk) if (strb == 0) begin
        i = addr;
        if (rw == 1) begin
            repeat (4) @(posedge clk);
            data_r = mem[i];
            rdy_r = 0;
            @(posedge clk)
            data_r = 'bz;
            rdy_r = 1;
        end else begin
            repeat (2) @(posedge clk);
            mem[i] = data;
            rdy_r = 0;
            @(posedge clk)
            rdy_r = 1;
        end
    end
endmodule   

