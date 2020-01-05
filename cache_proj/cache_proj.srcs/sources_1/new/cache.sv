`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/03 21:54:45
// Design Name: 
// Module Name: cache
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

`define addr_size   8
`define set_size    5
`define word_size   16

module cache(
    clk, paddr, pdata, prw, pstrb, prdy,
        maddr, mdata, mrw, mstrb, mrdy
    );
    
    input   clk, mrdy, paddr, prw, pstrb;
    output      prdy, maddr, mrw, mstrb;
    inout   mdata, pdata;

    int w_count, w_hit;
    int r_count, r_hit;
        
    logic   [`word_size-1:0]    mdata_r, pdata_r;
    logic   [`addr_size-1:0]    maddr_r;
    logic                       mrw_r, mstrb_r, prdy_r;
    
    wire    [`addr_size-1:0]        paddr;
    wire    [`addr_size-1:0] #(5)   maddr = maddr_r;   
    wire    [`word_size-1:0] #(5)   mdata = mdata_r, pdata = pdata_r;
    wire                     #(5)   mrw = mrw_r, mstrb = mstrb_r, prdy = prdy_r;
    
    logic   [3:0]   oen, wen;
    wire    [3:0]   hit;
    
    //---------- cashe sets ----------
    cache_set s0(paddr, pdata, hit[0], oen[0], wen[0]); 
    cache_set s1(paddr, pdata, hit[1], oen[1], wen[1]);
    cache_set s2(paddr, pdata, hit[2], oen[2], wen[2]);
    cache_set s3(paddr, pdata, hit[3], oen[3], wen[3]);
    
    initial begin
        maddr_r =   0;
        mdata_r =   'bz;
        pdata_r =   'bz;
        mrw_r   =   0;
        mstrb_r =   1;
        prdy_r  =   1;
        oen     =   4'b1111;
        wen     =   4'b1111;
        
        w_count =   0;
        w_hit   =   0;
        r_count =   0;
        r_hit   =   0;
    end                        

    //---------- Local LRU memory ----------
    
    logic [2:0] lru_mem [0:(1 << `set_size) - 1];

    integer i;
    initial for (i = 0; i < (1 << `set_size); i=i+1) lru_mem[i] = 0;

    function integer hash;
        input [`addr_size-1:0] a;
        hash = a[`set_size - 1:0];
    endfunction

    task update_lru;
        input [`addr_size-1:0] addr;
        input [3:0] hit;
        logic [2:0] lru;
        begin
            lru = lru_mem[hash(addr)];
            lru[2] = ((hit & 4'b1100) != 0);
            if (lru[2]) lru[1] = hit[3];
            else        lru[0] = hit[1];
            lru_mem[hash(addr)] = lru;
        end
    endtask

    function [3:0] pick_set;
        input [`addr_size-1:0] addr;
        integer setnum;
        begin
            casez (lru_mem[hash(addr)])
                3'b1?1 : setnum = 0;
                3'b1?0 : setnum = 1;
                3'b01? : setnum = 2;
                3'b00? : setnum = 3;
                default: setnum = 0;
            endcase
            if (prw == 1) begin
                $display("%t: Read miss, picking set %0d", $time, setnum);
                r_count++;
            end else begin
                $display("%t: Write miss, picking set %0d", $time, setnum);
                w_count++;
            end
            pick_set = 4'b0001 << setnum;
        end
    endfunction

    /**************** System Bus interface ****************/
    task sysread;
        input  [`addr_size-1:0] a;
        begin
            maddr_r = a;
            mrw_r = 1;
            mstrb_r = 0;
            @(posedge clk) mstrb_r = 1;
            assign prdy_r = mrdy;
            assign pdata_r = mdata;
            @(posedge clk) while (mrdy != 0) @(posedge clk) ;
            deassign prdy_r;  prdy_r = 1;
            deassign pdata_r; pdata_r = 'bz;
        end
    endtask

    task syswrite;
        input  [`addr_size-1:0] a;
        begin
            maddr_r = a;
            mrw_r = 0;
            mstrb_r = 0;
            @(posedge clk) mstrb_r = 1;
            assign prdy_r = mrdy;
            assign mdata_r = pdata;
            @(posedge clk) while (mrdy != 0) @(posedge clk) ;
            deassign prdy_r;  prdy_r = 1;
            deassign mdata_r; mdata_r = 'bz;
            mdata_r = 'bz;
        end
    endtask

    /**************** Cache control ****************/

    function [3:0] get_hit;
        input [3:0] hit;
        integer setnum;
        begin
            casez (hit)
                4'b???1 : setnum = 0;
                4'b??1? : setnum = 1;
                4'b?1?? : setnum = 2;
                4'b1??? : setnum = 3;
            endcase
            if (prw == 1) begin
                r_count++;
                r_hit++;
                $display("%t: Read hit to set %0d", $time, setnum);
                $display("Read hit rate %f (%d/%d)",$bitstoreal(r_hit)/$bitstoreal(r_count),r_hit,r_count);
            end else begin
                w_count++;
                w_hit++;            
                $display("%t: Write hit to set %0d", $time, setnum);
                $display("Write hit rate %f (%d/%d)",$bitstoreal(w_hit)/$bitstoreal(w_count),w_hit,w_count);
            end     
            get_hit = 4'b0001 << setnum;
        end
    endfunction

    logic [3:0] setsel;

    always @(posedge clk) if (pstrb == 0) begin
        if ((prw == 1) && hit) begin
            // Read Hit..
            setsel = get_hit(hit);
            oen = ~setsel;
            prdy_r = 0;
            @(posedge clk) prdy_r = 1;
            oen = 4'b1111;
        end else begin
            // Read Miss or Write Hit..
            if (hit)
                setsel = get_hit(hit);
            else
                setsel = pick_set(paddr);
            wen = ~setsel;
            if (prw == 1)
                sysread (paddr);
            else
                syswrite(paddr);
            wen = 4'b1111;
        end
        update_lru(paddr, setsel);
    end
endmodule


module cache_set(addr, data, hit, oen, wen);
  input addr, oen, wen;
  inout data;
  output hit;
  
  wire  [`addr_size-1:0] addr;
  logic [`word_size-1:0] data_r;
  logic hit_r;
  
  wire [`word_size-1:0] data = data_r;
  wire hit = hit_r;

  `define size (1 << `set_size)
  `define dly 5
  logic [`word_size-1:0] data_out;

  // ---------- Local tag and data memories -----------
  logic [`word_size-1:0] data_mem[0:(1 << `set_size)-1];
  logic [`addr_size-1:`set_size] atag_mem[0:(1 << `set_size)-1];
  logic [0:(1 << `set_size)-1] valid_mem;
  
  always @(data_out or oen)
    data_r <= #(5) oen ? `word_size'bz : data_out;

  function integer hash;
     input [`addr_size-1:0] a;
     hash = a[`set_size - 1:0];
  endfunction

  task lookup_cache;
    input [`addr_size-1:0] a;
    integer i;
    logic found;
  begin
    i = hash(a);
    found = valid_mem[i] && (a[`addr_size-1:`set_size] == atag_mem[i]);
    if (found) 
      hit_r <= #5 1'b1;
    else
      hit_r <= #5 1'b0;
  end
  endtask

  task update_cache;
    input [`addr_size-1:0] a;
    input [`word_size-1:0] d;
    integer i;
  begin
    i = hash(a);
    data_mem[i] = d;
    atag_mem[i] = a[`addr_size-1:`set_size];
    valid_mem[i] = 1'b1;
  end
  endtask
  
  integer i;
  initial begin
    for (i=0; i<`size; i=i+1)
      valid_mem[i] = 0;
  end

  always @(negedge(wen) or addr)
  begin
    lookup_cache(addr);
    data_out <= data_mem[hash(addr)];
  end
  
  always @(posedge(wen))
  begin
    update_cache(addr, data);
    lookup_cache(addr);
    data_out <= data_mem[hash(addr)];
  end
endmodule
