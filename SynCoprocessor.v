`timescale 1ns / 1ps
`include "Core.vh"

module SynCoprocessor(
    clk, rst_n, en,
    int0, int1, int2,
    irs, irs_w_mask, irs_set_en, irs_clr_en,
    ie,  ie_w_data, ie_w_en,
    epc, epc_w_data, epc_w_en,
    int, ints
);
    input clk, rst_n, en;
    input int0, int1, int2;
    output [31:0] irs;
    input irs_set_en, irs_clr_en;   // irs clr will clr corresponding bit of ir too
    input [2:0] irs_w_mask;
    output [31:0] ie;
    input ie_w_en;
    input ie_w_data;
    output [31:0] epc;
    input epc_w_en;
    input [31:0] epc_w_data;
    output int;
    output reg [2:0] ints;

    reg [2:0] ir_;
    reg [2:0] irs_;
    reg ie_;
    reg [31:0] epc_;


    initial begin
        ir_ <= 0;
        irs_ <= 0;
        ie_ <= 1;
        epc_ <= 0;
    end

    assign irs = {28'b0, ir_};
    assign ie = {31'b0, ie_};
    assign epc = epc_;

    reg [2:0] inm;
    always @(*) begin
        inm = 3'b111;
        if (irs_[2]) inm = 3'b0;
        else if (irs_[1]) inm = 3'b100;
        else if (irs_[0]) inm = 3'b110;
    end
    assign int = ie_ && |(inm & ir_);
    always @(*) begin
        ints = 3'd0;
        if (ir_[2]) ints = 3'd3;
        else if (ir_[1]) ints = 3'd2;
        else if (ir_[0]) ints = 3'd1;
    end

    always @(negedge clk, negedge rst_n) begin
        if (!rst_n) begin
            ir_ <= 0;
            irs_ <= 0;
            ie_ <= 1;
            epc_ <= 0;
        end
        else if (en) begin
            if (irs_set_en) irs_ <= irs_ | irs_w_mask;
            else if (irs_clr_en) begin 
                irs_ <= irs_ & irs_w_mask;
                ir_ <= ir_ & irs_w_mask;
            end else begin
                ir_ <= ir_ | {int2, int1, int0};
            end

            if (ie_w_en)  ie_  <= ie_w_data;
            if (epc_w_en) epc_ <= epc_w_data;
        end
    end

endmodule