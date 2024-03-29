`timescale 1ns / 1ps
`include "Core.vh"

// Brief: Program Counter, sychronized
// Description: Update program counter
// Author: G-H-Y
// Modified by: AzureCrab
module SynPC(clk, rst_n, en, stall, load_pc, pc_new, pc, pc_4);
    input clk;
    input rst_n;    // negedge reset
    input en;       // high enable normal
    input stall;
    input load_pc;
    input [`IM_ADDR_BIT - 1:0] pc_new;
    output reg [`IM_ADDR_BIT - 1:0] pc;
    output [`IM_ADDR_BIT - 1:0] pc_4;

    assign pc_4 = pc + 1;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
   		    pc <= 0;
   	    else if (en)
            if (load_pc)
   		        pc <= pc_new[`IM_ADDR_BIT - 1:0];
            else if (!stall)
                pc <= pc_4[`IM_ADDR_BIT - 1:0];
    end
endmodule
