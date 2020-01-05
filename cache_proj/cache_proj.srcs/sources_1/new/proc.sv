`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/03 21:52:46
// Design Name: 
// Module Name: proc
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


module proc(clk, addr, data, rw, strb, rdy);
    input  clk, rdy;
    output addr, rw, strb;
    inout  data;

    `define addr_size 8
    `define word_size 16

    logic [`addr_size-1:0] addr_r;
    logic [`word_size-1:0] data_r;
    logic                  rw_r, strb_r;

    wire [`addr_size-1:0] #(5) addr = addr_r;
    wire [`word_size-1:0] #(5) data = data_r;
    wire                  #(5) rw = rw_r, strb = strb_r;

    task read;
        input  [`addr_size-1:0] a;
        logic [`word_size-1:0] d;
        begin
            addr_r = a;
            rw_r = 1;
            strb_r = 0;
            @(posedge clk) strb_r = 1;
            while (rdy != 0) @(posedge clk) ;
            d = data;
            $display("%t: Reading data=%h from addr=%d", $time, d, a);
        end
    endtask
    
    task write;
        input  [`addr_size-1:0] a;
        input  [`word_size-1:0] d;
        begin
            $display("%t: Writing data=%h to addr=%d", $time, d, a);
            addr_r = a;
            rw_r = 0;
            strb_r = 0;
            data_r = d;
            @(posedge clk) strb_r = 1;
            while (rdy != 0) @(posedge clk) ;
            data_r = 'bz;
            @(posedge clk);
        end
    endtask

    class Bus;
        rand bit[`addr_size-1:0] addr;
        rand bit[`word_size-1:0] data;
        //constraint word_align {addr[1:0] == 2'b0;}
    endclass
    
   

    
    initial begin
        // Set initial state of outputs..
        Bus bus = new;
        addr_r = 0;
        data_r = 'bz;
        rw_r = 0;
        strb_r = 1;

        // Wait for first clock, then perform read/write test
        @(posedge clk)
        $display("%t: Starting Read/Write test", $time);

        repeat (5000) begin
            if ( bus.randomize() == 1 )
                //$display ("addr = %16h data = %h\n", bus.addr, bus.data);
                write( bus.addr, bus.data);
            else
                $display ("Randomization failed.\n");
        end
        
        repeat (1000) begin
            if ( bus.randomize() == 1 )
                //$display ("addr = %16h data = %h\n", bus.addr, bus.data);
                read (bus.addr);
            else
                $display ("Randomization failed.\n");
        end

/*                    
        write( 71, 16'h298A);
        write(  9, 16'h5672);
        write( 80, 16'hEFAC);
        write(135, 16'hAB00);
        write( 39, 16'h0FFF);
        write( 45, 16'h55AA);
        write(199, 16'hF197);
        write(125, 16'h0101);
        write(231, 16'h8954);

        read (  9);
        read ( 80);
        read (135);
        read ( 71);
        read (200);
        read (125);
        read (231);
        read ( 45);
        read ( 39);
*/
        $display("Read/Write test done");
        $stop(1);
    end

endmodule
