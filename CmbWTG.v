`timescale 1ns / 1ps

`include "Core.vh"

// Brief: Where To Go, combinatorial
// Description: deal with jump/branch instruction
// Author: azure-crab
module CmbWTG(op, imm, data_x, data_y, 
              pc_4, pc_new, 
              jumped, is_branch, branched, jinted, 
              epc, ints);
    input [`WTG_OP_BIT - 1:0] op;
    input [`IM_ADDR_BIT - 1:0] imm;
    input signed [31:0] data_x;
    input signed [31:0] data_y;
    input [`IM_ADDR_BIT - 1:0] pc_4;
    input [2:0] ints;
    input [31:0] epc;
    output reg [`IM_ADDR_BIT - 1:0] pc_new;
    output reg jumped;          // True on successful jump
    output reg is_branch;       // True on branched
    output reg branched;        // True on successful conditional branch
    output reg jinted;          // True on successful int jump

    wire [`IM_ADDR_BIT - 1:0] j_addr = imm;
    wire [`IM_ADDR_BIT - 1:0] b_addr = imm + pc_4;

    always @(*) begin
        jumped = 0; 
        is_branch = 0;
        branched = 0;
        jinted = 0;
        pc_new = pc_4;
        case (op)
            `WTG_OP_J32: begin
                jumped = 1;
                pc_new = data_x[`IM_ADDR_BIT + 1:2];
            end
            `WTG_OP_J26: begin 
                jumped = 1;
                pc_new = j_addr;
            end
            `WTG_OP_BEQ: begin
                is_branch = 1;
                branched = (data_x == data_y);
                pc_new = b_addr;
            end
            `WTG_OP_BNE: begin
                is_branch = 1;
                branched = (data_x != data_y);
                pc_new = b_addr;
            end
            `WTG_OP_BLTZ: begin
                is_branch = 1;
                branched = (data_x < 0);
                pc_new = b_addr;
            end
            `WTG_OP_JINT: begin
                case (ints)
                    3'd1: begin jinted = 1; pc_new = `INT_VEC1; end
                    3'd2: begin jinted = 1; pc_new = `INT_VEC2; end
                    3'd3: begin jinted = 1; pc_new = `INT_VEC3; end
                    default: ;
                endcase
            end
            `WTG_OP_ERET: begin
                jinted = 1;
                pc_new = epc[`IM_ADDR_BIT + 1:2];
            end
            // not supported
            // `WTG_OP_BLEZ: begin
            //     is_branch = 1;
            //     branched = (data_x <= 0);                            
            //     pc_new = b_addr;
            // end
            // `WTG_OP_BGTZ: begin
            //     is_branch = 1;
            //     branched = (data_x > 0);
            //     pc_new = b_addr;
            // end
            // `WTG_OP_BGEZ: begin
            //     is_branch = 1;
            //     branched = (data_x >= 0);
            //     pc_new = b_addr;
            // end

            // WTG_OP_NOP
            default: ;
        endcase      
    end
endmodule
