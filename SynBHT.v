`timescale 1ns / 1ps

`include "Core.vh"

module CmbNewPredict(history, matched, succeed, out_his);
    input [1:0] history;
    input succeed, matched;
    output [1:0] out_his;
    reg [1:0] new_his;

    assign out_his = (matched) ? new_his : 'b10;

    always @(*) begin
        case(history)
            'b00    : new_his = (succeed) ? 'b01 : 'b00;
            'b11    : new_his = (succeed) ? 'b11 : 'b10;
            default : new_his = (succeed) ? new_his + 1 : new_his - 1;
        endcase
    end
endmodule

module SynBHT(clk, en, rst_n, 
              PC, PC_4, 
              is_branch, jumped, branched, succeed,
              pc_before_g, g_addr, 
              hit, guess_addr);
    input clk, en, rst_n;
    input [`IM_ADDR_BIT - 1:0] PC, PC_4, pc_before_g, g_addr;
    input is_branch, jumped, branched, succeed;
    wire w_en = is_branch || jumped;
    output reg hit;
    output [`IM_ADDR_BIT - 1:0] guess_addr;

    reg valid[`BHT_SIZE:0];
    reg [`BHT_ADDR_BIT - 1:0]   lru[0:`BHT_SIZE-1];
    reg [`IM_ADDR_BIT - 1:0]    tag[0:`BHT_SIZE-1];
    reg [1:0]                   history[0:`BHT_SIZE-1];
    reg [`IM_ADDR_BIT - 1:0]    next_addr[0:`BHT_SIZE-1];

    reg [`BHT_ADDR_BIT - 1:0]   lookup_index;
    reg [`BHT_ADDR_BIT - 1:0]   update_index;
    reg [`BHT_ADDR_BIT - 1:0]   replace_index;
    reg update;
    wire [`BHT_ADDR_BIT - 1:0]   write_index;

    assign guess_addr = (history[lookup_index] > 'b01) ? next_addr[lookup_index] : PC_4;
    integer i;
    
    initial
        for (i = 0; i < `BHT_SIZE; i = i + 1) begin
            lru[i] = `BHT_SIZE - 1;
        end

    // hit & lookup_index
    always @(*) begin
        hit = 0;
        lookup_index = 0;
        for (i = 0; i < `BHT_SIZE; i = i + 1) begin
            if (valid[i] && PC == tag[i]) begin 
                hit = 1;
                lookup_index = i;
            end
        end
    end

    // update, update index, replace index
    always @(*) begin
        update = 0;
        update_index = 0;
        replace_index = 0;
        for (i = 0; i < `BHT_SIZE; i = i + 1) begin
            if (valid[i] && pc_before_g == tag[i]) begin
                update_index = i;
                update = 1;
            end
            if (!valid[i] || lru[i] == 7)
                replace_index = i;
        end
    end
    assign write_index = (update) ? update_index : replace_index;

    reg [`BHT_ADDR_BIT - 1:0] new_lru[0:`BHT_SIZE-1];
    always @(*) begin
        for (i = 0; i < `BHT_SIZE; i = i + 1)
            new_lru[i] = (lru[i] < lru[write_index]) ? lru[i] + 1 : lru[i];
    end

    wire [1:0] new_his;
    CmbNewPredict vNP(
        .matched(update),
        .succeed(succeed),
        .history(history[write_index]),
        .out_his(new_his)
    );

    always @(negedge clk) begin
        if (en && w_en) begin
            for (i = 0; i < `BHT_SIZE; i = i + 1) begin
                lru[i] <= new_lru[i];
            end
            tag[write_index] = pc_before_g;
            history[write_index] = new_his;
            next_addr[write_index] = g_addr;
        end
    end

endmodule