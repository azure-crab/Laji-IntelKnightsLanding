`timescale 1ns / 1ps
`include "Core.vh"

// Brief: Program Counter, sychronized
// Description: Update program counter
// Author: G-H-Y
// Modified by: AzureCrab
module SynPC(clk, rst_n, en, 
             stall, isbj, gone,
             keep_pc, pc_before_g,
             g_addr, s_addr, 
             bht_hit, pc, pc_4);
    input clk;
    input rst_n;    // negedge reset
    input en;       // high enable normal
    input stall;
    input isbj;
    input gone;
    input keep_pc;
    input [`IM_ADDR_BIT - 1:0] pc_before_g;
    input [`IM_ADDR_BIT - 1:0] g_addr, s_addr;
    output bht_hit;
    output reg [`IM_ADDR_BIT - 1:0] pc;
    output [`IM_ADDR_BIT - 1:0] pc_4;
    assign pc_4 = pc + 1;
    
    initial pc <= `START_UP;

    wire [`IM_ADDR_BIT - 1:0] pc_BHT;
    SynBHT vBHT(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .PC(pc),
        .PC_4(pc_4),
        .w_en(isbj),
        .succeed(keep_pc),
        .pc_before_g(pc_before_g),
        .g_addr(g_addr),
        .hit(bht_hit),
        .guess_addr(pc_BHT)
    );

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
   		    pc <= `START_UP;
   	    else if (en)
            if (!keep_pc)
   		        pc <= (gone) ? g_addr : s_addr;
            else if (!stall)
                pc <= pc_BHT[`IM_ADDR_BIT - 1:0];
    end
endmodule
